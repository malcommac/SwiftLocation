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
  s.version          = "0.1.0"
  s.summary          = "CoreLocation Made Easy, the Swift way"
  s.description      = <<-DESC
                       An optional longer description of SwiftLocation

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "https://github.com/<GITHUB_USERNAME>/SwiftLocation"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "daniele margutti" => "me@danielemargutti.com" }
  s.source           = { :git => "https://github.com/malcommac/SwiftLocation.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/danielemargutti'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'SwiftLocation' => ['Pod/Assets/*.png']
  }

  s.frameworks = 'UIKit', 'CoreLocation'
end
