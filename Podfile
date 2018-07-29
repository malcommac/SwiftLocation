# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

abstract_target 'SwiftLocation' do
  # Shared podss
  pod 'SwiftyJSON', '~> 4.0'

  target 'SwiftLocation-iOS' do
    platform :ios, '9.0'
    # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!

    target 'SwiftLocation-iOS Tests' do
      inherit! :search_paths
      # Pods for testing
    end
  end

  target 'SwiftLocation-watchOS' do
    platform :watchos, '3.0'
    # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!
  end

  target 'TestApplication' do
    # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!

    # Pods for TestApplication

  end
end
