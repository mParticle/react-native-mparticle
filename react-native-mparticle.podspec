require 'json'
require_relative 'ios/mparticle_spm'

ios_platform = '15.6'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = package['name']
  s.version      = package['version']
  s.summary      = package['description']

  s.author            = { "mParticle" => "support@mparticle.com" }

  s.homepage     = package['homepage']
  s.license      = package['license']
  s.platforms = { :ios => ios_platform, :tvos => "15.6" }

  s.source       = { :git => "https://github.com/mParticle/react-native-mparticle.git", :tag => "#{s.version}" }
  s.source_files  = "ios/**/*.{h,m,mm,swift}"
  # The Rokt-typed code is Swift (ios/RNMParticle/Swift); Objective-C++ reaches it through the
  # hand-written RNMPRoktSwift.h. Private headers keep C++ and React headers out of the module's
  # umbrella header, which the Swift code's module would otherwise fail to build.
  s.swift_version = '5.0'
  s.private_header_files = 'ios/**/*.h'
  xcconfig = { 'DEFINES_MODULE' => 'YES' }

  # Swift Package Manager mode is the default: ios/mparticle_spm.rb links the mParticle SDKs into the
  # app target on each `pod install`. `$RNMParticleDisableSPM = true` at the top of the Podfile takes
  # them from CocoaPods instead.
  use_spm = MParticleSPM.enabled?

  if use_spm
    # The app target links mParticle and RoktContracts as Swift packages. This pod only compiles
    # against their headers and never links them, so it is a static framework even under
    # `use_frameworks! :linkage => :dynamic`.
    s.static_framework = true
    s.platforms = { :ios => ios_platform } # the Rokt kit Swift package is iOS-only
    xcconfig['HEADER_SEARCH_PATHS'] = '"$(DERIVED_FILE_DIR)/mParticleSPMInclude" "$(OBJROOT)/GeneratedModuleMaps-$(PLATFORM_NAME)"'
    # Where Xcode puts the Swift packages' .swiftmodule files, for build and archive alike.
    xcconfig['SWIFT_INCLUDE_PATHS'] = '$(inherited) "$(PODS_CONFIGURATION_BUILD_DIR)"'
    # Xcode writes a module map holding the absolute checkout path of each package, for build and
    # archive alike, under OBJROOT. Linking that directory into this target's derived sources means no
    # DerivedData or -clonedSourcePackagesDirPath layout is assumed. Declaring RoktContracts-Swift.h
    # as an input orders this phase, and so this target's compile, after the RoktContracts package.
    maps = '${OBJROOT}/GeneratedModuleMaps-${PLATFORM_NAME}'
    s.script_phase = {
      :name => '[mParticle] Locate Swift Package headers',
      :execution_position => :before_compile,
      :input_files => ["#{maps}/mParticle_Apple_SDK_ObjC.modulemap", "#{maps}/RoktContracts-Swift.h"],
      :output_files => ['${DERIVED_FILE_DIR}/mParticleSPMInclude'],
      :script => <<~'SH'
        set -eu
        MAP="${OBJROOT}/GeneratedModuleMaps-${PLATFORM_NAME}/mParticle_Apple_SDK_ObjC.modulemap"
        INC=$(sed -n 's/^umbrella "\(.*\)"$/\1/p' "$MAP" 2>/dev/null || true)
        if [ -z "$INC" ] || [ ! -d "$INC" ]; then
          echo "error: [mParticle] Swift Package Manager mode is on, but the mParticle-Apple-SDK Swift package is not linked into the app target. Run pod install again, or set \$RNMParticleDisableSPM = true at the top of the Podfile to take the SDK from CocoaPods."
          exit 1
        fi
        mkdir -p "${DERIVED_FILE_DIR}"
        ln -sfn "$INC" "${DERIVED_FILE_DIR}/mParticleSPMInclude"
      SH
    }
  end

  s.pod_target_xcconfig = xcconfig

  if respond_to?(:install_modules_dependencies, true)
    install_modules_dependencies(s)
  else
    s.dependency "React-Core"
  end

  unless use_spm
    s.dependency 'mParticle-Apple-SDK-ObjC', '>= 9.2.2', '< 10.0'
    s.dependency 'RoktContracts', '~> 2.0'
  end
end
