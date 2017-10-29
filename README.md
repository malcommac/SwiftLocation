<p align="center" >
<img src="https://raw.githubusercontent.com/malcommac/SwiftLocation/3.0.0/logo.png" width=530px height=116px alt="SwiftLocation" title="SwiftLocation">
</p>

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![CI Status](https://travis-ci.org/malcommac/Swiftlocation.svg)](https://travis-ci.org/malcommac/Swiftlocation) [![Version](https://img.shields.io/cocoapods/v/Swiftlocation.svg?style=flat)](http://cocoadocs.org/docsets/Swiftlocation) [![License](https://img.shields.io/cocoapods/l/Swiftlocation.svg?style=flat)](http://cocoadocs.org/docsets/Swiftlocation) [![Platform](https://img.shields.io/cocoapods/p/Swiftlocation.svg?style=flat)](http://cocoadocs.org/docsets/Swiftlocation)

<p align="center" >Easy & Efficient Location Tracking for iOS<br/>
Made with ♥ for Swift 4
<p/>
<p align="center" >★★ <b>Star our github repository to help us!</b> ★★</p>
<p align="center" >Created by <a href="http://www.danielemargutti.com">Daniele Margutti</a> (<a href="http://www.twitter.com/danielemargutti">@danielemargutti</a>)</p>

### What's SwiftLocation

SwiftLocation is a lightweight library to work with location tracking in iOS.
Stop struggling with CoreLocation services settings and delegate, try now a new simple and effective way to play with location.

It provides a block based asynchronous API to request current location, either once (oneshot) or continously (subscription). It internally manages multiple simultaneous location and heading requests and efficently manage battery usage of the host device based upon running requests.

### Main Features

| Feature                                       | Description                                                                                                                                                                            |
|-----------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Efficient Power Manager**                   | SwiftLocation automatically manage power consumption based upon currently running requests. It 1turns off hardware when not used, automatically.                                       |
| **Location Monitoring**                       | Easily monitor for your with desired accuracy and frequency (continous monitoring, background monitoring, monitor by distance intervals, interesting places or significant locations). |
| **Device Heading**                            | Subscribe and receive continous device's heading updates                                                                                                                               |
| **Reverse Geocoder**                          | Get location from address string or coordinates using three different services: Apple (built-in), Google (require API Key) and OpenStreetMap.                                          |
| **Autocomplete Places**                       | Implement your places autocomplete search with just one call, including place's details (it uses Google API)                                                                           |
| **IP Address Location**                       | Fetch current location without user authorization using device's IP address (4 services supported: freegeoip.net, api.petabyet.com, smart-ip.net, ip-api.com)                                              |
| **Background Location Monitoring**            | Easily monitor location with significant location in background.                                                                                                                       |
| **Background Monitor with Region Monitoring** | No yet supported                                                                                                                                                                       |


### Current Version
Latest version of SwiftLocation is: 3.0.0-beta

### Requirements
Current supported version of SwiftLocation require:

* **Minimum OS**: iOS 9, macOS 10.10 or watchOS 3.0
* **Swift**: Swift 4 (see swift-3 branch for an old unsupported version)

### Installation

#### CocoaPods

### Using [CocoaPods](http://cocoapods.org)

1.	Add the pod `SwiftLocation` to your [Podfile](http://guides.cocoapods.org/using/the-podfile.html).

```ruby
pod 'SwiftLocation'
```
Run `pod install` from Terminal, then open your app's `.xcworkspace` file to launch Xcode.

### Using [Carthage](https://github.com/Carthage/Carthage)

1. Add the `malcommac/SwiftLocation` project to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile).

```ogdl
github "malcommac/SwiftLocation"
```

1. Run `carthage update`, then follow the [additional steps required](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application) to add the iOS and/or Mac frameworks into your project.
1. Import the SwiftLocation framework/module via `import INTULocationManager`

### Documentation



