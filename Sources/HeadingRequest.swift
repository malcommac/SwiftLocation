/*
* SwiftLocation
* Easy and Efficent Location Tracker for Swift
*
* Created by:	Daniele Margutti
* Email:		hello@danielemargutti.com
* Web:			http://www.danielemargutti.com
* Twitter:		@danielemargutti
*
* Copyright © 2017 Daniele Margutti
*
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*
*/

import Foundation
import CoreLocation
import MapKit

public class HeadingRequest: Request, Equatable, Hashable {
	
	/// Typealias for accuracy, measured in degree
	public typealias AccuracyDegree = CLLocationDirection
	
	/// Success callback type
	public typealias Success = ((CLHeading) -> (Void))
	
	/// Failure callback type
	public typealias Failure = ((HeadingServiceState) -> (Void))
	
	/// Success callback
	internal var success: Success? = nil
	
	/// Failure callback
	internal var failure: Failure? = nil
	
	/// Unique identifier of the request
	public private(set) var id: RequestID = UUID().uuidString
	
	/// Last valid measured heading
	public internal(set) var heading: CLHeading?
	
	/// Minimum accuracy of values returned
	public private(set) var minimumAccuracy: AccuracyDegree? = nil
	
	/// Minimum interval to receive each event.
	/// If `nil` any interval is received regardeless the timestamp with the last one received.
	public private(set) var minimumInterval: TimeInterval? = nil
	
	/// Initialize a new request with given settings
	///
	/// - Parameters:
	///   - accuracy: required accuracy (in degrees)
	///   - minInterval: minimum interval between headings
	///   - mode: type of operation
	internal init(accuracy: AccuracyDegree?, minInterval: TimeInterval?) {
		self.minimumAccuracy = accuracy
		self.minimumInterval = minInterval
	}
	
	public static func ==(lhs: HeadingRequest, rhs: HeadingRequest) -> Bool {
		return lhs.id == rhs.id
	}
	
	public var hashValue: Int {
		return self.id.hashValue
	}
	
	/// Stop receiving updates for this heading request
	public func stop() {
		Locator.stopRequest(self)
	}
	
	/// Last error
	internal var error: HeadingServiceState? {
		let err = Locator.manager.headingState
		if err == .unavailable { return .unavailable }
		if self.heading == nil { return .invalid }
		return nil
	}
	
	/// Check if received heading is valid
	///
	/// - Parameter heading: valid
	/// - Returns: `true` if minimum conditions for heading are validated
	internal func isValidHeadingForRequest(_ heading: CLHeading?) -> Bool {
		guard let heading = heading else { return false }
		let minElapsed = (self.minimumInterval == nil ? true : fabs(heading.timestamp.timeIntervalSinceNow) >= self.minimumInterval!)
		let minAccuracy = (self.minimumAccuracy == nil ? true : self.minimumAccuracy! >= heading.headingAccuracy)
		return minElapsed && minAccuracy
	}
}
