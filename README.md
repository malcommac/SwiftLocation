![SwiftLocation](https://raw.githubusercontent.com/malcommac/SwiftLocation/master/logo.png)


SwiftLocation
=============
####Easy Location Services and Beacon Monitoring for Swift

[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/SwiftLocation.svg)](https://img.shields.io/cocoapods/v/SwiftLocation.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/SwiftLocation.svg?style=flat)](http://cocoadocs.org/docsets/SwiftLocation)
[![Twitter](https://img.shields.io/badge/twitter-@danielemargutti-blue.svg?style=flat)](http://twitter.com/danielemargutti)

SwiftLocation is a lightweight library you can use to monitor locations, make reverse geocoding (both with Apple and Google's services) monitor beacons and do beacon advertising.
It's really easy to use and it's compatible both with Swift 2.2, 2.3 and 3.0.

Main features includes:

- **Auto Management of hardware resources**: SwiftLocation turns off hardware if not used by our observers. Don't worry, we take care of your user's battery usage!
- **Complete location monitoring:** you can easily monitor for your desired accuracy and frequency (continous monitoring, background monitoring, monitor by distance intervals, interesting places or significant locations).
- **Device's heading observer**: you can observe or get current device's heading easily
- **Reverse geocoding** (from address string/coordinates to placemark) using both Apple and Google services (with support for API key)
- **GPS-less location fetching** using network IP address
- **Geographic region** monitoring (enter/exit from regions)
- **Beacon Family and Beacon** monitoring
- **Set a device to act like a Beacon** (only in foreground)

###Pre-requisites

Before using SwiftLocation you must configure your project to use location services. First of all you need to specify a value for ```NSLocationAlwaysUsageDescription``` or ```NSLocationWhenInUseUsageDescription``` into your application's Info.plist file. The string value you add will be shown along with the authorization request the first time your app will try to use location services hardware.

If you need background monitoring you should specify ```NSLocationAlwaysUsageDescription``` and specify the correct value in ```UIBackgroundModes``` key (you can learn more [here](https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html))

###SwiftLocation in your next big project? Tell it to me!

I'm collecting all the apps which uses SwiftLocation to manage beacon or location. If you are using SwiftLocation in your project please fill a PR to this file or send an email to hello@danielemargutti.com.

From SwiftLocation 0.x to 1.0
-------
Several changes are made from 0.x branch to 1.0 especially from the side of the location manager.
It's pretty easy to align your project with this news version.
Since 1.0 we will keep the API stable and any change will use @available metatag of Swift to keep you in track.

Changes are:

#### Renamed Methods
- ```LocationManager.shared.``` is now replaced by ```Location.```
- ```BeaconManager.shared.``` is now replaced by ```Beacon.```
- Each request is conform to ```Request``` protocol. Where allowed you can use ```start()```, ```pause()``` or ```cancel()``` a running request.
- ```observeLocations()``` is now replaced with ```getLocation()``` (and it allows you to specify a custom timeout)
- ```observeInterestingPlaces()``` is now replaced with ```getInterestingPlaces()```
- Reverse geocoding services are now under the ```reverse``` function umbrella (```reverse(location:...), reverse(address:... and reverse(coordinates:...)```)

#### Other Changes
- ```Accuracy``` now include IP Address Scan (```.IPScan```) to get the current location (```locateByIPAddress()``` was removed). It works as usual, without asking sensor authorization to the user.
- ```observeHeading()``` is now replaced with ```getHeading```. Heading services now works correctly and allow you to specify a frequency (```HeadingFrequency```: ```.Continous(interval)``` to receive new heading at specified time intervals; ```.TrueNorth(minDegree)``` and ```.MagneticNorth(minDegree)``` allows you to receive events only when a specified deviation from the last catched heading is reported).
- ```HeadingRequest``` has now a ```allowsCalibration``` property instead of a ```onCalibrationRequired()``` function.
- ```onSuccess``` handler in ```HeadingRequest``` is now ```onReceiveUpdates```

Documentation
-------

* **Monitor Current User Location (one shout, continous delivery etc.)**
* **Obtain Current Location without GPS**
* **Monitor Device Heading**
* **Reverse Address/Coordinates to CLPlacemark**
* **Monitor Interesting Visits**
* **Monitor Geographic Regions**
* **Monitor Beacons & Beacon Families**
* **Act like a Beacon**

#### Monitor Current User Location (one shot, continous delivery etc.)

Getting current user's location is pretty easy; all location related services are provided by the ```LocationManager``` singleton class.

```swift
Location.getLocation(withAccuracy: .Block, onSuccess: { foundLocation in
	// Your desidered location is here
}) { (lastValidLocation, error) in
	// something bad has occurred
	// - error contains the error occurred
	// - lastValidLocation is the last found location (if any) regardless specified accuracy level			
}
```

When you create a new observer you will get a request object ```LocationRequest``` you can use to change on the fly the current observer configuration or stop it.

This is an example:

```swift
Location.getLocation(withAccuracy: .Block, frequency: .OneShot, timeout: 50, onSuccess: { (location) in
	// You will receive at max one event if desidered accuracy can be achieved; this because you have set .OneShot as frequency.
}) { (lastValidLocation, error) in
}
// Sometimes in the future
request.stop() // Stop receiving updates
request.pause() // Temporary pause events
request.start() // Restart a paused request
```

```LocationRequest``` also specify a ```timeout``` property you can set to abort the request itself if no valid data is received in a certain amount of time. By default it's set to ```30 seconds``` (you can change directly at init time in ```getLocation()``` functions or by changing the ```.timeout``` property of the request itself)

```Location.getLocation()``` lets you to specify two parameters: the ```accuracy``` you need to get and the ```frequency``` intervals you want to use to get updated locations.

**ACCURACY**:

* ```IPScan```: (Network connection is required). Get an approximate location by using device's IP addres. It does not require GPS sensor or user authorizations.
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
Location.getLocation(withAccuracy: .IPScan, onSuccess: { (location) in
	// approximate location is here
}) { (lastValidLocation, error) in
	// something wrong has occurred; error will tell you what
}
```

#### Monitor Device Heading

You can get data about current device's heading using observeHeading() function.

```swift
Location.getHeading(HeadingFrequency.Continuous(interval: 5), accuracy: 1.5, allowsCalibration: true, didUpdate: { newHeading in
	// each changes of at least 1.5 degree and 5 seconds after the last measurement is reported here
}) { error in
	// something bad occurred
}
```

#### Reverse Address/Coordinates to CLPlacemark

You can do a reverse geocoding from a given pair of coordinates or a readable address string. You can use both Google or Apple's services to perform these request.

Swift location provides three different methods:

* ```reverse(address:using:onSuccess:onError)```: allows you to get a ```CLPlacemark``` object from a source address string. It require ```service``` (```.Apple``` or ```.Google```) and an ```address``` string.
* ```reverse(coordinates:using:onSuccess:onError:)```: allows you to get a ```CLPlacemark``` object from a source coordinates expressed as ```CLLocationCoordinate2D```.
* ```reverse(location:using:onSuccess:onError:)``` the same of the previous method but accept a ```CLLocation``` as source object.

Some examples:

```swift
let addString = "1 Infinite Loop, Cupertino"
Location.reverse(address: addString, onSuccess: { foundPlacemark in
	// foundPlacemark is a CLPlacemark object
}) { error in
	// failed to reverse geocoding due to an error
}
```
```swift
let coordinates = CLLocationCoordinate2DMake(41.890198, 12.492204)
Location.reverse(coordinates: coordinates, onSuccess: { foundPlacemark in
	// foundPlacemark is a CLPlacemark object
}) { error in
	// failed to reverse geocoding due to an error
}
```

#### Monitor Interesting Visits

```CoreLocation``` allows you to get notified when user visits an interesting place by returning a ```CLVisit``` object: it encapsulates information about interesting places that the user has been. Visit objects are created by the system. The visit includes the location where the visit occurred and information about the arrival and departure times as relevant. You do not create visit objects directly, nor should you subclass ```CLVisit```.

You can add a new handler to get notification about visits via ```getInterestingPlaces(onDidVisit:)``` function.

```swift
Location.getInterestingPlaces { newVisit in
	// a new CLVisit object is returned
}
```

#### Monitor Geographic Regions

You can monitor a specific geographic region identified by a center point and a radius (expressed in meters) and get notified about enter and exit events.
When you are working with geographic region or beacon, methods are provided by ```BeaconManager``` singleton class.

```swift
let coordinates = CLLocationCoordinate2DMake(41.890198, 12.492204)
let request = Beacon.monitorGeographicRegion(centeredAt: coordinates, radius: 1400, onEnter: { in
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
let request = Beacon.monitorForBeaconFamily(proximityUUID: familyUUID, onRangingBeacons: { beaconsFound in
	// beaconsFound is an array of found beacons ([CLBeacon])
}) { error in
	// something bad happened
}
// Sometimes in the future you may decide to stop observing
request.stop()
```

To monitor a particular beacon:

```swift
let request = Beacon.monitorForBeacon(proximityUUID: familyUUID, major: majorID, minor: minorID, onFound: { beaconsFound in
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
let beacon = BeaconRequest(beaconWithUUID: uuid, major: major, minor: minor)	Beacon.advertise(beacon)
```

Installation
-------

This library require iOS 8+ and Swift 2.2.

## CocoaPods
[CocoaPods](<http://cocoapods.org>) is a dependency manager for Cocoa projects. You can install it with the following command:

```
$ gem install cocoapods
```

CocoaPods 0.39.0+ is required to build SwiftLocation 1.0.0+.
To integrate SwiftLocation into your Xcode project using CocoaPods, specify it in your Podfile:

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'SwiftLocation', '~> 1.0'
end
```

Then, run the following command:

```
$ pod install
```
## Carthage

[Carthage](<https://github.com/Carthage/Carthage>) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](<http://brew.sh/>) using the following command:

```
$ brew update
$ brew install carthage
```

To integrate SwiftLocation into your Xcode project using Carthage, specify it in your Cartfile:

```
github "malcommac/SwiftLocation" ~> 1.0
```

Run ```carthage update``` to build the framework and drag the built ```SwiftLocation.framework``` into your Xcode project.

Author & License
-------

SwiftLocation was created and mantained by Daniele Margutti.

- Email: [hello@danielemargutti.com](<mailto:hello@danielemargutti.com>)
- Website: [danielemargutti.com](<http://www.danielemargutti.com>)
- Twitter: [@danielemargutti](<http://www.twitter.com/danielemargutti>)

While SwiftLocation is free to use and change (I'm happy to discuss any PR with you) if you plan to use it in your project please consider to add:

```"Location Services provided by SwiftLocation by Daniele Margutti"```

and a link to this GitHub page.

SwiftLocation is available under the MIT license.

See the LICENSE file for more info.
