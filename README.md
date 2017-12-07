<p align="center" >
<img src="https://raw.githubusercontent.com/malcommac/SwiftLocation/master/logo.png" width=530px alt="SwiftLocation" title="SwiftLocation">
</p>

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![CI Status](https://travis-ci.org/malcommac/SwiftLocation.svg)](https://travis-ci.org/malcommac/SwiftLocation) [![Version](https://img.shields.io/cocoapods/v/SwiftLocation.svg?style=flat)](http://cocoadocs.org/docsets/SwiftLocation) [![License](https://img.shields.io/cocoapods/l/SwiftLocation.svg?style=flat)](http://cocoadocs.org/docsets/SwiftLocation) [![Platform](https://img.shields.io/cocoapods/p/SwiftLocation.svg?style=flat)](http://cocoadocs.org/docsets/SwiftLocation)

<p align="center" >Easy & Efficient Location Tracking for iOS<br/>
🛰<br/>
Made with ♥ for Swift
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


### Other Libraries you may like

I'm also working on several other projects you may like.
Take a look below:

<p align="center" >

| Library         | Description                                      |
|-----------------|--------------------------------------------------|
| [**SwiftDate**](https://github.com/malcommac/SwiftDate)       | The best way to manage date/timezones in Swift   |
| [**Hydra**](https://github.com/malcommac/Hydra)           | Write better async code: async/await & promises  |
| [**Flow**](https://github.com/malcommac/Flow) | A new declarative approach to table managment. Forget datasource & delegates. |
| [**SwiftRichString**](https://github.com/malcommac/SwiftRichString) | Elegant & Painless NSAttributedString in Swift   |
| [**SwiftLocation**](https://github.com/malcommac/SwiftLocation)   | Efficient location manager                       |
| [**SwiftMsgPack**](https://github.com/malcommac/SwiftMsgPack)    | Fast/efficient msgPack encoder/decoder           |
</p>


### Current Version
Latest version of SwiftLocation is: 3.1.0 for Swift 4.

### Documentation

Table of Contents:

* [Requesting Authorizations](#authorizations)
* [Observe Authorization Status Changes](#observe_authorizations)
* [Getting Current Location (one shot)](#current_location)
* [Getting Current Location Without User Authorization (IP based)](#current_location_ip)
* [Subscribing to continuous location updates](#continuous)
* [Subscribing to Significant Location Changes](#significant)
* [Background Monitoring (using Significant Locations)](#background)
* [Managing Requests or Subscriptions Lifecycle](#manage)
* [Subscribing to Continuous Heading Updates](#heading)
* [Reverse Geocoding (from address to location / from coordinates to place)](#reverse)
* [Autocomplete Places (require Google API Key)](#autocomplete)

Other:

* [Issues & Contributions](#issues)
* [Requirements](#requirements)
* [Installation via CocoaPods/Chartage](#installation)

<a name="authorizations"/>

### Requesting Authorizations

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

<a name="observe_authorizations"/>

#### Observe Authorization Status Changes

You can also observe for changes in authorization status by subscribing auth changes events:

```swift
Locator.events.listen { newStatus in
	print("Authorization status changed to \(newStatus)")
}
```


<a name="current_location"/>

### Getting Current Location (one shot)

To get the device's current location, use the method `Locator.currentPosition`.
This function require two parameters:

* `accuracy`: The accuracy level desired (refers to the accuracy and recency of the location).
* `timeout`: The amount of time to wait for a location with the desired accuracy before completing

Accuracy levels are:

| Accuracy         | Description |
|----------------|------------------------------------------------------------------------------|
| `city`         | (lowest accuracy) 5000 meters or better, received within the last 10 minutes |
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

<a name="current_location_ip"/>

### Getting Current Location Without User Authorization (IP based)

If you don't want to require user authorization and you don't need of an accurate location you can use `Locator.currentPosition(usingIP:onSuccess:onFail)` function.
It uses host's device IP address to retrive the nearest location of the device (remember it may be inaccurate).
Location is retrived in one shot mode.

Currently four different services are supported:

* `freeGeoIP`: Free GeoIP service [http://freegeoip.net](http://freegeoip.net)
* `petabyet`: Petabyet service [http://api.petabyet.com/](http://api.petabyet.com/)
* `smartIP`: SmartIP service [http://smart-ip.net](http://smart-ip.net)
* `ipApi`: IPApi service [http://ip-api.com](http://ip-api.com)

Example:

```swift
Locator.currentPosition(usingIP: .smartIP, onSuccess: { loc in
	print("Find location \(loc)")
}) { err, _ in
	print("\(err)")
}
```

<a name="continuous"/>

### Subscribing to continuous location updates

To subscribe to continuous location updates, use the method `Locator.subscribePosition`.
The block will execute indefinitely (even across errors, until canceled), once for every new updated location regardless of its accuracy.

Example:

```swift
Locator.subscribePosition(accuracy: .city).onSuccess { loc in
	print("New location received: \(loc)")
}.onFailure { err, last in
	print("Failed with error: \(err)")
}
```

<a name="significant"/>

### Subscribing to Significant Location Changes

To subscribe to significant location changes, use the method `Locator.subscribeSignificantLocations`.
This instructs location services to begin monitoring for significant location changes, which is very power efficient.
The block will execute indefinitely (until canceled), once for every new updated location regardless of its accuracy.

Note:
If there are other simultaneously active location requests or subscriptions, the block will execute for every location update (not just for significant location changes).

```swift
Locator.subscribeSignificantLocations(onUpdate: { newLocation in
	print("New location \(newLocation)")
}) { (err, lastLocation) -> (Void) in
	print("Failed with err: \(err)")
}
```

<a name="background"/>

### Background Monitoring (using Significant Locations)

If your app has acquired the `always` location services authorization and your app is terminated with at least one active significant location change subscription (see above), your app may be launched in the background when the system detects a significant location change.

**Please note**:  when the app terminates, all of your active location requests and subscriptions with SwiftLocation are canceled automatically.
Therefore, when the app launches due to a significant location change, you should immediately use SwiftLocation to set up a new subscription for significant location changes in order to receive the location information.

A good point to do it is the application's `AppDelegate`:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
	/// If you start monitoring significant location changes and your app is subsequently terminated,
	/// the system automatically relaunches the app into the background if a new event arrives.
	// Upon relaunch, you must still subscribe to significant location changes to continue receiving location events.
	if let _ = launchOptions?[UIApplicationLaunchOptionsKey.location] {
		Locator.subscribeSignificantLocations(onUpdate: { newLocation in
			// This block will be executed with the details of the significant location change that triggered the background app launch,
			// and will continue to execute for any future significant location change events as well (unless canceled).
		}, onFail: { (err, lastLocation) in
			// Something bad has occurred
		})
	}
	// the rest of the init...
	return true
}
```

<a name="manage"/>

### Managing Requests or Subscriptions Lifecycle

Each request you have created via `Locator` function return a `Request` object. You can keep it to manage the lifecycle of the request.

Using `Locator` functions:

* `stopRequest()` to stop a request (both one shot or recurring). It won't execute the block. It's valid both for heading and location requests.
* `completeLocationRequest()` force the request to complete early, like a manual timeout. It will execute the block (valid only for location requests).
* `completeAllLocationRequests()` Immediately completes all active location requests and execute associated blocks.

<a name="heading"/>

### Subscribing to Continuous Heading Updates

To subscribe to continuous heading updates, use the method `Locator.subscribeHeadingUpdates` function.
It requires the following parameters:

* `accuracy`: minimum accuracy (expressed in degrees) you want to receive. `nil` to receive all events.
* `minInterval`: minimum interval between each request. `nil` to receive all events regardless the interval.

The block will execute indefinitely (until canceled), once for every new updated heading regardless of its accuracy.
Note that if heading requests are removed or canceled, the manager will automatically stop updating the device heading in order to preserve battery life.

If an error occurs, the block will execute with a status other than `succeded` (error callback), and the subscription will only be automatically canceled if the device doesn't have heading support (i.e. for error `unavailable`).

Example:

```swift
Locator.subscribeHeadingUpdates(accuracy: 2, onUpdate: { newHeading in
	print("New heading \(newHeading)")
}) { err in
	print("Failed with error: \(err)")
}
```
<a name="reverse"/>

### Reverse Geocoding (from address to location / from coordinates to place)

SwiftLocation supports reverse geocoding for:

* **From Address String to Location**: convert a readable address string to a valid `CLLocation` object with the associated coordinates
* **From Coordinates to Place**: convert a coordinate expressed place to one or more `Place` object (with `CLPlacemarks` associated when using Apple service)

Currently the following services are supported for reverse geocoding:

* **Apple Built-In Service**: Using built-in iOS services  (`CLGeocoder` and `CLPlacemark`)
* **Google API**: Using Google Maps Services. It requires API Key you can [obtain for free here](https://developers.google.com/maps/documentation/javascript/get-api-key)
* **OpenStreetMap**: Using OpenStreetMap ([nominatim](https://nominatim.openstreetmap.org))

**Note** If you are using Google API service be sure to set the API by calling `Locator.api.googleAPIKey = "<API KEY VALUE>"` before doing any request.

#### From Address String to Location
This function get a readable address and convert it in an array of `Place` objects.
`Place` is and object created to group common properties (`city,country,road,postalcode` and so on) between all supported services.
If you need of raw data of an object you can get the `rawDictionary` property.
If you are using Apple services you can get `placemark` to retrive the associated `CLPlacemark` instance.

Example

```swift
Locator.location(fromAddress: "1 Infinite Loop", using: .openStreetMap).onSuccess { places in
	print(places)
}.onFailure { err in
	print("err")
}
```

#### From Location to Places
This function get the location via `CLLocationCoordinate2D` and return a list of found `Place` objects.

Example:

```swift
Locator.api.googleAPIKey = ...
let coordinates = CLLocationCoordinate2DMake(41.890395, 12.493083)
Locator.location(fromCoordinates: coordinates, using: .google, onSuccess: { places in
	print(places)
}) { err in
	print(err)
}
```
<a name="autocomplete"/>

### Autocomplete Places (require Google API Key)

SwiftLocation allows to use the Google's Places APIs to get a list of candidate places for a given input string.
It returns a list of `PlaceMatch` object with the main informations about the candidate place.
You can retrive details about a place by calling `place.details(onSuccess: { placeInfo in .... })`.

Example:

```swift
Locator.autocompletePlaces(with: "123 main street", onSuccess: { candidates in
	print("Found \(candidates.count) candidates for this search")
	// get the detail of the first candidate - return a Place object.
	candidates.first?.detail(onSuccess: { placeDetail in
		print("Found detail about this place!")
	})
}) { err in
	print(err)
}
```

<a name="issues"/>

### Issues & Contributions

Please [open an issue here on GitHub](https://github.com/malcommac/SwiftLocation/issues/new) if you have a problem, suggestion, or other comment.
Pull requests are welcome and encouraged.

<a name="requirements"/>

### Requirements
Current supported version of SwiftLocation require:

* **Minimum OS**: iOS 9, macOS 10.10 or watchOS 3.0
* **Swift**: Swift 4

<a name="installation"/>

### Installation

#### CocoaPods

### Using [CocoaPods](http://cocoapods.org)

1.	Add the pod `SwiftLocation` to your [Podfile](http://guides.cocoapods.org/using/the-podfile.html).

```ruby
pod 'SwiftLocation', '~> 3.1.0'
```
Run `pod install` from Terminal, then open your app's `.xcworkspace` file to launch Xcode.

### Using [Carthage](https://github.com/Carthage/Carthage)

1. Add the `malcommac/SwiftLocation` project to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile).

```ogdl
github "malcommac/SwiftLocation"
```

1. Run `carthage update`, then follow the [additional steps required](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application) to add the iOS and/or Mac frameworks into your project.
1. Import the SwiftLocation framework/module via `import SwiftLocation`



