<p align="left" >
<img src="./swiftlocation_logo.png" width=300px alt="SwiftLocation" title="SwiftLocation">
</p>

### Efficient and easy to use location tracking, geocoding, autocomplete & beacon framework for iOS

|  	| Main Features 	|
|----	|----------------------------------------------------------------------------	|
| 🛰 	| GPS location with single line of code and fully customizable filters 	|
| 🙅‍♀️   	| No delegates, requests based architecture. We use the new Swift 5's Result type 	|
| 🔋 	| Auto manage tracking resources based upon running requests.	|
| 🔒 	| Automatic/manual user's permissions management	|
| 🌏 	| Support for Geocoding/Reverse Geocoding (Apple, Google, OpenStreet) 	|
| 🔍 	| Support for Autocomplete/Place Details (Apple, Google) 	|
| 🖥 	| Support IP based location with multiple pluggable services 	|
| 📍 	| Support iBeacon tracking	|
| ⏱ 	| Support continous location monitoring with fixed minumum time interval / min distance	|


SwiftLocation is **created and maintaned with ❥** by Daniele Margutti - [www.danielemargutti.com](http://www.danielemargutti.com).

A complete list of my **open source contributions** is on my [Github Profile](https://github.com/malcommac).

---

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![CI Status](https://travis-ci.org/malcommac/SwiftLocation.svg)](https://travis-ci.org/malcommac/SwiftLocation) [![Version](https://img.shields.io/cocoapods/v/SwiftLocation.svg?style=flat)](http://cocoadocs.org/docsets/SwiftLocation) [![License](https://img.shields.io/cocoapods/l/SwiftLocation.svg?style=flat)](http://cocoadocs.org/docsets/SwiftLocation) [![Platform](https://img.shields.io/cocoapods/p/SwiftLocation.svg?style=flat)](http://cocoadocs.org/docsets/SwiftLocation)


## Requirements

The latest version of SwiftLocation require:

- Swift 5+
- iOS 10+
- Xcode 10+

## Installation

The preferred installation method is with CocoaPods. Add the following to your Podfile:

```pod 'SwiftLocation', '~> 4.0'```

## Roadmap & Contributions

Would you contribute to the project? There are some interesting area of the project where your help will be very appreciated!

- [ ] Region Monitoring
- [ ] MapBox Support for geocoding/reverse and autocomplete
- [ ] Beacon Monitoring
- [ ] freeGeoIP and smartIP support for IP to location discovery

Any other idea for improvements? Fell free to open a PR!

Please [open an issue](https://github.com/malcommac/SwiftLocation/issues/new) here on GitHub if you have a problem, suggestion, or other comment. Pull requests are welcome and encouraged.


## Getting Started

The main goal of SwiftLocation is to provide an easy way to work with location related functionalities (gps tracking, ip tracking, autocomplete of places, geocoding, reverse gecoding...) with ease.

Using this lightweight library you will not need to struggle with CoreLocation's delegate and settings anymore; just ask for data and wait for it: SwiftLocation calibrate CLLocationManager's settings (distanceFilter, accuracy...) for you based upon running requests.

## Index

- [Main Concepts](#main_concepts)
- [Request Authorization](#request_authorization)
	- [Configure Info.plist in iOS 8-10](#configure_ios810)
	- [Configure Info.plist in iOS 11+](#configure_ios11)
	- [Explicitly ask for Authorization](#explicitly_ask_authorization)
	- [Observe Authorization State Changes](#observe_auth_changes)
- [Get Current Location via GPS](#user_location_gps)
- [Get Current Location via GPS with fixed min interval/distance](#minintervaldistance)
- [Get Current Location via IP](#user_location_ip)
- [Background Monitoring (Significant)](#background_monitoring)
- [Heading Updates](#heading_updates)
- [Geocoding/Reverse Geocoding](#geocoding)
- [Autocomplete](#autocomplete)
- [iBeacon Tracking](#ibeacon)

<a name="main_concepts"/>

### Main Concepts

All the SwiftLocation's services are exposed using the concept of request. Using the `LocationManager.shared` singleton you can call one of the available methods to request something; it will create a request for you, start & return it as output; You don't need to keep it alive (SwiftLocation's will take care of it for its entire lifecycle) but you may want to store it somewhere to manage it (this maybe useful when working with continous location requests and you want to pause or stop it).

Each request may have one or multiple `observers`; once the request will receive new data it will dispatch the result to any of subscribed callbacks by passing a [`Result`](https://www.swiftbysundell.com/posts/the-power-of-result-types-in-swift) type.
You can add/remove observers by accessing to `.observer` property of the request and using `add()`, `remove()` (you need to pass a previously saved from `.add()` observer ID) or `removeAll()` function.

Request can be stopped via `.stop()` (and it will be removed from queue) or paused via `.pause()` (stay on queue but did not receive events).

That's all, you are now ready to look a the functions!

<a name="request_authorization"/>

### Request Authorization

SwiftLocation automatically handles obtaining permission to access location services of the host machine when you issue a location request and user has not granted your app permissions yet.

<a name="configure_ios810"/>

#### Configure Info.plist in iOS 8-10

Starting with iOS 8, you must provide a description for how your app uses location services by setting a string for the key `NSLocationWhenInUseUsageDescription` or `NSLocationAlwaysUsageDescription` in your app's `Info.plist` file.

SwiftLocation determines which level of permissions to request based on which description key is present. You should only request the minimum permission level that your app requires, therefore it is recommended that you use the "When In Use" level unless you require more access. If you provide values for both description keys, the more permissive "Always" level is requested.

You can change how SwiftLocation can decide what kind of authorization to pick by changing the `LocationManager.shared.preferredAuthorization` property.

<a name="configure_ios11"/>

#### Configure Info.plist in iOS 11+

Starting with iOS 11, you must provide a description for how your app uses location services by setting a string for the key `NSLocationAlwaysAndWhenInUseUsageDescription` as well as a key for `NSLocationWhenInUseUsageDescription` in your app's `Info.plist` file.

<a name="explicitly_ask_authorization"/>

#### Explicitly ask for Authorization

Sometimes you may not want to wait for automatic authorization request; this is especially true for on-boarding screen where you may want to ask for them directly to your user.

In case you need to ask, at certain point of your flow for user's location permission, you just need to call:

`LocationManager.shared.requireUserAuthorization()`

followed by your desired mode (`.whenInUse` or `.always`).

You can also omit the authorization mode. In this case SwiftLocation determines which level of permissions to request based on which description key is present in your app's Info.plist (If you provide values for both description keys, the more permissive Always level is requested.). If you need to set the authorization manually be sure to call this function before adding any request.

<a name="observe_auth_changes"/>

#### Observe Authorization State Changes

You can also observe for changes in authorization status by subscribing auth changes events:

```swift
let observerID = LocationManager.shared.onAuthorizationChange.add { newState in
  print("Authorization status changed to \(newState)")
}
```

When you register an observer in LocationManager or a request you can also keep the returned observerID (an UInt64) you can use to discard it once it will be not useful anymore.

To remove an observer:

```swift
// Remove a specific observer of the onAuthorizationChange
LocationManager.shared.onAuthorizationChange.remove(observerID)
// Remove all observers
LocationManager.shared.onAuthorizationChange.removeAll()        
```

<a name="user_location_gps"/>

### Get Current Location via GPS

To get the current location using the device's GPS module you can use the `locateFromGPS()` function of the `LocationManager` singleton.

It will accepts the following parameters:

| Parameter 	| Type 	| Description 	|
|----------------	|--------------------------------	|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	|
| `subscription` 	| `LocationRequest.Subscription` 	| Type of subscription: `oneShot` create a subscription which expires once fulfilled (or rejected); `continuous` create an indefinitely running request, while `significant` create a request which returns only significant location changes. 	|
| `accuracy` 	| `Accuracy` 	| The minimum accuracy level threshold accepted by the request to dispatch a new value. See the table below for a complete list of values. `significant` subscription will ignore this paramter. 	|
| `distance` 	| `CLLocationDistance?` 	| The minimum distance (measured in meters) a device must move horizontally before an update event is generated 	|
| `activity` 	| `CLActivityType` 	| The location manager uses the information in this property as a cue to determine when location updates may be automatically paused. `significant` subscription will ignore this paramter. 	|
| `timeout` 	| `Timeout.Mode?` 	| if set a valid timeout interval to set; if you don't receive events in this interval requests will expire. Delayed timeout will be started once the user grant permissions; absolute timeout starts once the request is enqueued. `nil` means no timeout. `significant` subscription will ignore this paramter.	|
| `result` 	| `LocationRequest.Callback` 	| the first observer which will receive data from request (you can add multiple observer by managing the `observers` property of the returned request instance. 	|

**Accuracy** levels are:

| Accuracy         | Description |
|----------------|------------------------------------------------------------------------------|
| `any`         | no filter is applied |
| `city`         | (lowest accuracy) 5000 meters or better, received within the last 10 minutes |
| `neighborhood` | 1000 meters or better, received within the last 5 minutes                    |
| `block`        | 100 meters or better, received within the last 1 minute                      |
| `house`        | 15 meters or better, received within the last 15 seconds                     |
| `room`         | (highest accuracy) 5 meters or better, received within the last 5 seconds    |

The timeout parameter specifies how long you are willing to wait for a location with the accuracy you requested. The timeout guarantees that your block will execute within this period of time, either with a location of at least the accuracy you requested (succeded), or with whatever location could be determined before the timeout interval was up (timedout).

**Timeout** can be specified as:

- `after(_: TimeInterval)`: timeout occours after specified interval regardeless the needs of authorizations from the user.
- `delayed(_: TimeInterval)`: delay the start of the timeout countdown until the user has responded to the system location services permissions prompt (if the user hasn't allowed or denied the app access yet).

Inside the callback you will receive an object of type `CLLocation`.

The following example show how to create a continous location monitoring request:

```swift
let req = LocationManager.shared.locateFromGPS(.continous, accuracy: .city) { result in
  switch result {
    case .failure(let error):
      debugPrint("Received error: \(error)")
    case .success(let location):
      debugPrint("Location received: \(location)")
  }
}

// You can optionally keep returned instance of the request around in order to manage it, ie. to remove it:
req.stop() // remove from queue
req.pause() // pause events dispatching, request still in queue
```
<a name="minintervaldistance"/>

### Get Current Location via GPS with fixed min interval/distance

You can also subscribe to continuos location updates by filtering data using constraints on minimum passed time interval (since the last accepted location) and/or minimum distance (since the last accepted location).
Keep in mind: location manager still works even if data is not passed to the the request callback so you should pick the right `accuracy` parameter to balance the energy consuption and quality of the data.

This is an example of the code:

```swift
let request = LocationManager.shared.locateFromGPS(.continous, accuracy: .city) { data in
  switch data {
    case .failure(let error):
      print("Location error: \(error)")
    case .success(let location):
      print("New Location: \(location)")
  }
}
request.dataFrequency = .fixed(minInterval: 40, minDistance: 100) // minimum 40 seconds & 100 meters since the last update. 
```

<a name="user_location_ip"/>

### Get Current Location via IP

Sometimes you may not need to get the exact location of the user and bother it asking for permissions. In this case an approximate location maybe enough; you can get it by using one of the external services provided by SwiftLocation.

Currently supported services:

| Service 	| API Required 	| URL 	|
|------------	|--------------	|-------------------------	|
| ip-api.com 	| no 	| http://ip-api.com/json/ 	|
| apiapi.co 	| no 	| https://ipapi.co/json 	|
| freeGeoIP 	| yes (free) 	| https://freegeoip.net (NO YET SUPPORTED)	|
| smartIP 	| no 	| http://smart-ip.net (NO YET SUPPORTED) 	|

**Are you interested in adding another custom service? Fell free to make a PR!**

Making a request is pretty simple and you will receive an object of type `IPPlace` which is a class with the following properties:

```swift
public class IPPlace {
    let city: String?
    let countryCode: String?
    let countryName: String?
    let ip: String?
    let isp: String?
    let coordinates: CLLocationCoordinate2D?
    let organization: String?
    let regionCode: String?
    let regionName: String?
    let timezone: String?
    let zipCode: String?
}
```

This is an example of the call:

```swift
LocationManager.shared.locateFromIP(service: .ipAPI) { result in
  switch result {
    case .failure(let error):
      debugPrint("An error has occurred while getting info about location: \(error)")
    case .success(let place):
      debugPrint("You are at \(place.coordinates)")
  }
}
```
<a name="background_monitoring"/>

### Background Monitoring (Significant)

If your app has acquired the always location services authorization and your app is terminated with at least one active significant location change subscription (see above), your app may be launched in the background when the system detects a significant location change.

Please note: when the app terminates, all of your active location requests and subscriptions with SwiftLocation are canceled automatically. Therefore, when the app launches due to a significant location change, you should immediately use SwiftLocation to set up a new subscription for significant location changes in order to receive the location information.

A good point to do it is the application's AppDelegate:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
  /// If you start monitoring significant location changes and your app is subsequently terminated,
  /// the system automatically relaunches the app into the background if a new event arrives.
  // Upon relaunch, you must still subscribe to significant location changes to continue receiving location events.
  if let _ = launchOptions?[UIApplicationLaunchOptionsKey.location] {
    LocationManager.shared.locateFromGPS(.significant, accuracy: .any) { data in
      // ....
   }
 }
}
```

<a name="heading_updates"/>

### Heading Updates

To subscribe to continuous heading updates, use the method `LocationManager.shared.headingSubscription()` function.

It requires the following parameters:

- `accuracy`: minimum accuracy (expressed in degrees) you want to receive. nil to receive all events.
- `minInterval`: minimum interval between each request. nil to receive all events regardless the interval.

The block will execute indefinitely (until canceled), once for every new updated heading regardless of its accuracy. Note that if heading requests are removed or canceled, the manager will automatically stop updating the device heading in order to preserve battery life.

If an error occurs, the block will execute with a status other than succeded (error callback), and the subscription will only be automatically canceled if the device doesn't have heading support (i.e. for error unavailable).

Example:

```swift
LocationManager.shared.headingSubscription(accuracy: 2, minInterval: 10) { result in
   // data
}        
```
<a name="geocoding"/>

### Geocoding/Reverse Geocoding

SwiftLocation supports both geocoding and reverse geocoding:

- `locateFromCoordinates()`: to get a list of places at given coordinates
- `locateFromAddress()`: to get a list of places at given address.

The following services are supported as `service` parameter of the both function; the column Option Class define which object you need to instantiate in order to customize service's search.  

| Geocoder 	| Type 	| Option Class 	|
|------------	|---------------	|-------------------------------------	|
| Apple 	| `.apple(_)` 	| `GeocoderRequest.Options` 	|
| Google 	| `.google(_)` 	| `GeocoderRequest.GoogleOptions` 	|
| OpenStreet 	| `.openStreet(_)` 	| `GeocoderRequest.OpenStreetOptions` 	|

Some example:

```swift
let options = GeocoderRequest.GoogleOptions(APIKey: "<GOOGLE API KEY>")
let coordinates = CLLocationCoordinate2DMake(..., ...)

LocationManager.shared.locateFromCoordinates(coordinates, service: .google(options)) { result in
  switch result {
    case .failure(let error):
      debugPrint("An error has occurred: \(error)")
    case .success(let places):
      debugDescription("Found \(places.count) places!")
  }
}
```

```swift
let options = GeocoderRequest.OpenStreetOptions()
options.locale = "it"
options.limit = 1
let restrictedSearchRegion = // CLRegion

LocationManager.shared.locateFromAddress("<ADDRESS>", inRegion: restrictedSearchRegion, timeout: nil, service: .openStreet(options)) { data in
switch result {
    case .failure(let error):
      debugPrint("An error has occurred: \(error)")
    case .success(let places):
      debugDescription("Found \(places.count) places!")
  }
}
```

Both of these calls return a array of objects of type `Place`.
`Place` is an intermediary object used to represent a place in the same way for all supported services.

Properties:

```swift
public class Place {
   let placemark: CLPlacemark?
    let name: String?
    let coordinates: CLLocationCoordinate2D?

    let state: String?
    let county: String?
    let neighborhood: String?
    let city: String?
    let country: String?
    let isoCountryCode: String?
    let postalCode: String?
    let streetNumber: String?
    let streetAddress: String?
    let formattedAddress: String?
    let areasOfInterest: [String]?

    let region: CLRegion?
    let timezone: TimeZone?
    let postalAddress: CNPostalAddress?
    let addressDictionary: [AnyHashable: Any]?
}
```
<a name="autocomplete"/>

## Autocomplete

Autocomplete functionality is mostly used in conjuction with maps in order to provide suggestions for places or address in a particular region.

SwiftLocation supports Apple and Google (require API Key) services for autocomplete feature.

Autocomplete is exposed by the `LocationManager.shared.autocomplete()` function which takes the following arguments:

| Argument 	| Type 	| Description 	|
|----------------	|---------------------------------	|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	|
| `partialMatch` 	| `AutocompleteRequest.Operation` 	| `partialSearch(_)`: it's a partial search operation. Usually it's used when you need to provide a search,inside search boxes of the map. Once you have the full query or the address you can,///,use a placeDetail search to retrive more info about the place. `placeDetail(_)`: when you have a full search query (from services like apple) or the place id (from service like google),you can use this operation to retrive more info about the place. 	|
| `timeout` 	| `Timeout.Mode` 	| it's always `absolute`. If set specify the maximum interval without response to mark the request as timed out. 	|
| `service` 	| `Autocomplete.Service` 	| `apple(AutocompleteRequest.Options?)` or `.google(AutocompleteRequest.GoogleOptions)`. Options is required to use google service because it needs of a valid API key. 	|

Both requests return a list of `PlaceMatch` objects which can be:

- `partialMatch(PlacePartialMatch)` in case of `partialMatch` request. `PlacePartialMatch` is an lightweight objects which just contains the suggestion for string completing (`title`/`subtitle` and `highlightsRanges`).
- `fullMatch(Place)` in case of `placeDetail` request. It contains a standard `Place` object we seen above.

Some examples:

```swift
LocationManager.shared.autocomplete(partialMatch: .partialSearch("Piazza della Rep"), service: .apple(nil)) { result in
  switch result {
    case .failure(let error):
      debugPrint("Request failed: \(error)")
    case .success(let suggestions):
      debugPrint("Find \(suggestions.count) suggestions")
      for suggestion in suggestions {
        debugPrint(place.partialMatch?.title)
      }
  }
}
```

```swift
// placeDetail maybe a placeID (for Google) or a full address string already completed using partialMatch search.
 LocationManager.shared.autocomplete(partialMatch: .placeDetail("Piazza della Repubblica, Roma"), service: .apple(nil)) { result in
  switch result {
    case .failure(let error):
      debugPrint("Request failed: \(error)")
    case .success(let places):
      debugPrint("Find \(places.count) places")
      for place in places {
        debugPrint("Place: \(place.fullMatch?.name)")
      }
    }
}
```

<a name="ibeacon"/>

## iBeacon Tracking

Since 4.2.0 SwiftLocation also support iBeacon's beacons tracking.  

An iBeacon is a device that emits a Bluetooth signal that can be detected by your devices. Companies can deploy iBeacon devices in environments where proximity detection is a benefit to users, and apps can use the proximity of beacons to determine an appropriate course of action. You decide what actions to take based on the proximity of nearby beacons. For example, a department store might deploy beacons identifying each section of the store, and the corresponding app might point out sale items when the user is near each section.

When deploying your iBeacon hardware, you must program each iBeacon with an appropriate proximity UUID, major value, and minor value. These values identify each of your beacons uniquely and make it possible for your app to differentiate between those beacons later.

- The uuid (universally unique identifier) is a 128-bit value that uniquely identifies your app’s beacons.
- The major value is a 16-bit unsigned integer that you use to differentiate groups of beacons with the same UUID.
- The minor value is a 16-bit unsigned integer that you use to differentiate groups of beacons with the same UUID and major value.

Only the UUID is required, but it is recommended that you program all three values into your iBeacon hardware. In your app, you can look for related groups of beacons by specifying only a subset of values.

Tracking a beacon with SwiftLocation is very simple.

```swift
// The UUID is a 128-bit value that uniquely identifies your app’s beacons.
let proximityUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
LocationManager.shared.locateFromBeacons(.continous, proximityUUID: proximityUUID, result:  { result in
  switch result {
    case .failure(let error): 
        // something went wrong
    case .success(let beaconsFound):
        // beacons found     
        doSomethingWithBeacons(beaconsFound)                      
  }
})

func doSomethingWithBeacons(_ beacons: [CLBeacon]) {
  guard beacons.isEmpty == false else {
    return
  }
 
   let nearestBeacon = beacons.first!
   let major = CLBeaconMajorValue(nearestBeacon.major)
   let minor = CLBeaconMinorValue(nearestBeacon.minor)
        
   switch nearestBeacon.proximity {
        case .near, .immediate:
            // Display information about the relevant exhibit.
            break
                
        default:
           // Dismiss exhibit information, if it is displayed.
           break
        }
    }
}
```

### Tip

When deploying beacons, consider giving each one a unique combination of UUID, major, and minor values so that you can distinguish among them. If multiple beacons use the same UUID, major, and minor values, the array of beacons delivered to the request reponse method might be differentiated only by their proximity and accuracy values.

## Copyright

SwiftLocation is currently owned and maintained by Daniele Margutti.
It's licensed under MIT License.

<div>Icons made by <a href="https://www.flaticon.com/<?=_('authors').'/'?>eucalyp" title="Eucalyp">Eucalyp</a> from <a href="https://www.flaticon.com/" 		    title="Flaticon">www.flaticon.com</a> is licensed by <a href="http://creativecommons.org/licenses/by/3.0/" 		    title="Creative Commons BY 3.0" target="_blank">CC 3.0 BY</a></div>
