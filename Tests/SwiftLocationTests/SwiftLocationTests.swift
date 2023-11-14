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

import XCTest
import CoreLocation
@testable import SwiftLocation

final class SwiftLocationTests: XCTestCase {
    
    private var mockLocationManager: MockedLocationManager!
    private var location: Location!
    
    override func setUp() {
        super.setUp()
        
        self.mockLocationManager = MockedLocationManager()
        self.location = Location(locationManager: mockLocationManager)
    }
    
    // MARK: - Tests
    
    /// Tests the location services enabled changes.
    func testMonitoringLocationServicesEnabled() async throws {
        let expectedValues = simulateLocationServicesChanges()
        var idx = 0
        for await event in await self.location.startMonitoringLocationServices() {
            print("Location services enabled did change: \(event.isLocationEnabled ? "enabled" : "disabled")")
            XCTAssertEqual(expectedValues[idx], event.isLocationEnabled, "Failed to get correct values from location services enabled")
            idx += 1
            if idx == expectedValues.count {
                break // terminate the stream will also automatically remove the monitoring.
            }
        }
    }
    
    /// Test authorization status changes.
    func testMonitoringAuthorizationStatus() async throws {
        let expectedValues = simulateAuthorizationStatusChanges()
        var idx = 0
        for await event in await self.location.startMonitoringAuthorization() {
            print("Authorization status did change: \(event.authorizationStatus.description)")
            XCTAssertEqual(expectedValues[idx], event.authorizationStatus, "Failed to get correct values from authorization status")
            idx += 1
            if idx == expectedValues.count {
                break
            }
        }
    }
    
    /// Test accuracy authorization changes.
    func testMonitoringAccuracyAuthorization() async throws {
        let expectedValues = simulateAccuracyAuthorizationChanges()
        var idx = 0
        for await event in await self.location.startMonitoringAccuracyAuthorization() {
            print("Accuracy authorization did change: \(event.accuracyAuthorization.description)")
            XCTAssertEqual(expectedValues[idx], event.accuracyAuthorization, "Failed to get correct values from accuracy authorization status")
            idx += 1
            if idx == expectedValues.count {
                break
            }
        }
    }
    
    #if !os(tvOS)
    /// Test request for permission with failure in plist configuration
    func testRequestPermissionsFailureWithPlistConfiguration() async throws {
        mockLocationManager.onValidatePlistConfiguration = { permission in
            switch permission {
            case .always:
                return LocationErrors.plistNotConfigured
            case .whenInUse:
                return nil
            }
        }
        
        do {
            let newStatus = try await location.requestPermission(.always)
            XCTFail("Permission should fail due to missing plist while it returned \(newStatus)")
        } catch { }
    }
    #endif
    
    func testRequestPermissionWhenInUseSuccess() async throws {
        do {
            let expectedStatus = CLAuthorizationStatus.restricted
            mockLocationManager.onRequestWhenInUseAuthorization = {
                return expectedStatus
            }
            let newStatus = try await location.requestPermission(.whenInUse)
            XCTAssertEqual(expectedStatus, newStatus)
        } catch {
            XCTFail("Request should not fail: \(error.localizedDescription)")
        }
    }
        
    #if !os(tvOS)
    func testRequestAlwaysSuccess() async throws {
        do {
            let expectedStatus = CLAuthorizationStatus.authorizedAlways
            mockLocationManager.onRequestAlwaysAuthorization = {
                return expectedStatus
            }
            
            let newStatus = try await location.requestPermission(.always)
            XCTAssertEqual(expectedStatus, newStatus)
        } catch {
            XCTFail("Request should not fail: \(error.localizedDescription)")
        }
    }
    #endif
    
    /// Test the request location permission while observing authorization status change.
    func testMonitorAuthorizationWithPermissionRequest() async throws {
        mockLocationManager.authorizationStatus = .notDetermined
        XCTAssertEqual(location.authorizationStatus, .notDetermined)
    
        let exp = XCTestExpectation()
        
        let initialStatus = mockLocationManager.authorizationStatus
        Task.detached {
            for await event in await self.location.startMonitoringAuthorization() {
                print("Authorization switched from \(initialStatus) to \(event.authorizationStatus.description)")
                exp.fulfill()
            }
        }

        sleep(1)
        #if os(macOS)
        mockLocationManager.onRequestAlwaysAuthorization = { return .authorizedAlways }
        let newStatus = try await location.requestPermission(.always)
        XCTAssertEqual(newStatus, .authorizedAlways)
        #else
        mockLocationManager.onRequestWhenInUseAuthorization = { return .authorizedWhenInUse }
        let newStatus = try await location.requestPermission(.whenInUse)
        XCTAssertEqual(newStatus, .authorizedWhenInUse)
        #endif
        
        await fulfillment(of: [exp])
    }
    
