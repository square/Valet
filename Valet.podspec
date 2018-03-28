Pod::Spec.new do |s|
  s.name     = 'Valet'
  s.version  = '3.1.0'
  s.license  = 'Apache License, Version 2.0'
  s.summary  = 'Valet lets you securely store data in the iOS or OS X Keychain without knowing a thing about how the Keychain works. It\'s easy. We promise.'
  s.homepage = 'https://github.com/square/Valet'
  s.authors  = 'Square'
  s.source   = { :git => 'https://github.com/square/Valet.git', :tag => s.version }
  s.source_files = 'Sources/**/*.{swift,h}'
  s.public_header_files = 'Sources/*.h'
  s.frameworks = 'Security'
  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '9.0'
  s.macos.deployment_target = '10.11'

  s.test_spec 'Tests' do |test_spec|
    test_spec.ios.requires_app_host = true
    test_spec.ios.source_files = 'Tests/**/*.{h,m,swift}'
    test_spec.ios.exclude_files = 'Tests/MacTests.swift'
    test_spec.tvos.requires_app_host = true
    test_spec.tvos.source_files = 'Tests/**/*.{h,m,swift}'
    test_spec.tvos.exclude_files = ['Tests/MacTests.swift', 'Tests/*BackwardsCompatibilityTests.swift']
    test_spec.macos.source_files = 'Tests/**/*.{h,m,swift}'
    test_spec.pod_target_xcconfig = {
      'SWIFT_OBJC_BRIDGING_HEADER' => '${PODS_TARGET_SRCROOT}/Tests/ValetTests-Bridging-Header.h',
      'CLANG_WARN_UNGUARDED_AVAILABILITY' => 'YES'
    }
  end
end
