Pod::Spec.new do |s|
  s.name         = "SwiftLocation"
  s.version      = "5.1.0"
  s.summary      = "Location Manager Made Easy"
  s.description  = <<-DESC
  Efficient location tracking for iOS with support for oneshot/continuous/background tracking, reverse geocoding, autocomplete, geofencing, beacon monitoring & broadcasting
  DESC
  s.homepage     = "https://github.com/malcommac/SwiftLocation.git"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Daniele Margutti" => "hello@danielemargutti.com" }
  s.social_media_url   = "https://twitter.com/danielemargutti"
  s.ios.deployment_target = "11.0"
  s.macos.deployment_target = "11.0"
  s.source       = { :git => "https://github.com/malcommac/SwiftLocation.git", :tag => s.version.to_s }
  s.frameworks  = "Foundation","CoreLocation","MapKit"
  s.swift_versions = ['5.0', '5.1', '5.3']

  s.subspec 'Core' do |s|
    s.source_files = "Sources/SwiftLocation/**/*.swift"
    s.frameworks  = "Foundation","CoreLocation","MapKit"
  end

  s.subspec 'BeaconBroadcaster' do |s|
    s.dependency 'SwiftLocation/Core'
    s.source_files = "Sources/SwiftLocationBeaconBroadcaster/**/*.swift"
    s.frameworks  = "Foundation","CoreBluetooth"
  end
end
