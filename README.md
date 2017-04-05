<p align="center" >
  <img src="https://raw.githubusercontent.com/malcommac/SwiftLocation/master/logo.png" width=200px height=207px alt="SwiftLocation" title="SwiftLocation">
</p>


[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/SwiftLocation.svg)](https://img.shields.io/cocoapods/v/SwiftLocation.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/SwiftLocation.svg?style=flat)](http://cocoadocs.org/docsets/SwiftLocation)
[![Twitter](https://img.shields.io/badge/twitter-@danielemargutti-blue.svg?style=flat)](http://twitter.com/danielemargutti)
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/swift3-compatible-orange.svg?style=flat" alt="Swift 3 compatible" /></a>

<p align="center" >★★ <b>Star our github repository to help us!</b> ★★</p>
<p align="center" >Created by <a href="http://www.danielemargutti.com">Daniele Margutti</a> (<a href="http://www.twitter.com/danielemargutti">@danielemargutti</a>)</p>

SwiftLocation is the right choice to work easily and efficiently with Location Manager.
Main features includes:
- **Efficient Hardware Management**: it turns off hardware when not used. Don't worry, we take care of your user's battery usage!
- **Location monitoring**: easily monitor for your with desired accuracy and frequency (continous monitoring, background monitoring, monitor by distance intervals, interesting places or significant locations).
- **Device Heading**: get current device's heading easily
- **Reverse geocoding**: (from address string/coordinates to placemark) using both Apple and Google services (with support for API key)
- **GPS-less location**: fetching using network IP address with 4 different providers (`freeGeoIP`, `petabyet`, `smartIP` or `telize`)
- **Geographic region monitoring**: monitor background location enter/exit

## You also may like

Do you like `SwiftLocation`? I'm also working on several other opensource libraries.

Take a look here:

* **[SwiftDate](https://github.com/malcommac/SwiftDate)** - Date & Timezone management in Swift
* **[Hydra](https://github.com/malcommac/Hydra)** - Promises & Async/Await - Write better async code in Swift
* **[SwiftRichString](https://github.com/malcommac/SwiftRichString)** - Elegant and painless attributed string in Swift
* **[SwiftScanner](https://github.com/malcommac/SwiftScanner)** - String scanner in pure Swift with full unicode support
* **[SwiftSimplify](https://github.com/malcommac/SwiftSimplify)** - Tiny high-performance Swift Polyline Simplification Library
* **[SwiftMsgPack](https://github.com/malcommac/SwiftMsgPack)** - MsgPack Encoder/Decoder in Swit

## Releases History
- [1.1.1](https://github.com/malcommac/SwiftLocation/releases/tag/1.1.1) is the last version with Beacon Monitoring active (actually we have a plan to add it as subspec but right now is temporary disabled).
- [1.0.5](https://github.com/malcommac/SwiftLocation/releases/tag/1.0.5) Is the last version compatible with Swift 2.3 (not supported anymore)
- [0.1.4](https://github.com/malcommac/SwiftLocation/releases/tag/0.1.4) Is the last version compatible with Swift 2.0 (not supported anymore)

<a name="index" />

## Index
* **[Differences with 1.x](#migration)**
* **[Introduction](#introduction)**
* **[APIs Index](#api)**
	* [Location Monitoring](#location)
	* [Reverse Geocoding](#reverse)
	* [Heading Monitoring](#heading)
	* [Region Monitoring](#region)
	* [Visits Monitoring](#visits)
* **[Prerequisites](#prerequisites)**
* **[Get Current Location](#getcurrentlocation)**
	* [Manage `LocationRequest`](#locationrequest)
	* [Examples](#examples_location)
* **[Reverse geocoding from address string](#reverse_string)**
	* [Examples](#examples_reverse)
* **[Reverse geocoding from a `CLLocation`](#reverse_location)**
	* [Examples](#example_reverse_location)
* **[Get continous device's heading (`CLHeading`)](#get_heading)**
	* [Examples](#examples_heading)
* **[Monitor geographic region](#monitor_region)**
	* [Examples](#examples_monitor)**
* **[Monitor Visits (`CLVisits`)](#monitor_visits)**
	* [Examples](#examples_visits)
* **[Background Updates](#background)**
* **[More on `LocationTracker`](#locationtracker)**

Other:

* **[Installation](#installation)**
* **[Requirements](#requirements)**
* **[Credits](#credits)**

<a name="migration" />

## Differences with 1.x

SwiftLocation 2.x is a complete rewrite of the library. However, while some calls may appears different it's pretty much the same. If you are in dubt fell free to ask support via issue tracking. I'll try to reply fast as I can.

<a name="introduction" />

## Introduction

The main concept behind SwiftLocation is a central Location Manager class called `LocationTracker`. It automatically manages hardware resources by turning on/off and change filters level according to currently running requests: you just don't need to worry about battery usage, SwiftLocation takes care of it.

([Index ↑](#index))

<a name="api" />

## APIs Index

When you need to perform a location operation you can call one of the available `LocationTracker` functions:

<a name="location" />

#### Location Monitoring (`LocationRequest`)
- `getLocation(accuracy:frequency:timeout:success:failure:)` to get the current device location
- `getLocation(forAddress:inRegion:timeout:success:failure)` to perform a reverse geocoding from an address string
- `getLocation(forABDictionary:timeout:success:failure:)` to get the location from a given Address Book record

<a name="reverse" />

#### Reverse Geocoding (`GeocoderRequest`)
- `getPlacemark(forLocation:timeout:success:failure:)` to get placemarks from a specified location

<a name="heading" />

#### Heading Monitoring (`HeadingRequest`)
- `getContinousHeading(filter:success:failure)` to get continous device's heading

<a name="region" />

#### Region Monitoring (`RegionRequest`)
- `monitor(regionAt:radius:enter:exit:error:)` to get notified when user enter/exit from a region defined by given coordinates and radius
- `monitor(region:enter:exit:error:)` to get notified when user enter/exit from a given region

<a name="visits" />

#### Visit Monitoring (`VisitsRequest`)
- `monitorVisit(event:error)` to get notified when user visit an 'important' region (ie. home, or work)

Each of this method create a `Request` instance which will be added to the `LocationTracker`'s pool and started automatically.
You can manage each `Request` at any time to abort (`cancel()`), pause (`pause()`) or start/resume (`resume()`) it.
Each request implements at least two callbacks called when a new data is received or an error has occurred.

<a name="prerequisites" />

### Important Prerequisites
Before using SwiftLocation you must configure your project to use location services.
First of all you need to specify a value for `NSLocationAlwaysUsageDescription` or `NSLocationWhenInUseUsageDescription` (or both) into your application's `Info.plist` file.
The string value you add will be shown along with the authorization request the first time your app will try to use location services hardware.

If you need background monitoring you should specify `NSLocationAlwaysUsageDescription` and specify the correct value in `UIBackgroundModes` key (you can learn more here).

([Index ↑](#index))

<a name="getcurrentlocation" />

### Get Current Location
The most common request is to get the current user location.
`getLocation(accuracy:frequency:timeout:success:error:)` defines the following parameters:
- `accuracy`:  the minimum accuracy of location you want to accept. It defines an enum with the following options: 
  - `IPScan`: uses geolocation via IP; It's not particularly accurate but it's the only option Which does not require user authorization and not involve the GPS module.
  You can specify one of the following IP services: `freeGeoIP`, `petabyet`, `smartIP` or `telize`.
  - `any`: the lowest accuracy (< 1000km is accepted)
  - `country`: lower accuracy (< 100km is accepted)
  - `city`: city level accuracy (< 3km is accepted)
  - `neighborhood`: neighborhood accuracy (less than a kilometer is accepted)
  - `block`: block accuracy (hundred meters)
  - `house`: house accuracy (nearest ten meters are accepted)
  - `room`: best accuracy
  - `navigation`: best accuracy for a navigation based purpose
- `frequency`: specify the frequency of updates you want to receive from the location manager. It defines an enum with the following options:
  - `continous`: continous location updating; you will receive new location updates (or errors) until you manually remove (`cancel()`) or pause (`pause()`) the request itself.
  - `oneShot`: the first valid result for given settings is reported, then the request itself is aborted automatically.
  - `significant`: only significant location changes are reported. It's used to preserve battery energy and also work on `background`.
  - `deferredUntil`: defer location updating until passed `distance` (in meters) or time `timeout` (in seconds) is reached. **iOS 10 users**: Seems there is a bug in iOS 10 with deferred location updating which return kLocationError 0 when you start a new monitoring (see [this](http://stackoverflow.com/questions/39498899/deferredlocationupdatesavailable-returns-no-in-ios-10), [this](https://github.com/zakishaheen/deferred-location-implementation) and [this](https://github.com/lionheart/openradar-mirror/issues/15939); a radar is opened but actually we have not any news)
- `timeout`: define a maximum time interval (in seconds). If no updates are delivered to the request until that time the request itself generate a `LocationError.timeout` error in error callback. By passing `nil` timeout timer is disabled.
- `success`: define a callback which is called when a new location is received. Received parameter is a `CLLocation` object.
- `failure`: define a callback which is called when a new error (of type `Error`) is received. By default the request still running after an error; if you want to kill it automatically on error set the `cancelOnError` property to `true`.

([Index ↑](#index))

<a name="locationrequest" />

#### Manage `LocationRequest`
There are a number of interesting properties you may want to set for a `LocationRequest` request, especially:

- `.activity` (`CLActivityType`): It indicate the type of activity associated with location updates and helps the system to set best value for energy efficency. By default its set to `.other` but can be `automotiveNavigation` (for navigation sw), `fitness` (includes any pedestrian activities) or `.otherNavigation` (for other navigation cases (excluding pedestrian navigation), e.g. navigation for boats, trains, or planes).
- `.minimumDistance` (`CLLocationDistance`): The minimum distance (measured in meters) a device must move horizontally before an update event is generated. This value is ignored when request is has `significant` frequency set. Set it to `nil` to report all movements (default is `nil`).

Other read-only properties are:

- `lastLocation` (`CLLocation`): last valid measured location for valid for the request (maybe `nil`)
- `lastError` (`Error`): last received error (maybe `nil`)

You may also register request in order to receive changes in global location manager authorization.
Just use:

```swift
let request = Location.getLocation...
// callback is called on main thread by reporting previous and current authorization status
request.register(observer: LocObserver.onAuthDidChange(.main, { (request, oldAuth, newAuth) in
	print("Authorization moved from \(oldAuth) to \(newAuth)")
}))
```

<a name="examples_location" />

#### Examples

##### 1. Getting current location via IP Scan.

```swift
// Accuracy is set to IP Scan (using freeGEOIP service), no user auth is required but given location maybe inaccurate
// Frequency is one shot, so after a valid location is obtained (or error has occurred) the request itself will be
// automatically removed from main queue.
Location.getLocation(accuracy: .IPScan(IPService(.freeGeoIP)), frequency: .oneShot, success: { _,location in
  print("Found location \(location)")
}) { (_, last, error) in
	print("Something bad has occurred \(error)")
}
```

Note:
To be able to find user's location this way, you need to update your info.plist and add required security settings for it. (iOS 9+):

```
<dict>
	<key>NSAllowsArbitraryLoads</key>
        <false/>
        <key>NSExceptionDomains</key>
        <dict>
            <key>ip-api.com</key>
      <dict>
        <key>NSIncludesSubdomains</key>
        <true/>
        <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
        <true/>
        <key>NSTemporaryExceptionMinimumTLSVersion</key>
        <string>TLSv1.1</string>
      </dict>
        </dict>
    </dict>
```

##### 2. Getting continous location (`CLLocation`)

```swift
// Here we want to get an higher accuracy and continous location update.
// Once added to the pool, if needed, the app will ask to the user permission to obtain the location; if granted,
// the request (along with the all the others in pending state) will be started.
//
// In case of error we want to cancel our request and report the error.
// Each request's callback includes a reference to the request itself so you can manage easily the workflow.
Location.getLocation(accuracy: .city, frequency: .continuous, success: { (_, location) in
		print("A new update of location is available: \(location)")
}) { (request, last, error) in
		request.cancel() // stop continous location monitoring on error
		print("Location monitoring failed due to an error \(error)")
}
```

([Index ↑](#index))

<a name="reverse_string" />

### Reverse geocoding from address string
This function allows you to get a `CLPlacemark` object from a given address string.
It's a one shot request so, once finished, it will be removed automatically from the queue.
`getLocation(forAddress:inRegion:timeout:success:failure:)` defines the following parameters:
- `address`: this is the input string with the address you want to reverse geocode
- `region`: you may optionally pass a valid `CLRegion` to help the reverse geocoder engine to produce best results
- `timeout`: when specified the timeout interval defines the max number of seconds can elapse before aborting the request using `LocationError.timeout`.
- `success`: define a callback which will be executed if reverse geocoding succeded and a valid `CLPlacemark` instance is available
- `failure`: define a callback which will be executed if reverse geocoding fails with an `Error`.

Very similar to the func described there is:
`getLocation(forABDictionary:timeout:success:failure:)`
which allows you to reverse a dictionary coming from the system Address Book.

<a name="example_reverse" />

##### Example

```swift
Location.getLocation(forAddress: "1 Infinite Loop, Cupertino", success: { placemark in
	print("Placemark found: \(placemark)")
}) { error in
	print("Cannot reverse geocoding due to an error \(error)")
}
```

([Index ↑](#index))

<a name="reverse_location" />

### Reverse geocoding from a `CLLocation`
Another reverse geocoding func allows you to get one or more `CLPlacemark` instances by passing a `CLLocation` as input.
`getPlacemark(forLocation:timeout:success:failure:)` defines the following parameters:
- `location`: a valid `CLLocation` instance you want to analyze
- `timeout`: if not `nil` defines a max amount of seconds to execute the geocoding operation; if reached a `LocationError.timeout` is thrown.
- `success`: define a callback which will be executed if reverse geocoding succeded and a valid `CLPlacemark` instance is available.
- `failure`: define a callback which will be executed if reverse geocoding fails with an `Error`. 

<a name="example_reverse_location" />

##### Example

```swift
let loc = CLLocation(latitude: 42.972474, longitude: 13.757332)
Location.getPlacemark(forLocation: loc, success: { placemarks in
	// Found Contrada San Rustico, Contrada San Rustico, 63065 Ripatransone, Ascoli Piceno, Italia
	// @ <+42.97264130,+13.75787860> +/- 100.00m, region CLCircularRegion
	print("Found \(placemarks.first!)")
}) { error in
	print("Cannot retrive placemark due to an error \(error)")
}
```
<a name="get_heading" />

### Get continous device's heading (`CLHeading`)
This func allows you to get update about device's heading.
`getContinousHeading(filter:success:failure)` defines the following parameters:
- `filter`: define the minimum angular change (measured in degrees) required to generate new heading events
- `success`: define a callback where new heading updates are delivered (input params include a reference to `HeadingRequest` request and the new `CLHeading` object)
- `failure`: define a callback where errors from request are delivered (input params include a refere to `HeadingRequest` and occurred `Error`)

<a name="examples_heading" />

#### Examples

```swift
do {
	try Location.getContinousHeading(filter: 0.2, success: { heading in
		print("New heading value \(heading)")
	}) { error in
		print("Failed to update heading \(error)")
	}
} catch {
	print("Cannot start heading updates: \(error)")
}
```

([Index ↑](#index))

<a name="monitor_region" />

### Monitor geographic region
Region monitoring allows you to stay informed when device enter/exit from a specified region.
Region monitoring also works in background; however in order to support it when the app is killed you should re-add it to the queue on `AppDelegate`'s launch func.
Region may be defined by a `CLRegion` instance or directly by passing `CLLocationCoordinate2D` and a given radius.

First option is:
`monitor(regionAt:radius:enter:exit:error:)` define the following parameters:
- `center`: center coordinate of the region you want to monitor (`CLLocationCoordinate2D`)
- `radius`: radius of the region from `center` point (expressed in meters)
- `enter`: callback called once the device did entered into the region
- `exit`: callback called once the device did exited from the region
- `error`: callback called once an error has occurred

Second options is:
`monitor(region:enter:exit:error:` define the following parameters:
- `region`: a `CLCircularRegion` which defines the region you want to monitor
- `enter`: callback called once the device did entered into the region
- `exit`: callback called once the device did exited from the region
- `error`: callback called once an error has occurred

<a name="examples_monitor" />

#### Example

```swift
do {
	let loc = CLLocationCoordinate2DMake( 42.972474, 13.757332)
	let radius = 100.0
	try Location.monitor(regionAt: loc, radius: radius, enter: { _ in
		print("Entered in region!")
	}, exit: { _ in
		print("Exited from the region")
	}, error: { req, error in
		print("An error has occurred \(error)")
		req.cancel() // abort the request (you can also use `cancelOnError=true` to perform it automatically
	})
} catch {
	print("Cannot start heading updates: \(error)")
}
```

([Index ↑](#index))

<a name="monitor_visits" />

### Monitor Visits (`CLVisits`)
A `CLVisit` object encapsulates information about interesting places that the user has been. Visit objects are created by the system and delivered. The visit includes the location where the visit occurred and information about the arrival and departure times as relevant. You do not create visit objects directly, nor should you subclass `CLVisit`.
In order to monitor visits you can use this function:
`monitorVisit(event:error)` which defines the following parameters:
- `event`: callback called when a new visit has occurred
- `error`: callback called on `Error`.

<a name="examples_visits" />

#### Example

```swift
do {
  try Location.monitorVisit(event: { visit in
	  print("A new visit to \(visit)")
	}, error: { error in
		print("Error occurred \(error)")
	})
} catch {
	print("Cannot start visit updates: \(error)")
}
```

([Index ↑](#index))

<a name="background" />

### Background Updates

Background monitoring is a sensitive topic; efficent use of device's battery is one of hit point for Apple.

#### Significant Locations
At this time the only way to get continous update even if the app is in background is to use `significant` location monitoring.
Basically you need to:
- Add the `NSLocationAlwaysUsageDescription` description in your app's `Info.plist`
- Turn on `Background Fetch` and `Location Updates` checkbox in `Project Settings > Capabilities > Background Modes`
- Register a `significant` location request in your `AppDelegate`'s `application(application:didFinishLaunchingWithOptions:)`

You will receive only significant updates from location manager. What it does mean?
The significant location change is the least accurate of all the location monitoring types. It only gets its updates when there is a cell tower transition or change. This can mean a varying level of accuracy and updates based on where the user is. City area, more updates with more towers. Out of town, interstate, fewer towers and changes.

### Using Background Task

You can also register a background task to get the most accurated result for a limited period of time.
In your background task you can define a region monitoring request; as soon as the device crosses the region you will create another region from the current coordinates while entering and exiting from regions, did update location delegate gets called and you get the updated coordinate while application is in terminated mode.

([Index ↑](#index))

<a name="locationtracker" />

### More on `LocationTracker`
At any time you can also monitor the `LocationTracker` status.
There are a number of properties you can set:

- `.onAddNewRequest`: allows you to set a callback which is called when a new `Request` is added to the queue
- `.onRemoveRequest`: allows you to set a callback which is called when a queued `Request` is removed from the queue

```swift
Location.onAddNewRequest = { req in
  print("A new request is added to the queue \(req)")
}
Location.onRemoveRequest = { req in
	print("An existing request was removed from the queue \(req)")
}
```

- `.displayHeadingCalibration`: Asks whether the heading calibration alert should be displayed. This method is called in an effort to calibrate the onboard hardware used to determine heading values. By default is `true`.
- `.headingOrientation`: The device orientation to use when computing heading values.
- `.autoPauseUpdates`: This function also scan for any running Request's `activityType` and see if location data is unlikely to change. If `true` (for example when user stops for food while using a navigation app) the location manager might pause updates for a period of time. (by default is `false`).

- `lastLocation` last location get the last valid `CLLocation` obtained from the location manager.
- `locationSettings` return the current settings for Location Tracker instance by returning a `TrackerSettings` struct with the following global `CLLocationManager` properties: `accuracy`, `frequency`, `activity`, `distanceFilter`. Values are evaluated continously based upon running requests.

([Index ↑](#index))

<a name="installation" />

## Installation
You can install Swiftline using CocoaPods, carthage and Swift package manager

### CocoaPods
    use_frameworks!
    pod 'SwiftLocation'

### Carthage
    github 'malcommac/SwiftLocation'

### Swift Package Manager
Add swiftline as dependency in your `Package.swift`

```
  import PackageDescription

  let package = Package(name: "YourPackage",
    dependencies: [
      .Package(url: "https://github.com/malcommac/SwiftLocation.git", majorVersion: 0),
    ]
  )
```

([Index ↑](#index))


<a name="requirements" />

## Requirements

Current version is compatible with:

* Swift 3.0+
* iOS 9.0 or later

([Index ↑](#index))

<a name="credits" />

## Credits & License
SwiftLocation is owned and maintained by [Daniele Margutti](http://www.danielemargutti.com/).

As open source creation any help is welcome!

The code of this library is licensed under MIT License; you can use it in commercial products without any limitation.

The only requirement is to add a line in your Credits/About section with the text below:

```
This software uses open source SwiftLocation's library to manage location updates.
Web: http://github.com/malcommac/SwiftLocation
Created by Daniele Margutti and licensed under MIT License.
```
([Index ↑](#index))
