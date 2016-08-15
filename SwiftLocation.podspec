#
# Be sure to run `pod lib lint SwiftLocation.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "SwiftLocation"
  s.version          = "1.0.0"
  s.summary          = "Location & Beacon Monitor Tool for Swift 2+"
  s.description      = <<-DESC
                       SwiftLocation is a simple 100% Swift 2.0+ wrapper around CoreLocation. Use Location services has never been easier and you can do it with your favourite language.
Let me show the best features of the library:

- **Auto-managed Hardware services** (heading/location/monitor services are turned off when not used)
- **Reverse geocoding services** (from address/coordinates to location placemark) using both **Apple** own CoreLocation services or external **Google Location APIs**
- Fast and low-powered **IP based device's location** discovery
- **Single shot location discovery** method (with desidered accuracy level) to get current user location with a simple closure as respond
- **Continous location update** methods to get both detailed locations or only significant data only.
- **Region monitor** with a single line of code
- **iBeacon proximity monitor** with a single line of code
- **Fixed user position** simulation
                       DESC
  s.homepage         = "https://github.com/malcommac/SwiftLocation"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "daniele margutti" => "me@danielemargutti.com" }
  s.source           = { :git => "https://github.com/malcommac/SwiftLocation.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/danielemargutti'

  s.platform     = :ios, '8.0'
  s.platform     = :osx, '10.9'
  s.platform     = :tvos, '9.0'
  s.requires_arc = true
  s.source_files = 'src/**'

  s.frameworks = 'UIKit', 'CoreLocation', 'CoreBluetooth'
end
