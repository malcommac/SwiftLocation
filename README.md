<p align="center" >
<img src="https://raw.githubusercontent.com/malcommac/SwiftLocation/3.0.0/logo.png" width=385px height=116px alt="SwiftLocation" title="SwiftLocation">
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

Main features of the library includes:

| Feature                     | Description                                                                                                                                                                            |
|-----------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Efficient Power Manager** | SwiftLocation automatically manage power consumption based upon currently running requests. It 1turns off hardware when not used, automatically.                                       |
| **Location Monitoring**     | Easily monitor for your with desired accuracy and frequency (continous monitoring, background monitoring, monitor by distance intervals, interesting places or significant locations). |
| **Device Heading**          | Subscribe and receive continous device's heading updates                                                                                                                               |
| **Reverse Geocoder**        | Get location from address string or coordinates using three different services: Apple (built-in), Google (require API Key) and OpenStreetMap.                                          |
| **Autocomplete Places**     | Implement your places autocomplete search with just one call, including place's details (it uses Google API)                                                                           |
| **IP Address Location**     | Fetch current location without user authorization using device's IP address (4 services supported: freeGeoIP, petabyet, smartIPor telize)                                              |



