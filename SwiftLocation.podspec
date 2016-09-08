Pod::Spec.new do |s|
  s.name = 'SwiftLocation'
  s.version = '1.0.5'
  s.license = 'MIT'
  s.summary = 'Elegant Location Services and Beacon Monitoring in Swift'
  s.homepage = 'https://github.com/malcommac/SwiftLocation'
  s.social_media_url = 'http://twitter.com/danielemargutti'
  s.authors = { 'Daniele Margutti' => 'hello@danielemargutti.com' }
  s.source = { :git => 'https://github.com/malcommac/SwiftLocation.git', :tag => s.version }

  s.ios.deployment_target = '8.0'

  s.source_files = 'src/*.swift'
end