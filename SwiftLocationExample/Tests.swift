import UIKit
import XCTest
import MapKit
import CoreLocation

class ReverseGeocoderTestClass: XCTestCase {
	var initialCoordinates: CLLocationCoordinate2D?
	
	override func setUp() {
		super.setUp()
		initialCoordinates = CLLocationCoordinate2DMake(41.890198, 12.492204)
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testAll() {
		testAppleReverseCoordinates()
		testGoogleReverseCoordinates()
		testAppleReverseAddress()
		testGoogleReverseAddress()
	}
	
	func testAppleReverseCoordinates() {
		sub_testReverseGeocodingCoordinates(Service.Apple)
	}
	
	func testGoogleReverseCoordinates() {
		sub_testReverseGeocodingCoordinates(Service.GoogleMaps)
	}
	
	func testAppleReverseAddress() {
		sub_testReverseAddress(Service.Apple)
	}
	
	func testGoogleReverseAddress() {
		sub_testReverseAddress(Service.GoogleMaps)
	}
	
	private func sub_testReverseAddress(service: Service!) {
		var placeFound: CLPlacemark?
		
		let exp = expectationWithDescription("reverse_geocoder_address")
		SwiftLocation.shared.reverseAddress(service, address: "Piazza Del Colosseo 58, Roma", region: nil, onSuccess: { (place) -> Void in
			placeFound = place
			XCTAssertNotNil(placeFound, "Found place cannot be nil")
			XCTAssertEqualWithAccuracy(placeFound!.location!.coordinate.latitude, 41.890, accuracy: 0.02,"Unexpected latitute found")
			XCTAssertEqualWithAccuracy(placeFound!.location!.coordinate.longitude, 12.492, accuracy: 0.02,"Unexpected longitude found")
			exp.fulfill()
			}) { (error) -> Void in
				XCTFail("An error has occurred: \(error?.localizedDescription)")
				exp.fulfill()
		}
		
		waitForExpectationsWithTimeout(20, handler: { (error) -> Void in
			if error == nil {
				print("Test passed: \(placeFound?.description)")
			} else {
				print("Test not passed: \(error?.localizedDescription)")
			}
		})
	}
	
	private func sub_testReverseGeocodingCoordinates(service: Service!) {
		var placeFound: CLPlacemark?
		
		print("Testing with service: \(service)")
		
		let exp = expectationWithDescription("reverse_geocoder_coordinates")
		SwiftLocation.shared.reverseCoordinates(service, coordinates: initialCoordinates, onSuccess: { (place) -> Void in
			placeFound = place
			XCTAssertNotNil(placeFound, "Found place cannot be nil")
			XCTAssertEqualWithAccuracy(placeFound!.location!.coordinate.latitude, 41.890, accuracy: 0.02,"Unexpected latitute found")
			XCTAssertEqualWithAccuracy(placeFound!.location!.coordinate.longitude, 12.492, accuracy: 0.02,"Unexpected longitude found")
			exp.fulfill()
			}) { (error) -> Void in
				XCTFail("An error has occurred: \(error?.localizedDescription)")
				exp.fulfill()
		}
		
		waitForExpectationsWithTimeout(20, handler: { (error) -> Void in
			if error == nil {
				print("Test passed: \(placeFound?.description)")
			} else {
				print("Test not passed: \(error?.localizedDescription)")
			}
		})
		
	}
	
}
