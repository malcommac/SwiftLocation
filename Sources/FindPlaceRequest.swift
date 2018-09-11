//
//  FindPlaceRequest.swift
//  SwiftLocation
//
//  Created by danielemargutti on 28/10/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation

public typealias FindPlaceRequest_Success = (([PlaceMatch]) -> (Void))
public typealias FindPlaceRequest_Failure = ((LocationError) -> (Void))

/// Public protocol for place find request
public class FindPlaceRequest: Equatable {
	
	/// Success handler
	var success: FindPlaceRequest_Success?
	
	/// Failure handler
	var failure: FindPlaceRequest_Failure?
	
	/// Timeout interval
	var timeout: TimeInterval
	
	/// Execute operation
	func execute() {}
	
	/// Cancel current execution (if any)
	func cancel() {}
	
	private func complete() {}
	
	/// Unique identifier of the request
	var identifier: String
	
	internal init(timeout: TimeInterval? = nil) {
		self.identifier = UUID().uuidString
		self.timeout = timeout ?? 10
	}
	
	public static func == (lhs: FindPlaceRequest, rhs: FindPlaceRequest) -> Bool {
		return lhs.identifier == rhs.identifier
	}
}

/// Find Place with Google
public class FindPlaceRequest_Google: FindPlaceRequest {
	
	/// session task
	private var task: JSONOperation? = nil

	/// Input to search
	public private(set) var input: String

    /// Language in which the results are displayed
    public private(set) var language: FindPlaceRequest_Google_Language?
	
	/// Init new find place operation
	///
	/// - Parameters:
	///   - operation: operation to execute
	///   - timeout: timeout, `nil` uses default timeout of 10 seconds
    public init(input: String, timeout: TimeInterval? = nil, language: FindPlaceRequest_Google_Language? = nil) {
		self.input = input
        self.language = language ?? FindPlaceRequest_Google_Language.english
		super.init(timeout: timeout)
	}
	
	public override func execute() {
		guard let APIKey = Locator.api.googleAPIKey else {
			self.failure?(LocationError.missingAPIKey(forService: "google"))
			return
		}
        let lang = language?.rawValue ?? "en"
		let url = URL(string: "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(input.urlEncoded)&language=\(lang)&key=\(APIKey)")!
		self.task = JSONOperation(url, timeout: self.timeout)
		self.task?.onFailure = { [weak self] err in
            guard let `self` = self else { return }
			self.failure?(err)
			self.complete()
		}
		self.task?.onSuccess = { [weak self] json in
			defer { self?.complete() }
			
			guard let `self` = self else { return }
			guard let json = json as? [String:Any] else {
				self.failure?(LocationError.dataParserError)
				return
			}
			// api related error
			let status = json["status"] as? String
			if status != "OK",
				let error_msg = json["error_message"] as? String, !error_msg.isEmpty {
				self.failure?(LocationError.other(error_msg))
				return
			}
			
			let places = PlaceMatch.load(list: json["predictions"] as? [Any])
			self.success?(places)
		}
		self.task?.execute()
	}
	
	public override func cancel() {
		self.task?.cancel()
		self.complete()
	}
	
	private func complete() {
		Locator.autocompleteRequest.remove(self)
	}
	
}

/// Google Autocomplete supported languages
///
/// - arabic: Arabic
/// - bulgarian: Bulgarian
/// - bengali: Bengali
/// - catalan: Catalan
/// - czech: Czech
/// - danish: Danish
/// - dutch: Dutch
/// - german: German
/// - greek: Greek
/// - english: English
/// - english_AU: English (Australia)
/// - english_GB: English (Great Britain)
/// - spanish: Spanish
/// - basque: Basque
/// - chinese_simplified: Chinese (Simplified)
/// - chinese_traditional: Chinese (Traditional)
/// - farsi: Farsi
/// - finnish: Finnish
/// - filipino: Filipino
/// - french: French
/// - galician: Galician
/// - gujarati: Gujarati
/// - hindi: Hindi
/// - croatian: Croatian
/// - hungarian: Hungarian
/// - indonesian: Indonesian
/// - italian: Italian
/// - hebrew: Hebrew
/// - japanese: Japanese
/// - kannada: Kannada
/// - korean: Korean
/// - lithuanian: Lithuanian
/// - latvian: Latvian
/// - malayalam: Malayalam
/// - marathi: Marathi
/// - norwegian: Norwegian
/// - polish: Polish
/// - portuguese: Portuguese
/// - portuguese_BR: Portuguese (Brasil)
/// - portuguese_PT: portuguese (Portugal)
/// - romanian: Romanian
/// - russian: Russian
/// - slovak: Slovak
/// - slovenian: Slovenian
/// - serbian: Serbian
/// - swedish: Swedish
/// - tamil: Tamil
/// - telugu: Telugu
/// - thai: Hhai
/// - tagalog: Tagalog
/// - turkish: Turkish
/// - ukrainian: Ukrainian
/// - vietnamese: Vietnamese
public enum FindPlaceRequest_Google_Language: String {
    case arabic = "ar"
    case bulgarian = "bg"    
    case bengali = "bn"
    case catalan    = "ca"
    case czech = "cs"
    case danish = "da"
    case dutch = "nl"
    case german = "de"
    case greek = "el"    
    case english = "en"    
    case english_AU = "en-AU"
    case english_GB = "en-GB"
    case spanish = "es"
    case basque = "eu"    
    case chinese_simplified = "zh-CN"
    case chinese_traditional = "zh-TW"
    case farsi = "fa"
    case finnish = "fi"
    case filipino = "fil"
    case french = "fr"
    case galician    = "gl"
    case gujarati = "gu"
    case hindi = "hi"
    case croatian = "hr"
    case hungarian = "hu"
    case indonesian = "id"
    case italian = "it"
    case hebrew = "iw"
    case japanese = "ja"
    case kannada = "kn"
    case korean = "ko"
    case lithuanian = "lt"
    case latvian = "lv"
    case malayalam = "ml"
    case marathi = "mr"
    case norwegian = "no"
    case polish = "pl"
    case portuguese = "pt"
    case portuguese_BR = "pt-BR"
    case portuguese_PT = "pt-PT"
    case romanian = "ro"
    case russian = "ru"
    case slovak = "sk"
    case slovenian = "sl"
    case serbian = "sr"
    case swedish = "sv"
    case tamil = "ta"
    case telugu = "te"
    case thai = "th"
    case tagalog = "tl"
    case turkish = "tr"
    case ukrainian = "uk"
    case vietnamese = "vi"
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

	public init?(_ json: [String: Any]?) {
		guard let json = json else { return nil }
		guard let place = json["place_id"] as? String, !place.isEmpty else {
			return nil
		}
		self.placeID = place
		self.name = json.keyPath("description", default: "")
		self.mainText = json.keyPath("structured_formatting.main_text", default: "")
		self.secondaryText = json.keyPath("structured_formatting.secondary_text", default: "")
		self.types = json.keyPath("types", default: []).compactMap { $0 as? String }
	}
	
	public static func load(list: [Any]?) -> [PlaceMatch] {
		return (list ?? []).compactMap { PlaceMatch($0 as? [String:Any]) }
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
		task.onSuccess = { [weak self] json in
			guard let `self` = self else { return }
			guard 	let json = json as? [String:Any],
					let data: [String:Any] = json.keyPath("result", default: nil),
					let place = Place(googleJSON: data) else {
				onFail?(LocationError.dataParserError)
				return
			}
			self.detail = place
			onSuccess(self.detail!)
		}
		task.onFailure = { err in
			onFail?(err)
		}
		task.execute()
	}

}
