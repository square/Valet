Pod::Spec.new do |s|
  s.name     = 'Valet'
  s.version  = '5.0.0'
  s.license  = 'Apache License, Version 2.0'
  s.summary  = 'Securely store data on iOS, tvOS, watchOS, or macOS without knowing a thing about how the Keychain works. It\'s easy. We promise.'
  s.homepage = 'https://github.com/square/Valet'
  s.authors  = 'Square'
  s.source   = { :git => 'https://github.com/square/Valet.git', :tag => s.version }
  s.swift_version = '6.0'
  s.source_files = 'Sources/Valet/**/*.{swift,h}'
  s.public_header_files = 'Sources/Valet/*.h'
  s.frameworks = 'Security'
  s.ios.deployment_target = '12.0'
  s.tvos.deployment_target = '12.0'
  s.watchos.deployment_target = '4.0'
  s.macos.deployment_target = '10.13'

  s.tvos.exclude_files = 'Sources/Valet/SinglePromptSecureEnclaveValet.swift'
  s.watchos.exclude_files = 'Sources/Valet/SinglePromptSecureEnclaveValet.swift'
end
