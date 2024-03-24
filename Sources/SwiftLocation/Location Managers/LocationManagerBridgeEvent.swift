//
//  SwiftLocation
//  Async/Await Wrapper for CoreLocation
//
//  Copyright (c) 2023 Daniele Margutti (hello@danielemargutti.com).
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import CoreLocation

/// This is the list of events who can be received by any task.
public enum LocationManagerBridgeEvent {
    
    // MARK: - Authorization
    
    case didChangeLocationEnabled(_ enabled: Bool)
    case didChangeAuthorization(_ status: CLAuthorizationStatus)
    case didChangeAccuracyAuthorization(_ authorization: CLAccuracyAuthorization)

    // MARK: - Location Monitoring
    
    case locationUpdatesPaused
    case locationUpdatesResumed
    case receiveNewLocations(locations: [CLLocation])
    
    // MARK: - Region Monitoring
    
    #if !os(visionOS)
    case didEnterRegion(_ region: CLRegion)
    case didExitRegion(_ region: CLRegion)
    case didStartMonitoringFor(_ region: CLRegion)
    #endif
    
    // MARK: - Failures
    
    case didFailWithError(_ error: Error)
    
    #if !os(visionOS)
    case monitoringDidFailFor(region: CLRegion?, error: Error)
    #endif
    
    // MARK: - Visits Monitoring

    #if !os(watchOS) && !os(tvOS) && !os(visionOS)
    case didVisit(visit: CLVisit)
    #endif
    
    // MARK: - Headings
    
    #if os(iOS)
    case didUpdateHeading(_ heading: CLHeading)
    #endif
    
    // MARK: - Beacons
    
    #if !os(watchOS) && !os(tvOS) && !os(visionOS)
    case didRange(beacons: [CLBeacon], constraint: CLBeaconIdentityConstraint)
    case didFailRanginFor(constraint: CLBeaconIdentityConstraint, error: Error)
    #endif
}
