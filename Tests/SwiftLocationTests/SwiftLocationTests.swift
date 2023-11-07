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
        let expectedValues = simulateAccuracyAuthorizationCnanges()
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
    
    /// Test request for permission with failure in plist configuration
    func testRequestPermissionsFailureWithPlistConfiguration() async throws {
        mockLocationManager.onValidatePlistConfiguration = { permission in
            switch permission {
            case .always:
                Errors.plistNotConfigured
            case .whenInUse:
                nil
            }
        }
        
        do {
            let newStatus = try await location.requestPermission(.always)
            XCTFail("Permission should fail due to missing plist while it returned \(newStatus)")
        } catch { }
    }
    
    func testRequestPermissionWhenInUseSuccess() async throws {
        do {
            let expectedStatus = CLAuthorizationStatus.restricted
            mockLocationManager.onRequestWhenInUseAuthorization = {
                expectedStatus
            }
            let newStatus = try await location.requestPermission(.whenInUse)
            XCTAssertEqual(expectedStatus, newStatus)
        } catch {
            XCTFail("Request should not fail: \(error.localizedDescription)")
        }
    }
        
    func testRequestAlwaysSuccess() async throws {
        do {
            let expectedStatus = CLAuthorizationStatus.authorizedAlways
            mockLocationManager.onRequestWhenInUseAuthorization = {
                expectedStatus
            }
            
            let newStatus = try await location.requestPermission(.always)
            XCTAssertEqual(expectedStatus, newStatus)
        } catch {
            XCTFail("Request should not fail: \(error.localizedDescription)")
        }
    }
    
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
        mockLocationManager.onRequestWhenInUseAuthorization = { .authorizedWhenInUse }
        let newStatus = try await location.requestPermission(.whenInUse)
        XCTAssertEqual(newStatus, .authorizedWhenInUse)
        
        await fulfillment(of: [exp])
    }
    
    // MARK: - Private Functions
    
    private func simulateAccuracyAuthorizationCnanges() -> [CLAccuracyAuthorization] {
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
        let sequence : [CLAuthorizationStatus] = [.notDetermined, .restricted, .denied, .denied, .authorizedWhenInUse, .authorizedAlways]
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
            for value in sequence {
                self.mockLocationManager.authorizationStatus = value
                usleep(10) // 0.1s
            }
        })
        return [.restricted, .denied, .authorizedWhenInUse, .authorizedAlways]
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
