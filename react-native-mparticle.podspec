require 'json'

new_arch_enabled = ENV['RCT_NEW_ARCH_ENABLED'] == '1'
ios_platform = new_arch_enabled ? '11.0' : '9.0'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = package['name']
  s.version      = package['version']
  s.summary      = package['description']

  s.author            = { "mParticle" => "support@mparticle.com" }

  s.homepage     = package['homepage']
  s.license      = package['license']
  s.platforms = { :ios => ios_platform, :tvos => "9.2" }

  s.source       = { :git => "https://github.com/mParticle/react-native-mparticle.git", :tag => "#{s.version}" }
  s.source_files  = "ios/**/*.{h,m,mm,swift}"

  if respond_to?(:install_modules_dependencies, true)
    install_modules_dependencies(s)
  else
    s.dependency "React-Core"
  end

  # Primary: CocoaPods dependency (still works when SPM is not used)
  s.dependency 'mParticle-Apple-SDK', '~> 8.0'

  # SPM bridge: registers mParticle-Apple-SDK as an SPM dependency alongside CocoaPods (RN 0.75+).
  # See: https://github.com/facebook/react-native/pull/44627
  if respond_to?(:spm_dependency, true)
    spm_dependency(s,
      url: 'https://github.com/mParticle/mparticle-apple-sdk.git',
      requirement: { kind: 'upToNextMajorVersion', minimumVersion: '8.0.0' },
      products: ['mParticle-Apple-SDK']
    )
  end
end
