Pod::Spec.new do |s|
  s.name = 'SwiftLocation'
  s.version = '2.0.6'
  s.license = 'MIT'
  s.summary = 'Efficent and Easy Location Monitoring in Swift'
  s.homepage = 'https://github.com/malcommac/SwiftLocation'
  s.social_media_url = 'http://twitter.com/danielemargutti'
  s.authors = { 'Daniele Margutti' => 'hello@danielemargutti.com' }
  s.source = { :git => 'https://github.com/malcommac/SwiftLocation.git', :tag => s.version }
  s.ios.deployment_target = '9.0'
  s.frameworks            = "CoreLocation", "MapKit", "Foundation"
  s.source_files = 'Sources/**/*.swift'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.0' }
end