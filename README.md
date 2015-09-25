![SwiftDate](https://raw.githubusercontent.com/malcommac/SwiftLocation/master/logo.png)

SwiftLocation
=============

<https://travis-ci.org/daniele%20margutti/SwiftLocation>
<http://cocoapods.org/pods/SwiftLocation>
<http://cocoapods.org/pods/SwiftLocation>
<http://cocoapods.org/pods/SwiftLocation>

## What's SwiftLocation?
SwiftLocation is a simple 100% Swift wrapper around CoreLocation. Use Location services has never been easier and you can do it with your favourite language.
Let me show the best features of the library:

- **Auto-managed Hardware services** (heading/location/monitor services are turned off when not used)
- **Reverse geocoding services** (from address/coordinates to location placemark) using both **Apple** own CoreLocation services or external **Google Location APIs**
- Fast and low-powered **IP based device's location** discovery
- **Single shot location discovery** method (with desidered accuracy level) to get current user location with a simple closure as respond
- **Continous location update** methods to get both detailed locations or only significant data only.
- **Region monitor** with a single line of code
- **iBeacon proximity monitor** with a single line of code
- **Fixed user position** simulation

## Future Improvements
I'm looking for your suggestions: feel free to leave your pool request or feature request.
BTW I plan to introduce a GPX simulation engine soon as I can in order to get a realistic simulation of location events.

### Author
Daniele Margutti  
*web*: [www.danielemargutti.com](http://www.danielemargutti.com)  
*twitter*: [@danielemargutti](http://www.twitter.com/danielemargutti)  
*mail*: me [at] danielemargutti dot com  

## Documentation

SwiftLocation is exposed as a singleton class. So in order to call all available methods you need to call ```SwiftLocation.shared.<method>```

## Prepare your project
*(SwiftLocation is compatible with iOS8+. iOS7 is not supported)*
Before using SwiftLocation you need to enable CoreLocation services to your project. First of all add required frameworks into your project: both MapKit and CoreLocation frameworks should be linked (it will be done automatically if you are using SwiftLocation via CocoaPods).
Then you need to provide at least one key into your project's Info.plist between:
- ```NSLocationAlwaysUsageDescription```
- ```NSLocationWhenInUseUsageDescription``` 

In order to provide a description of your request to the end user when the system location alert panel will be presented on screen.
If you are using SwiftLocation with iOS simulator you can also set a fake location using ```.fixedLocation``` and/or ```.fixedLocationDictionary``` (or by setting the location into project scheme settings).

### GET "ONE SHOT" USER LOCATION

To get the current user location without getting a continous update of the data each time, you can use ```currentLocation``` method.
Parameters are:
- ```accuracy```: identify the accuracy of location you want to receive. A more accurate result may require a longer processing time. Accuracy can be: - 
	- ```Country``` (it does not use CoreLocation but only IP based discovery. Results are not accurated but it's faster than any other accuracy level and it does not require user authorizations).
	- ```City```: 5000 meters or better, and received within the last 10 minutes. Lowest accuracy.
	- ```Neighborhood```: 1000 meters or better, and received within the last 5 minutes.
	- ```Block```: 100 meters or better, and received within the last 1 minute.
	- ```House```: 15 meters or better, and received within the last 15 seconds.
	- ```Room```: 5 meters or better, and received within the last 5 seconds. Highest accuracy.
- ```timeout```: the max processing time. When expired error callback is called automatically.
- ```onSuccess```: callback called when a valid result is found
- ```onFail```: callback called when an error or timeout event is occurred

An example:

```swift
SwiftLocation.shared.currentLocation(Accuracy.Neighborhood, timeout: 20, onSuccess: { (location) -> Void in
	// location is a CLPlacemark
}) { (error) -> Void in
	// something went wrong
}
```

### GET ONLY SIGNIFICANT LOCATION UPDATES
When you don't need of a continous update of the user locations you can save user's device power by receiving only significant location updates.
You need to call ```significantLocation()``` method.
As for any other location request you can abort it (or stop receiving updates) by saving it's identifier and using ```cancelRequest()``` method.

Example:

```swift
let requestID = SwiftLocation.shared.significantLocation({ (location) -> Void in
	// a new significant location has arrived
}, onFail: { (error) -> Void in
	// something went wrong. request will be cancelled automatically
})
// Sometime in the future... you may want to interrupt the subscription
SwiftLocation.shared.cancelRequest(requestID)
```


### GET CONTINUOUS LOCATION UPDATES
To get location update continously you can use ```continuousLocation()``` method. It register a new request which live until you cancel it (use returned ```RequestID``` type and ```cancelRequest()``` method to abort any request).
Parameters:
- ```accuracy```: identify the accuracy of location you want to receive. A more accurate result may require a longer processing time.
- ```onSuccess```: callback called when a new location has arrived
- ```onFail```: callback called when an error or timeout event is occurred. Request is cancelled automatically at this point.

Example:
```swift
let requestID = SwiftLocation.shared.continuousLocation(Accuracy.Room, onSuccess: { (location) -> Void in
	// a new location has arrived
}) { (error) -> Void in
	// something went wrong. request will be cancelled automatically
}
// Sometime in the future... you may want to interrupt it
SwiftLocation.shared.cancelRequest(requestID)
```

### REVERSE COORDINATES
You can do a reverse geocoding from a given pair of coordinates or a readable address string. You can use both Google or Apple's services to perform these request.
Methods are: ```reverseAddress()``` and ```reverseCoordinates```.

```reverseAddress()``` parameters are:
- ```service```: service to use. Can be ```Apple``` or ```GoogleMaps```
- ```address```: address string to reverse (ie. '1 Infinite Loop 1, Cupertino')
- ```region```: optional region parameter to specify a more strict region to use (ignored when service is ```GoogleMaps```)
- ```onSuccess```: success callback (contains the CLPlacemark object)
- ```onFail```: error callback (contains an NSError)

```reverseCoordinates()``` is pretty similar but it takes ```coordinates``` as parameter.

Example:

```swift
SwiftLocation.shared.reverseAddress(Service.Apple, address: "1 Infinite Loop, Cupertino (USA)", region: nil, onSuccess: { (place) -> Void in
	// our CLPlacemark is here
}) { (error) -> Void in
	// something went wrong
}
```
```swift
let coordinates = CLLocationCoordinate2DMake(41.890198, 12.492204)
SwiftLocation.shared.reverseCoordinates(Service.Apple, coordinates: coordinates, onSuccess: { (place) -> Void in
	// our placemark is here
}) { (error) -> Void in
	// something went wrong
}
```

### MONITOR A SPECIFIC REGION
You can also monitor a specific region by receiving notifications when user enter or exit from the region itself.
To register a new monitor you need to call ```monitorRegion()``` method.
This is a subscription so you need to get the ```requestID``` to cancel it by using ```cancelRequest()```.

Parameters are:
- ```region```: region to monitor. Must be a subclass of CLRegion
- ```onEnter```: callback called each time user enter into the region bounds
- ```onExit```: callback called each time user exit from the region bounds

Example:
```swift
let regionCoordinates = CLLocationCoordinate2DMake(41.890198, 12.492204)
var region = CLCircularRegion(center: regionCoordinates, radius: CLLocationDistance(50), identifier: "identifier_region")
let requestID = SwiftLocation.shared.monitorRegion(region, onEnter: { (region) -> Void in
	// events called on enter
}) { (region) -> Void in
	// event called on exit
}
// Sometime in the future... you may want to interrupt the subscription
SwiftLocation.shared.cancelRequest(requestID)
```

## BEACON REGION MONITOR
Starts the delivery of notifications for beacons in the specified region.
Use ```monitorBeaconsInRegion()``` method.
Parameters are:
- ```region```: ```CLBeaconRegion``` to monitor
- ```onRanging```: handler called every time one or more beacon are in range, ordered by distance (closest is the first one)

Example:

```swift
let bRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: "ciao"), identifier: "myIdentifier")
let requestID = SwiftLocation.shared.monitorBeaconsInRegion(bRegion, onRanging: { (regions) -> Void in
	// events called on ranging
})
// Sometime in the future... you may want to interrupt the subscription
SwiftLocation.shared.cancelRequest(requestID)
```

## CANCEL A SUBSCRIPTION
To cancel a subscription or a request you need to call the identifier provided at creation time.

```swift
SwiftLocation.shared.cancelRequest(requestID)
```

To cancel all running requests you can call ```cancelAllRequests()```:

```swift
SwiftLocation.shared.cancelAllRequests()
```

Requirements
------------
This library require iOS 8+ and Swift 2.0


Installation
------------

SwiftLocation is available through [CocoaPods](<http://cocoapods.org>). To
install it, simply add the following line to your Podfile:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pod "SwiftLocation"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


License
-------

SwiftLocation is available under the MIT license. See the LICENSE file for more
info.