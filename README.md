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
Latest version of SwiftLocation is: 3.0.0-beta for Swift 4.

### Documentation

### Requesting Permission

SwiftLocation automatically handles obtaining permission to access location services of the host machine when you issue a location request and user has not granted your app permissions yet.

#### iOS 9 and iOS 10
Starting with iOS 8, you must provide a description for how your app uses location services by setting a string for the key `NSLocationWhenInUseUsageDescription` or `NSLocationAlwaysUsageDescription` in your app's `Info.plist` file.

SwiftLocation determines which level of permissions to request based on which description key is present. You should only request the minimum permission level that your app requires, therefore it is recommended that you use the `"When In Use"` level unless you require more access.
If you provide values for both description keys, the more permissive `"Always"` level is requested.

#### Manual Request
Sometimes you want to get the authorization manually.
In this case you need to call `Locator.requestAuthorizationIfNeeded` by passing the auth level (`always` or `whenInUse`).

Example:

```swift
Locator.requestAuthorizationIfNeeded(.always)
```

#### iOS 11+
Starting with iOS 11, you must provide a description for how your app uses location services by setting a string for the key `NSLocationAlwaysAndWhenInUseUsageDescription` in your app's Info.plist file.

### Getting Current Location (one shot)

To get the device's current location, use the method `Locator.currentPosition`.
This function require two parameters:

* `accuracy`: The accuracy level desired (refers to the accuracy and recency of the location).
* `timeout`: The amount of time to wait for a location with the desired accuracy before completing

Accuracy levels are:

| `city`         | (lowest accuracy) 5000 meters or better, received within the last 10 minutes |
|----------------|------------------------------------------------------------------------------|
| `neighborhood` | 1000 meters or better, received within the last 5 minutes                    |
| `block`        | 100 meters or better, received within the last 1 minute                      |
| `house`        | 15 meters or better, received within the last 15 seconds                     |
| `room`         | (highest accuracy) 5 meters or better, received within the last 5 seconds    |

The timeout parameter specifies how long you are willing to wait for a location with the accuracy you requested. The timeout guarantees that your block will execute within this period of time, either with a location of at least the accuracy you requested (`succeded`), or with whatever location could be determined before the timeout interval was up (`timedout`).

Timeout can be specified as:

* `after(_: TimeInterval)`: timeout occours after specified interval regardeless the needs of authorizations from the user.
* `delayed(_: TimeInterval)`: delay the start of the timeout countdown until the user has responded to the system location services permissions prompt (if the user hasn't allowed or denied the app access yet).

This is an example of the call:

```swift
Locator.currentPosition(accuracy: .city).onSuccess { location in
	print("Location found: \(location)")
}.onFailure { err, last in
	print("Failed to get location: \(err)")
}
```

#### Observe Authorization Status Changes

You can also observe for changes in authorization status by subscribing auth changes events:

```swift
Locator.events.listen { newStatus in
	print("Authorization status changed to \(newStatus)")
}
```

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



