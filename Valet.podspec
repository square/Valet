Pod::Spec.new do |s|
  s.name     = 'Valet'
  s.version  = '0.9'
  s.license  = 'Apache'
  s.summary  = 'Valet is a wrapper for Keychain that makes it dead simple to utilize Keychain.'
  s.homepage = 'https://stash.corp.squareup.com/projects/IOS/repos/valet/browse'
  s.authors  = { 'Dan Federman' => 'federman@squareup.com', 'Eric Muller' => 'emuller@squareup.com' }
  s.source   = { :git => 'https://stash.corp.squareup.com/scm/ios/valet.git', :tag => s.version }
  s.source_files = 'Valet/*.{h,m}', 'Other/*.{h,m}'
  s.prefix_header_file = 'Other/Valet-Prefix.pch'
  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'
end
