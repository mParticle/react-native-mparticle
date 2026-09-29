# Opt-in Swift Package Manager mode for the mParticle SDKs (see README › Swift Package Manager).
#
# Podfile usage (bare React Native):
#
#   $RNMParticleUseSPM = true                      # must be set before `target` / use_native_modules!
#   require_relative '../node_modules/react-native-mparticle/ios/mparticle_spm'
#   ...
#   post_install do |installer|
#     react_native_post_install(installer, ...)
#     mparticle_spm_post_install(installer, kits: [
#       { url: 'https://github.com/mparticle-integrations/mp-apple-integration-rokt', product: 'mParticle-Rokt', version: '9.6.1' },
#     ])
#   end
#
# What it does:
#   1. Refuses to install when a pod would add a second copy of the mParticle / Rokt SDKs (mixing pods
#      and Swift packages builds and archives silently, then crashes at runtime).
#   2. Adds the mParticle core (and any kits) as Swift packages to every iOS application target that
#      uses this pod, idempotently, pinned to an exact version. The app target owns the only copy of each
#      SDK.
require 'xcodeproj'

module MParticleSPM
  # Keep these URLs byte-identical to the ones the mParticle kits use, so SwiftPM unifies them into one
  # package identity (mparticle-apple-sdk). No `.git` suffix for the core.
  CORE_URL = 'https://github.com/mParticle/mparticle-apple-sdk'.freeze
  CORE_PRODUCT = 'mParticle-Apple-SDK'.freeze
  # Default core version when the Podfile does not pass one. Bump with each tested native release.
  DEFAULT_CORE_VERSION = '9.6.1'.freeze
  CONFLICTING_PODS = /\A(mParticle-.*|Rokt-Widget|RoktContracts|RoktUXHelper|DcuiSchema)\z/.freeze

  def self.guard!(installer)
    conflicts = installer.pod_targets.map(&:pod_name).uniq.grep(CONFLICTING_PODS)
    return if conflicts.empty?

    raise Pod::Informative,
          "[mParticle] $RNMParticleUseSPM is set, but these pods would add a second copy of the " \
          "mParticle/Rokt SDKs next to the Swift packages: #{conflicts.sort.join(', ')}. Remove them " \
          "(including any mParticle pre_install dynamic-framework hook entries) and add kits via " \
          "mparticle_spm_post_install(installer, kits: [...]) instead."
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
end

def mparticle_spm_post_install(installer, core_version: MParticleSPM::DEFAULT_CORE_VERSION, kits: [])
  MParticleSPM.guard!(installer)
  # mParticle kits are released in lockstep with the core, so a kit without a version gets the core's.
  packages = [{ url: MParticleSPM::CORE_URL, product: MParticleSPM::CORE_PRODUCT, version: core_version }] +
             kits.map { |kit| { version: core_version }.merge(kit) }
  touched = {}
  MParticleSPM.application_targets(installer).each do |project, target|
    packages.each do |pkg|
      added = MParticleSPM.add_package(project, target, **pkg.slice(:url, :product, :version))
      Pod::UI.puts "[mParticle] #{target.name} <- #{pkg[:product]} #{pkg[:version]}".green if added
    end
    touched[project.path.to_s] = project
  end
  touched.each_value(&:save)
end
