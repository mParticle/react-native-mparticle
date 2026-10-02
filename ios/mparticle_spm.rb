# Swift Package Manager mode for the mParticle SDKs, the default (see README › Swift Package Manager).
#
# react-native-mparticle.podspec loads this file on every `pod install` and turns the mode on unless
# the Podfile opts out. React Native and this package still install with CocoaPods; the mParticle
# core SDK and its kits are Swift packages linked into the app target. Podfile settings, all
# optional, set before the first `target` block, which evaluates the podspec:
#
#   $RNMParticleSPMKits = ['mParticle-Rokt']   # kits by pod name, from ios/mparticle_spm_kits.json,
#                                              # or { url:, product:, version: } for any other kit
#   $RNMParticleSPMCoreVersion = '9.6.1'       # exact core SDK version; kits without one get it too
#   $RNMParticleDisableSPM = true              # take the SDKs from CocoaPods instead
#
# On each `pod install` in this mode:
#   1. Before CocoaPods validates the targets, it stops the install if a pod would add a second copy
#      of the mParticle / Rokt SDKs. Mixing pods and Swift packages builds and archives silently, then
#      crashes at runtime.
#   2. After the Podfile's post_install hook, it adds the core SDK and each kit as Swift packages,
#      pinned to an exact version, to every iOS application target that uses this pod. The app target
#      owns the only copy of each SDK.
# With the opt-out, it only warns when an app target still links the mParticle Swift packages.
require 'json'
require 'xcodeproj'