    /// Test increment of precision and monitoring.
    func testRequestPrecisionPosition() async throws {
        mockLocationManager.authorizationStatus = .notDetermined
        XCTAssertEqual(mockLocationManager.accuracyAuthorization, .reducedAccuracy)
        
        #if os(macOS)
        mockLocationManager.onRequestAlwaysAuthorization = { return .authorizedAlways }
        let newStatus = try await location.requestPermission(.always)
        XCTAssertEqual(newStatus, .authorizedAlways)
        #else
        mockLocationManager.onRequestWhenInUseAuthorization = { return .authorizedWhenInUse }
        let newStatus = try await location.requestPermission(.whenInUse)
        XCTAssertEqual(newStatus, .authorizedWhenInUse)
        #endif
        
        // Test misconfigured Info.plist file
        do {
            mockLocationManager.onRequestValidationForTemporaryAccuracy = { purposeKey in
                return LocationErrors.plistNotConfigured
            }
            let _ = try await location.requestTemporaryPrecisionAuthorization(purpose: "test")
            XCTFail("This should fail")
        } catch {
            XCTAssertEqual(error as? LocationErrors, LocationErrors.plistNotConfigured)
        }
        
        // Test correct configuration
        do {
            mockLocationManager.onRequestValidationForTemporaryAccuracy = { purposeKey in
                return nil
            }
            let newStatus = try await location.requestTemporaryPrecisionAuthorization(purpose: "test")
            XCTAssertEqual(newStatus, .fullAccuracy)
        } catch {
            XCTFail("This should not fail: \(error.localizedDescription)")
        }
    }
    
    #if !os(tvOS)
    /// Test stream of updates for locations.
    func testUpdatingLocations() async throws {
        // Request authorization
        #if os(macOS)
        mockLocationManager.onRequestAlwaysAuthorization = { return .authorizedAlways }
        try await location.requestPermission(.always)
        #else
        mockLocationManager.onRequestWhenInUseAuthorization = { return .authorizedWhenInUse }
        try await location.requestPermission(.whenInUse)
        #endif
        let expectedValues = simulateLocationUpdates()
        var idx = 0
        for await event in try await self.location.startMonitoringLocations() {
            print("Accuracy authorization did change: \(event.description)")
            XCTAssertEqual(expectedValues[idx], event)
            idx += 1
            if idx == expectedValues.count {
                break
            }
        }
    }
    #endif
    
