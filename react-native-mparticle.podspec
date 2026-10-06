require 'json'

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

  # Opt-in Swift Package Manager mode: set `$RNMParticleUseSPM = true` at the top of the Podfile and
  # call `mparticle_spm_post_install` (ios/mparticle_spm.rb) in post_install. When it is unset, this
  # podspec resolves exactly as before.
  use_spm = defined?($RNMParticleUseSPM) && $RNMParticleUseSPM

  if use_spm
    # The app target links mParticle and RoktContracts as Swift packages. This pod only compiles
    # against their headers and never links them, so it is a static framework even under
    # `use_frameworks! :linkage => :dynamic`.
    s.static_framework = true
    s.platforms = { :ios => ios_platform } # the Rokt kit Swift package is iOS-only
    s.pod_target_xcconfig = {
      'HEADER_SEARCH_PATHS' => '"$(DERIVED_FILE_DIR)/mParticleSPMInclude" "$(OBJROOT)/GeneratedModuleMaps-$(PLATFORM_NAME)"'
    }
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
          echo "error: [mParticle] \$RNMParticleUseSPM is set but the mParticle-Apple-SDK Swift package is not linked into the app target. Call mparticle_spm_post_install in your Podfile post_install."
          exit 1
        fi
        mkdir -p "${DERIVED_FILE_DIR}"
        ln -sfn "$INC" "${DERIVED_FILE_DIR}/mParticleSPMInclude"
      SH
    }
  end

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