module MParticleSPM
  # Keep these URLs byte-identical to the ones the mParticle kits use, so SwiftPM unifies them into one
  # package identity (mparticle-apple-sdk). No `.git` suffix for the core.
  CORE_URL = 'https://github.com/mParticle/mparticle-apple-sdk'.freeze
  CORE_PRODUCT = 'mParticle-Apple-SDK'.freeze
  # Default core version when the Podfile sets none. Bump with each tested native release.
  DEFAULT_CORE_VERSION = '9.6.1'.freeze
  # Kits by their CocoaPods name. The Expo config plugin reads the same file.
  KITS = JSON.parse(File.read(File.join(__dir__, 'mparticle_spm_kits.json')))['kits'].freeze
  CONFLICTING_PODS =
    /\A(mParticle-.*|Rokt-Widget|RoktContracts|RoktUXHelper|DcuiSchema|RoktSDKPlus|RoktPaymentExtension)\z/.freeze

  def self.enabled?
    !(defined?($RNMParticleDisableSPM) && $RNMParticleDisableSPM)
  end

  def self.core_version
    (defined?($RNMParticleSPMCoreVersion) && $RNMParticleSPMCoreVersion) || DEFAULT_CORE_VERSION
  end

  # $RNMParticleSPMKits as { url:, product:, version: } hashes. mParticle kits are released in
  # lockstep with the core, so a kit without a version gets the core's.
  def self.kits
    entries = Array(defined?($RNMParticleSPMKits) ? $RNMParticleSPMKits : nil)
    names = entries.grep(String)
    names.each do |name|
      included = Array(KITS.dig(name, 'includes')) & names
      next if included.empty?

      raise Pod::Informative,
            "[mParticle] $RNMParticleSPMKits lists #{name} and #{included.join(', ')}, but #{name} " \
            "already includes #{included.join(', ')}. List only #{name}."
    end
    entries.map { |entry| resolve_kit(entry) }
  end

  def self.resolve_kit(entry)
    if entry.is_a?(String)
      kit = KITS[entry]
      unless kit
        raise Pod::Informative,
              "[mParticle] $RNMParticleSPMKits: unknown kit #{entry.inspect}. Use a pod name from " \
              'react-native-mparticle/ios/mparticle_spm_kits.json, or { url:, product:, version: } ' \
              'for any other kit.'
      end
      return { url: kit['url'], product: kit['product'], version: core_version }
    end

    kit = entry.is_a?(Hash) ? entry.transform_keys(&:to_sym) : {}
    unless kit[:url] && kit[:product]
      raise Pod::Informative,
            "[mParticle] $RNMParticleSPMKits: #{entry.inspect} must be a kit pod name, or a hash " \
            'with url: and product: (and optionally version:).'
    end
    { version: core_version }.merge(kit.slice(:url, :product, :version))
  end

  # Runs before CocoaPods resolves the platforms, which would otherwise fail on a tvOS target with a
  # generic "not compatible" error.
  def self.check_podfile!(podfile)
    return unless podfile

    tvos = podfile.target_definition_list.select do |definition|
      definition.platform&.name == :tvos &&
        definition.dependencies.any? { |dependency| dependency.root_name == 'react-native-mparticle' }
    end
    return if tvos.empty?

    raise Pod::Informative,
          "[mParticle] Swift Package Manager mode is iOS only, but #{tvos.map(&:name).join(', ')} " \
          'targets tvOS. Set $RNMParticleDisableSPM = true at the top of the Podfile to take the ' \
          'mParticle SDKs from CocoaPods for the whole Podfile.'
  end

  def self.guard!(installer)
    conflicts = installer.pod_targets.map(&:pod_name).uniq.grep(CONFLICTING_PODS)
    return if conflicts.empty?

    raise Pod::Informative,
          '[mParticle] This package takes the mParticle SDKs from Swift Package Manager, but these ' \
          "pods would add a second copy: #{conflicts.sort.join(', ')}. Either remove them (and their " \
          'entries in any pre_install dynamic-framework hook) and list the kits in ' \
          '$RNMParticleSPMKits, or set $RNMParticleDisableSPM = true at the top of the Podfile to stay ' \
          'on CocoaPods.'
  end

  # Only iOS apps that use this pod: other apps in the same Podfile must not get the SDKs.
  def self.application_targets(installer)
    aggregates = installer.aggregate_targets.select do |aggregate|
      aggregate.platform.name == :ios && aggregate.pod_targets.any? { |pod| pod.pod_name == 'react-native-mparticle' }
    end
    aggregates.flat_map do |aggregate|
      aggregate.user_targets
               .select { |t| t.product_type == 'com.apple.product-type.application' }
               .map { |t| [aggregate.user_project, t] }
    end.uniq { |project, target| [project.path.to_s, target.uuid] }
  end

  def self.add_package(project, target, url:, product:, version:)
    ref = project.root_object.package_references.find do |r|
      r.is_a?(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference) && r.repositoryURL == url
    end
    unless ref
      ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
      ref.repositoryURL = url
      project.root_object.package_references << ref
    end
    requirement = { 'kind' => 'exactVersion', 'version' => version }
    changed = ref.requirement != requirement
    ref.requirement = requirement

    return changed if target.package_product_dependencies.any? { |d| d.product_name == product }

    dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    dep.package = ref
    dep.product_name = product
    target.package_product_dependencies << dep
    build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
    build_file.product_ref = dep
    target.frameworks_build_phase.files << build_file
    true
  end

  def self.link_packages(installer)
    packages = [{ url: CORE_URL, product: CORE_PRODUCT, version: core_version }] + kits
    touched = {}
    application_targets(installer).each do |project, target|
      packages.each do |pkg|
        added = add_package(project, target, **pkg.slice(:url, :product, :version))
        Pod::UI.puts "[mParticle] #{target.name} <- #{pkg[:product]} #{pkg[:version]}".green if added
      end
      touched[project.path.to_s] = project
    end
    touched.each_value(&:save)
  end

  # With the opt-out, the CocoaPods SDK and any leftover Swift package would both be linked. Kits
  # outside the table are caught by their `mParticle-` product name.
  def self.warn_leftover_packages(installer)
    products = [CORE_PRODUCT] + KITS.values.map { |kit| kit['product'] }
    application_targets(installer).each do |_, target|
      leftover = target.package_product_dependencies.map(&:product_name).select do |product|
        products.include?(product) || product.start_with?('mParticle-')
      end
      next if leftover.empty?

      Pod::UI.warn "[mParticle] $RNMParticleDisableSPM is set, but #{target.name} still links the " \
                   "Swift packages #{leftover.join(', ')}. Remove them from the target, or the app " \
                   'contains two copies of the SDK.'
    end
  end

  # Prepended to Pod::Installer when the Podfile evaluates the podspec (React Native's
  # use_native_modules! does), before the install starts, so no Podfile hook is needed.
  module InstallerHooks
    private

    def resolve_dependencies
      MParticleSPM.check_podfile!(podfile) if MParticleSPM.enabled?
      super
    end

    def validate_targets
      if MParticleSPM.enabled?
        MParticleSPM.guard!(self)
        MParticleSPM.kits
      end
      super
    end

    def run_podfile_post_install_hooks
      super
      if MParticleSPM.enabled?
        MParticleSPM.link_packages(self)
      else
        MParticleSPM.warn_leftover_packages(self)
      end
    end
  end
end

if defined?(Pod::Installer) && !Pod::Installer.ancestors.include?(MParticleSPM::InstallerHooks)
  Pod::Installer.prepend(MParticleSPM::InstallerHooks)
end