    /// Test one shot request method.
    func testRequestLocation() async throws {
        // Request authorization
        #if os(macOS)
        mockLocationManager.onRequestAlwaysAuthorization = { return .authorizedAlways}
        try await location.requestPermission(.always)
        #else
        mockLocationManager.onRequestWhenInUseAuthorization = { return .authorizedWhenInUse }
        try await location.requestPermission(.whenInUse)
        #endif
        // Check the return of an error
        simulateRequestLocationDelayedResponse(event: .didFailed(LocationErrors.notAuthorized))
        let e1 = try await self.location.requestLocation()
        XCTAssertEqual(e1.error as? LocationErrors, LocationErrors.notAuthorized)
        
        // Check the return of several location
        let now = Date()
        let l1 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 41.915001, longitude: 12.577772),
            altitude: 100, horizontalAccuracy: 50, verticalAccuracy: 20, timestamp: now.addingTimeInterval(-2)
        )
        let l2 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 41.915001, longitude: 12.577772),
            altitude: 100, horizontalAccuracy: 50, verticalAccuracy: 20, timestamp: now.addingTimeInterval(-1)
        )
        let l3 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 41.915001, longitude: 12.577772),
            altitude: 100, horizontalAccuracy: 50, verticalAccuracy: 20, timestamp: now
        )
        simulateRequestLocationDelayedResponse(event: .didUpdateLocations([l1, l2, l3]))
        let e2 = try await self.location.requestLocation()
        XCTAssertEqual(e2.location, l3)
        XCTAssertEqual(e2.locations?.count, 3)
        
        
        // Check the timeout with a filtered location
        do {
            let nonValidLocation = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 41.915001, longitude: 12.577772),
                altitude: 100, horizontalAccuracy: 50, verticalAccuracy: 20, timestamp: Date()
            )
            simulateRequestLocationDelayedResponse(event: .didUpdateLocations([nonValidLocation]))
            
            let _ = try await self.location.requestLocation(accuracy: [
                .horizontal(100)
            ], timeout: 2)
        } catch {
            XCTAssertEqual(error as? LocationErrors, LocationErrors.timeout)
        }
        
        // Check the return of some non filtered locations
        do {
            let now = Date()
            let nonValidLocationByHorizontalAccuracy = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 10, longitude: 5),
                altitude: 100, horizontalAccuracy: 220, verticalAccuracy: 2, timestamp: now
            )
            let nonValidLocationByVerticalAccuracy = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 20, longitude: 9),
                altitude: 100, horizontalAccuracy: 3, verticalAccuracy: 150, timestamp: now
            )
            let validLocation1 = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 30, longitude: 12),
                altitude: 100, horizontalAccuracy: 1, verticalAccuracy: 1, timestamp: now
            )
            let validLocation2 = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: 40, longitude: 10),
                altitude: 100, horizontalAccuracy: 1, verticalAccuracy: 1, timestamp: now.addingTimeInterval(-6)
            )
            
            simulateRequestLocationDelayedResponse(event: .didUpdateLocations([
                nonValidLocationByVerticalAccuracy,
                validLocation1,
                nonValidLocationByHorizontalAccuracy,
                validLocation2
            ]))
            
            let event = try await self.location.requestLocation(accuracy: [
                .horizontal(200),
                .vertical(100)
            ])
            XCTAssertEqual(event.locations?.count, 2)
            XCTAssertEqual(event.location, validLocation1)
        } catch {
            XCTFail("Failed to retrive location: \(error.localizedDescription)")
        }

    }
    
    #if !os(watchOS) && !os(tvOS)
    func testMonitorCLRegion() async throws {
        let (expectedValues, region) = simulateRegions()
        var idx = 0
        for await event in try await self.location.startMonitoring(region: region) {
            print("Monitoring region event received: \(event.description)")
            XCTAssertEqual(expectedValues[idx], event)
            idx += 1
            if idx == expectedValues.count {
                break
            }
        }
    }
    #endif
    
    #if !os(watchOS) && !os(tvOS)
    func testMonitoringVisits() async throws {
        let expectedValues = simulateVisits()
        var idx = 0
        for await event in await self.location.startMonitoringVisits() {
            print("Monitoring region event received: \(event.description)")
            XCTAssertEqual(expectedValues[idx], event)
            idx += 1
            if idx == expectedValues.count {
                break
            }
        }
    }
    #endif
    
    #if !os(watchOS) && !os(tvOS)
    func testMonitoringSignificantLocationChanges() async throws {
        let expectedValues = simulateSignificantLocations()
        var idx = 0
        for await event in await self.location.startMonitoringSignificantLocationChanges() {
            print("Visits received: \(event.description)")
            XCTAssertEqual(expectedValues[idx], event)
            idx += 1
            if idx == expectedValues.count {
                break
            }
        }
    }
    #endif
    
    #if !os(tvOS)
    func testAllowsBackgroundLocationUpdates() async throws {
        location.allowsBackgroundLocationUpdates = true
        XCTAssertEqual(location.allowsBackgroundLocationUpdates, location.locationManager.allowsBackgroundLocationUpdates)
    }
    #endif
        
    // MARK: - Private Functions
    
    #if !os(watchOS) && !os(tvOS)
    private func simulateSignificantLocations() -> [Tasks.SignificantLocationMonitoring.StreamEvent] {
        let sequence: [Tasks.SignificantLocationMonitoring.StreamEvent] = [
            .didFailWithError(LocationErrors.timeout),
            .didResume,
            .didResume,
            .didUpdateLocations([
                CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: 41.915001, longitude: 12.577772),
                    altitude: 100, horizontalAccuracy: 50, verticalAccuracy: 20, timestamp: Date()
                ),
                CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: 41.8, longitude: 12.7),
                    altitude: 97, horizontalAccuracy: 30, verticalAccuracy: 10, timestamp: Date()
                )
            ])
        ]
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            for event in sequence {
                self.mockLocationManager.updateSignificantLocation(event: event)
            }
        })
        return sequence
    }
    #endif
    
    #if !os(watchOS) && !os(tvOS)
    private func simulateVisits() -> [Tasks.VisitsMonitoring.StreamEvent] {
        let sequence: [Tasks.VisitsMonitoring.StreamEvent] = [
            .didVisit(CLVisit()),
            .didFailWithError(LocationErrors.timeout),
            .didVisit(CLVisit())
        ]
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            for event in sequence {
                self.mockLocationManager.updateVisits(event: event)
            }
        })
        return sequence
    }
    #endif
    
    #if !os(watchOS) && !os(tvOS)
    private func simulateRegions() -> (sequence: [Tasks.RegionMonitoring.StreamEvent], region: CLRegion) {
        let region = CLBeaconRegion(uuid: UUID(), identifier: "beacon_1")
        let sequence: [Tasks.RegionMonitoring.StreamEvent] = [
            .didStartMonitoringFor(region: region),
            .didEnterTo(region: region),
            .didExitTo(region: region),
            .monitoringDidFailFor(region: region, error: LocationErrors.timeout)
        ]
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            for event in sequence {
                self.mockLocationManager.updateRegionMonitoring(event: event)
            }
        })
        return (sequence, region)
    }
    #endif
    
    private func simulateRequestLocationDelayedResponse(event: Tasks.ContinuousUpdateLocation.StreamEvent) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.mockLocationManager.updateLocations(event: event)
        })
    }
    
    private func simulateLocationUpdates() -> [Tasks.ContinuousUpdateLocation.StreamEvent] {
        #if os(iOS)
        let sequence: [Tasks.ContinuousUpdateLocation.StreamEvent] = [
            .didUpdateLocations([
                CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: 41.915001, longitude: 12.577772),
                    altitude: 100, horizontalAccuracy: 50, verticalAccuracy: 20, timestamp: Date()
                ),
                CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: 41.8, longitude: 12.7),
                    altitude: 97, horizontalAccuracy: 30, verticalAccuracy: 10, timestamp: Date()
                )
            ]),
            .didPaused,
            .didResume,
            .didFailed(LocationErrors.notAuthorized),
            .didUpdateLocations([
                CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: 40, longitude: 13),
                    altitude: 4, horizontalAccuracy: 1, verticalAccuracy: 2, timestamp: Date()
                ),
                CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: 39, longitude: 15),
                    altitude: 1300, horizontalAccuracy: 300, verticalAccuracy: 1, timestamp: Date()
                )
            ]),
            .didUpdateLocations([
                CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: 10, longitude: 20),
                    altitude: 10, horizontalAccuracy: 30, verticalAccuracy: 20, timestamp: Date()
                )
            ])
        ]
        #else
        let sequence: [Tasks.ContinuousUpdateLocation.StreamEvent] = [
            .didUpdateLocations([
                CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: 41.915001, longitude: 12.577772),
                    altitude: 100, horizontalAccuracy: 50, verticalAccuracy: 20, timestamp: Date()
                ),
                CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: 41.8, longitude: 12.7),
                    altitude: 97, horizontalAccuracy: 30, verticalAccuracy: 10, timestamp: Date()
                )
            ]),
            .didFailed(LocationErrors.notAuthorized),
            .didUpdateLocations([
                CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: 40, longitude: 13),
                    altitude: 4, horizontalAccuracy: 1, verticalAccuracy: 2, timestamp: Date()
                ),
                CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: 39, longitude: 15),
                    altitude: 1300, horizontalAccuracy: 300, verticalAccuracy: 1, timestamp: Date()
                )
            ]),
            .didUpdateLocations([
                CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: 10, longitude: 20),
                    altitude: 10, horizontalAccuracy: 30, verticalAccuracy: 20, timestamp: Date()
                )
            ])
        ]
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            for event in sequence {
                self.mockLocationManager.updateLocations(event: event)
                usleep(10) // 0.1s
            }
        })
        
        return sequence
    }
    
    
    private func simulateAccuracyAuthorizationChanges() -> [CLAccuracyAuthorization] {
        let sequence : [CLAccuracyAuthorization] = [.fullAccuracy, .fullAccuracy, .fullAccuracy, .reducedAccuracy]
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            for value in sequence {
                self.mockLocationManager.accuracyAuthorization = value
                usleep(10) // 0.1s
            }
        })
        return [.fullAccuracy, .reducedAccuracy]
    }
    
    private func simulateAuthorizationStatusChanges() -> [CLAuthorizationStatus] {
        #if os(macOS)
        let sequence : [CLAuthorizationStatus] = [.notDetermined, .restricted, .denied, .denied, .authorizedAlways]
        #else
        let sequence : [CLAuthorizationStatus] = [.notDetermined, .restricted, .denied, .denied, .authorizedWhenInUse, .authorizedAlways]
        #endif
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            for value in sequence {
                self.mockLocationManager.authorizationStatus = value
                usleep(10) // 0.1s
            }
        })
        
        #if os(macOS)
        return [.restricted, .denied, .authorizedAlways]
        #else
        return [.restricted, .denied, .authorizedWhenInUse, .authorizedAlways]
        #endif
    }
    
    private func simulateLocationServicesChanges() -> [Bool] {
        let sequence = [false, true, false, true, true, true, false] // only real changes are detected
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            for value in sequence {
                self.mockLocationManager.isLocationServicesEnabled = value
                usleep(10)
            }
        })
        return [false, true, false, true, false]
    }
    
}
