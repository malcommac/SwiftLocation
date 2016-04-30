![SwiftDate](https://raw.githubusercontent.com/malcommac/SwiftLocation/develop/swiftlocation.png)

SwiftLocation
=============

### What's SwiftLocation?
SwiftLocation is a lightweight library you can use to monitor locations, beacons, make reverse geocoding and do beacon advertising. It's really easy to use and made in pure Swift 2.2.

Main features includes:

- **Auto Management of hardware resources**: SwiftLocation turns off hardware if not used by our observers.
- **Complete location monitoring:** you can easily monitor for you desidered accuracy and frequency (continous monitoring, background monitoring, monitor by distance intervals, interesting places or significant locations).
- **Device's heading observer**: you can observe or get current device's heading easily
- **Reverse geocoding** (from address string/coordinates to placemark) using both Apple and Google services
- **GPS-less location fetching** using network IP address
- **Geographic region** monitoring (enter/exit from regions)
- **Beacon Family and Beacon** monitoring
- **Set a device to act like a Beacon** (only in foreground)

Pre-requisites

Before using SwiftLocation you must configure your project to use location services. First of all you need to specify a value for NSLocationAlwaysUsageDescription or NSLocationWhenInUseUsageDescription into your application's Info.plist file. The string value you add will be shown along with the authorization request the first time your app will try to use location services hardware.

If you need background monitoring you should specify NSLocationAlwaysUsageDescription and specify the correct value in UIBackgroundModes key (you can learn more [here](https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html))

### Documentation

#### Monitor Current User Location (one shot, continous...)

Getting current user's location is pretty easy; all location related services are provided by the ```LocationManager``` singleton class.

```swift
LocationManager.shared.observeLocations(.Block, frequency: .OneShot, onSuccess: { location in
	// location contain your CLLocation object
}) { error in
	// Something went wrong. error will tell you what
}
```

When you create a new observer you will get a request object ```LocationRequest``` you can use to change on the fly the current observer configuration or stop it.

This is an example:

```swift
let request = LocationManager.shared.observeLocations(.Block, frequency: .OneShot, onSuccess: { location in ... }) { error in ... }
// Sometimes in the future
request.stop() // Stop receiving updates
```

```LocationRequest``` also specify a ```timeoutTimer``` property you can set to abort the request itself if no valid data is received in a certain amount of time. By default it's disabled.

```observeLocation()``` lets you to specify two parameters: the ```accuracy``` you need to get and the ```frequency``` intervals you want to use to get updated locations.

**ACCURACY**:

* ```Any```: First available location is accepted, no matter the accuracy
* ```Country```: Only locations accurate to the nearest 100 kilometers are dispatched
* ```City```: Only locations accurate to the nearest three kilometers are dispatched
* ```Neighborhood```: Only locations accurate to the nearest kilometer are dispatched
* ```Block```: Only locations accurate to the nearest one hundred meters are dispatched
* ```House```: Only locations accurate to the nearest ten meters are dispatched
* ```Room```: Use the highest-level of accuracy, may use high energy
* ```Navigation```: Use the highest possible accuracy and combine it with additional sensor data



**FREQUENCY:**

* ```Continuous```: receive each new valid location, never stop (you must stop it manually)
* ```OneShot```: the first valid location data is received, then the request will be invalidated
* ```ByDistanceintervals(meters)```: receive a new update each time a new distance interval is travelled. Useful to keep battery usage low
* ```Significant```: receive only valid significant location updates. This capability provides tremendous power savings for apps that want to track a user’s approximate location and do not need highly accurate position information



#### Obtain Current Location without GPS

Sometimes you could need to get the current approximate location and you may not need to turn on GPS hardware and waste user's battery. When accuracy is not required you can locate the user by it's public network IP address (obviously this require an internet connection).

```swift
LocationManager.shared.locateByIPAddress(onSuccess: { placemark in
	// placemark is a valid CLPlacemark object			
}) { error in
	// something wrong has occurred; error will tell you what
}
```

#### Monitor Device Heading

You can get data about current device's heading using observeHeading() function.

```swift
let request = LocationManager.shared.observeHeading(onSuccess: { heading in
	// a valid CLHeading object is returned
}) { error in
	// something wrong has occurred		
}
// You can decide to monitor only certain delta of orientation
request.degreesInterval = 20
// Sometimes in the future
request.stop()
```

#### Reverse Address/Coordinates to CLPlacemark

You can do a reverse geocoding from a given pair of coordinates or a readable address string. You can use both Google or Apple's services to perform these request.

Swift location provides three different methods:

* ```reverseAddress(service:address:onSuccess:onError)```: allows you to get a ```CLPlacemark``` object from a source address string. It require ```service``` (```.Apple``` or ```.Google```) and an ```address``` string.
* ```reverseLocation(service:coordinates:onSuccess:onError:)```: allows you to get a ```CLPlacemark``` object from a source coordinates expressed as ```CLLocationCoordinate2D```.
* ```reverseLocation(service:location :onSuccess:onError:)``` the same of the previous method but accept a ```CLLocation``` as source object.

Some examples:

```swift
let address = "1 Infinite Loop, Cupertino (USA)"
LocationManager.shared.reverseAddress(address: address, onSuccess: { foundPlacemark in
	// foundPlacemark is a CLPlacemark object
}) { error in
	// failed to reverse geocoding due to an error			
}
```
```swift
let coordinates = CLLocationCoordinate2DMake(41.890198, 12.492204)
// Use Google service to obtain placemark
LocationManager.shared.reverseLocation(service: .Google, coordinates: coordinates, onSuccess: { foundPlacemark in
	// foundPlacemark is a CLPlacemark object
}) { error in
	// failed to reverse geocoding
}
```

#### Monitor Interesting Visits

CoreLocation allows you to get notified when user visits an interesting place by returning a CLVisit object: it encapsulates information about interesting places that the user has been. Visit objects are created by the system. The visit includes the location where the visit occurred and information about the arrival and departure times as relevant. You do not create visit objects directly, nor should you subclass CLVisit.

You can add a new handler to get notification about visits via observeInterestingPlaces(handler:) function.

```swift
LocationManager.shared.observeInterestingPlaces { newVisit in
	// a new CLVisit object is returned
}
```

#### Monitor Geographic Regions

You can monitor a specific geographic region identified by a center point and a radius (expressed in meters) and get notified about enter and exit events.
When you are working with geographic region or beacon, methods are provided by ```BeaconManager``` singleton class.

```swift
let coordinates = CLLocationCoordinate2DMake(41.890198, 12.492204)
let request = BeaconManager.shared.monitorGeographicRegion(centeredAt: coordinates, radius: 1400, onEnter: { in
	// on enter in region
}) { in
	// on exit from region
}
// Sometimes in the future you may decide to stop observing region
request.stop()
```

#### Monitor Beacons & Beacon Families
You can monitor for a beacon or a beacon family.

To get notifications about beacons of a particular family:

```swift
let request = BeaconManager.shared.monitorForBeaconFamily(proximityUUID: familyUUID, onRangingBeacons: { beaconsFound in
	// beaconsFound is an array of found beacons ([CLBeacon])
}) { error in
	// something bad happened
}
// Sometimes in the future you may decide to stop observing
request.stop()
```

To monitor a particular beacon:

```swift
let request = BeaconManager.shared.monitorForBeacon(proximityUUID: familyUUID, major: majorID, minor: minorID, onFound: { beaconsFound in
	// beaconsFound is an array of found beacons ([CLBeacon]) but in this case it contains only one beacon
}) { error in
	// something bad happened
}
// Sometimes in the future you may decide to stop observing
request.stop()
```

#### Act like a Beacon

You can set your device to act like a beacon (this feature works only in foreground due to some limitations of Apple's own methods).

```swift
let beacon = BeaconRequest(beaconWithUUID: uuid, major: major, minor: minor)	BeaconManager.shared.advertise(beacon)
```

#### Requirements & Installation

This library require iOS 8+ and Swift 2.2.

SwiftLocation is available through [CocoaPods](<http://cocoapods.org>). To
install it, simply add the following line to your Podfile:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pod "SwiftLocation"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


Author & License
-------

SwiftLocation was created and mantained by Daniele Margutti.
Email: hello@danielemargutti.com
Website: http://www.danielemargutti.com

While SwiftLocation is free to use and change (I'm happy to discuss any PR with you) if you plan to use it in your project please consider to add "Location Services provided by SwiftLocation by Daniele Margutti" and a link to this GitHub page.

SwiftLocation is available under the MIT license.

See the LICENSE file for more info.