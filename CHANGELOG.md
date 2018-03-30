### CHANGELOG

#### Version 3.2.3 - [Download](https://github.com/malcommac/SwiftLocation/releases/tag/3.2.3)

- [#204](https://github.com/malcommac/SwiftLocation/issues/204)  - Fixed memory leaks into task closures
- [#203](https://github.com/malcommac/SwiftLocation/issues/203)  - `GeocoderRequest` `cancel()` function is now accessible


#### Version 3.2.2 - [Download](https://github.com/malcommac/SwiftLocation/releases/tag/3.2.2)

- [#202](https://github.com/malcommac/SwiftLocation/issues/202)  - Fix a deadlock while calling events (found on 32 bit machines)


#### Version 3.2.1 - [Download](https://github.com/malcommac/SwiftLocation/releases/tag/3.2.1)

Released on: March 19, 2018

* [#192](https://github.com/malcommac/SwiftLocation/issues/192) Fixes for Place parser from Apple services. Unified shared properties terminology between services. The following properties of `Place` are now deprecated: `state` (use `administrativeArea`),`county` and `cityDistrict` (use `subAdministrativeArea`), `neighborhood` (use `locality`),`postcode` (use `postalCode`), `road` (use `thoroughfare`), `houseNumber` (use `subThoroughfare`)

#### Version 3.2.0 - [Download](https://github.com/malcommac/SwiftLocation/releases/tag/3.1.0) 

Released on: March 16, 2018

- [#197](https://github.com/malcommac/SwiftLocation/issues/197) Added neighborhood and formatted address key in `Place` entity.
- [#181](https://github.com/malcommac/SwiftLocation/issues/181) Fixed an issue with `WhenInUse` authorization under iOS 11 which may cause crashes.
- [#180](https://github.com/malcommac/SwiftLocation/issues/180) `events.listen()` function now returns a `TokenID` you can use to remove event listener callback via `events.remove()`.
- [#186](https://github.com/malcommac/SwiftLocation/pull/186) Added language support to Google Places APIs requests (default is english).
- [#187](https://github.com/malcommac/SwiftLocation/issues/187) Fixed a memory issue with geocoding requests (if you don't keep it alive by assigning the request to a strong var you will not receive responses because the request itself are destroyed immediately). Since this version all requests are keeped strongly by the library itself (you don't need to store them manually anymore and they are removed automatically once finished and events are dispatched). Requests interaction (add/remove of a request) is a thread-safe operation.
- [#189](https://github.com/malcommac/SwiftLocation/pull/189) Added support for HTTPS on freeIP service.

