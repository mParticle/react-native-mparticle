require 'json'

new_arch_enabled = ENV['RCT_NEW_ARCH_ENABLED'] == '1'
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

  if respond_to?(:install_modules_dependencies, true)
    install_modules_dependencies(s)
  else
    s.dependency "React-Core"
  end

  s.dependency 'mParticle-Apple-SDK-ObjC', '~> 9.0'
  s.dependency 'RoktContracts', '~> 0.1'
end
