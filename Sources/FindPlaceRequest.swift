//
//  FindPlaceRequest.swift
//  SwiftLocation
//
//  Created by danielemargutti on 28/10/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation
import SwiftyJSON

public typealias FindPlaceRequest_Success = (([PlaceMatch]) -> (Void))
public typealias FindPlaceRequest_Failure = ((LocationError) -> (Void))

/// Public protocol for place find request
public protocol FindPlaceRequest {
	
	/// Success handler
	var success: FindPlaceRequest_Success? { get set }
	
	/// Failure handler
	var failure: FindPlaceRequest_Failure? { get set }
	
	/// Timeout interval
	var timeout: TimeInterval { get set }
	
	/// Execute operation
	func execute()
	
	/// Cancel current execution (if any)
	func cancel()
}

/// Find Place with Google
public class FindPlaceRequest_Google: FindPlaceRequest {
	
	/// session task
	private var task: JSONOperation? = nil
	
	/// Success callback
	public var success: FindPlaceRequest_Success?
	
	/// Failure callback
	public var failure: FindPlaceRequest_Failure?
	
	/// Timeout interval
	public var timeout: TimeInterval
	
	/// Input to search
	public private(set) var input: String
	
	/// Init new find place operation
	///
	/// - Parameters:
	///   - operation: operation to execute
	///   - timeout: timeout, `nil` uses default timeout of 10 seconds
	public init(input: String, timeout: TimeInterval? = nil) {
		self.input = input
		self.timeout = timeout ?? 10
	}
	
	public func execute() {
		guard let APIKey = Locator.api.googleAPIKey else {
			self.failure?(LocationError.missingAPIKey(forService: "google"))
			return
		}
		
		let url = URL(string: "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(input.urlEncoded)&key=\(APIKey)")!
		self.task = JSONOperation(url, timeout: self.timeout)
		self.task?.onFailure = { err in
			self.failure?(err)
		}
		self.task?.onSuccess = { json in
			if json["status"].stringValue != "OK" {
				self.failure?(LocationError.other("Wrong google response"))
				return
			}
			let places = PlaceMatch.load(list: json["predictions"].arrayValue)
			self.success?(places)
		}
		self.task?.execute()
	}
	
	public func cancel() {
		self.task?.cancel()
	}
	
}

/// Identify a single match entry for a place search
public class PlaceMatch {
	
	/// Identifier of the place
	public internal(set) var placeID: String
	
	/// Name of the place
	public internal(set) var name: String
	
	/// Main text of the place
	public internal(set) var mainText: String
	
	/// Secondary text of the place
	public internal(set) var secondaryText: String
	
	/// Place types string (google)
	public internal(set) var types: [String]
	
	/// Place detail cache
	public private(set) var detail: Place?

	public init?(_ json: JSON) {
		guard let placeID = json["place_id"].string else { return nil }
		self.placeID = placeID
		self.name = json["description"].stringValue
		self.mainText = json["structured_formatting"]["main_text"].stringValue
		self.secondaryText = json["structured_formatting"]["secondary_text"].stringValue
		self.types = json["types"].arrayValue.map { $0.stringValue }
	}
	
	public static func load(list: [JSON]) -> [PlaceMatch] {
		return list.flatMap { PlaceMatch($0) }
	}
	
	public func detail(timeout: TimeInterval? = nil,
	                   onSuccess: @escaping ((Place) -> (Void)),
	                   onFail: ((LocationError) -> (Void))? = nil) {
		if let p = self.detail {
			onSuccess(p)
			return
		}
		guard let APIKey = Locator.api.googleAPIKey else {
			onFail?(LocationError.missingAPIKey(forService: "google"))
			return
		}
		let url = URL(string: "https://maps.googleapis.com/maps/api/place/details/json?placeid=\(self.placeID)&key=\(APIKey)")!
		let task = JSONOperation(url, timeout: timeout ?? 10)
		task.onSuccess = { json in
			self.detail = Place(googleJSON: json["result"])
			onSuccess(self.detail!)
		}
		task.onFailure = { err in
			onFail?(err)
		}
		task.execute()
	}

}
