//
//  SwiftLocation - Efficient Location Tracking for iOS
//
//  Created by Daniele Margutti
//   - Web: https://www.danielemargutti.com
//   - Twitter: https://twitter.com/danielemargutti
//   - Mail: hello@danielemargutti.com
//
//  Copyright © 2019 Daniele Margutti. Licensed under MIT License.

import Foundation

public class JSONOperation {
    
    // MARK: - Public Typealiases -
    
    public typealias ResponseData = Result<Any,LocationManager.ErrorReason>
    public typealias Callback = ((ResponseData) -> Void)
    
    // MARK: - Private Properties -
    
    /// Task of the operation
    private var task: URLSessionDataTask?
    
    /// Callback to call at the end
    private var callback: Callback?
    
    /// Request to make.
    private var request: URLRequest
    
    // MARK: - Public Methods -
    
    /// Create a new request.
    ///
    /// - Parameters:
    ///   - url: url to download.
    ///   - timeout: timeout of the request, `10` seconds if not explicitly specified.
    ///   - cachePolicy: cache policy, if not specified `reloadIgnoringLocalAndRemoteCacheData`.
    public init(_ url: URL, timeout: TimeInterval?, cachePolicy: NSURLRequest.CachePolicy? = nil) {
        self.request = URLRequest(url: url, cachePolicy: (cachePolicy ?? .reloadIgnoringLocalAndRemoteCacheData), timeoutInterval: timeout ?? 10.0)
    }
    
    /// Start a request. Any pending request from the same class will be discarded.
    ///
    /// - Parameter callback: callback to call as response to the request.
    public func start(_ callback: @escaping Callback) {
        self.task?.cancel()
        self.callback = callback
        self.task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            self?.onReceiveResponse(data, response, error)
        })
        self.task?.resume()
    }
    
    /// Stop task without dispatching the event to callback.
    public func stop() {
        self.callback = nil
        self.task?.cancel()
    }
    
    // MARK: - Private Methods -
    
    private func onReceiveResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
        if let error = error {
            callback?(.failure(.generic(error.localizedDescription)))
            return
        }
        
        guard let data = data else {
            callback?(.failure(.noData(request.url)))
            return
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            callback?(.success(json))
        }
    }
}
