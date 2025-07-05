//
//  HTTP.swift
//
//  A blend of human creativity by TheMisfit68 and
//  AI assistance from ChatGPT.
//  Crafting the future, one line of Swift at a time.
//  Copyright © 2023 Jan Verrept. All rights reserved.
//

public class HTTPClient {
	let baseURL: String
	private var clientConfig: esp_http_client_config_t!
	var clientHandle: OpaquePointer?
	public var delegate: HTTPClientDelegate?
	
	// C-callback that will be used to pass events onto the Swift message handler
	private static let cCallback: @convention(c) (UnsafeMutablePointer<esp_http_client_event_t>?) -> esp_err_t = { eventPtr in
		guard let eventPtr = eventPtr else { return ESP_FAIL }
		let event = eventPtr.pointee
		
		// Recast user_data back into Swift instance
		if let context = event.user_data {
			let client = Unmanaged<HTTPClient>.fromOpaque(context).takeUnretainedValue()
			client.handleEvent(event)
			return ESP_OK
		} else {
			return ESP_FAIL
		}
	}
	
	public init(baseURL: String, userName: String? = nil, password: String? = nil) {
		self.baseURL = baseURL
		
		let cURL = strdup(baseURL)
		let cUserName = strdup(userName)
		let cPassword = strdup(password)

		defer {
			free(cURL)
			free(cUserName)
			free(cPassword)
		}
		
		var config = make_http_config(cURL, cUserName, cPassword, HTTPClient.cCallback)
		let unmanagedSelf = Unmanaged.passUnretained(self).toOpaque()
		config.user_data = unmanagedSelf
		
		self.clientConfig = config
		self.clientHandle = esp_http_client_init(&self.clientConfig)
	}

	
	// Swift-side handler that maps C event to delegate call
	func handleEvent(_ event: esp_http_client_event_t) {
		switch event.event_id {
			case HTTP_EVENT_ON_DATA:
				if let data = event.data, event.data_len > 0 {
					let buffer = UnsafeBufferPointer(start: UnsafeRawPointer(data).assumingMemoryBound(to: UInt8.self), count: Int(event.data_len))
					let message = String(decoding: buffer, as: UTF8.self)
					delegate?.httpClient(self, didReceiveData: message)
				}
				
			case HTTP_EVENT_ON_CONNECTED:
				delegate?.httpClientDidConnect(self)
				
			case HTTP_EVENT_HEADER_SENT:
				delegate?.httpClientDidSendHeader(self)
				
			case HTTP_EVENT_ON_HEADER:
				if let key = event.header_key, let value = event.header_value {
					let keyStr = String(cString: key)
					let valueStr = String(cString: value)
					delegate?.httpClient(self, didReceiveHeader: keyStr, value: valueStr)
				}
				
			case HTTP_EVENT_ON_FINISH:
				delegate?.httpClientDidFinish(self)
				
			case HTTP_EVENT_DISCONNECTED:
				delegate?.httpClientDidDisconnect(self)
				
			default:
				break
		}
	}
}

public protocol HTTPClientDelegate: AnyObject {
	func httpClientDidConnect(_ client: HTTPClient)
	func httpClientDidSendHeader(_ client: HTTPClient)
	func httpClient(_ client: HTTPClient, didReceiveHeader key: String, value: String)
	func httpClient(_ client: HTTPClient, didReceiveData data: String)
	func httpClientDidFinish(_ client: HTTPClient)
	func httpClientDidDisconnect(_ client: HTTPClient)
}
