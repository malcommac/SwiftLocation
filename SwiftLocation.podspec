Pod::Spec.new do |s|
  s.name         = "SwiftLocation"
  s.version      = "3.0.0-beta"
  s.summary      = "Easy and Efficient Location Tracking for iOS"
  s.description  = <<-DESC
    Efficient location tracking for iOS with support for oneshot/continuous/background tracking, reverse geocoding and more!
  DESC
  s.homepage     = "https://github.com/malcommac/SwiftLocation.git"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Daniele Margutti" => "me@danielemargutti.com" }
  s.social_media_url   = ""
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/malcommac/SwiftLocation.git.git", :tag => s.version.to_s }
  s.source_files  = "Sources/**/*"
  s.frameworks  = "Foundation","CoreLocation","MapKit"
  s.dependency 'SwiftyJSON', '~> 4.0.0-alpha.1'
end
