Pod::Spec.new do |s|
  s.name     = 'Valet'
  s.version  = '2.0.4'
  s.license  = 'Apache License, Version 2.0'
  s.summary  = 'Valet lets you securely store data in the iOS or OS X Keychain without knowing a thing about how the Keychain works. It\'s easy. We promise.'
  s.homepage = 'https://github.com/square/Valet'
  s.authors  = 'Square'
  s.source   = { :git => 'https://github.com/square/Valet.git', :tag => s.version }
  s.source_files = 'Valet/*.{h,m}', 'Other/*.{h,m}'
  s.frameworks = 'Security'
  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.10'
  s.watchos.deployment_target = '2.0'
end
