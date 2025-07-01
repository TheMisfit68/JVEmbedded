// HTTP.swift
//
// A blend of human creativity by TheMisfit68 and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

public class HTTPClient {
	private var clientConfig: esp_http_client_config_t!

	let baseURL: String
	let username: String?
	let password: String?
	public weak var delegate: HTTPClientDelegate?
		
	// C-callback that will be used to pass events onto the Swift message handler
	private static let cGetCallback: @convention(c) (UnsafePointer<CChar>?, Int) -> Void = { data, len in
		guard let data else { return }
		let buffer = UnsafeBufferPointer(start: UnsafeRawPointer(data).assumingMemoryBound(to: UInt8.self), count: len)
		let string = String(decoding: buffer, as: UTF8.self)
	}
	
	public init(baseURL: String, username: String? = nil, password: String? = nil) {
		self.baseURL = baseURL
		self.username = username
		self.password = password
		HTTPClient.sharedInstance = self
	}
	
	public func get(path: String) throws(HTTPError) {
		let fullURL = baseURL + path
		var httpContext = HTTP_ctx(date: nil, size: 0, status: 0, data: nil)
		fullURL.withCString { urlCStr in
			if let username = username, let password = password {
				username.withCString { userCStr in
					password.withCString { passCStr in
						_ = http_get_shim(&httpContext, urlCStr, userCStr, passCStr, nil)
					}
				}
			} else {
				_ = http_get_shim(&httpContext, urlCStr, nil, nil, nil)
			}
		}
	}
	
	// The actual Swift event handler that will be called by the C-callback and
	// passes the event to the delegate
	func handleEvent(_ event: esp_mqtt_event_t) {
		
		delegate?.httpClient(sharedInstance, didReceiveData: string)
		
		
//		switch event.event_id {
//			case MQTT_EVENT_CONNECTED:
//				
//				self.isConnected = true
//				self.delegate?.mqttClientDidConnect(self)
//				
//				// Flush pending subscriptions
//				for (topic, qos) in pendingSubscriptions {
//					try? subscribe(topic: topic, qos: qos)
//				}
//				pendingSubscriptions.removeAll()
//				
//			case MQTT_EVENT_DISCONNECTED:
//				
//				self.isConnected = false
//				self.delegate?.mqttClient(self, didDisconnectWithError: .operationFailed)
//				
//			case MQTT_EVENT_DATA:
//				
//				if let topicCString = event.topic, let messagePtr = event.data {
//					let topic = String(cString: topicCString)
//					
//					// Convert Int8* to UInt8* for proper UTF-8 decoding
//					let uint8Ptr = UnsafeRawPointer(messagePtr).assumingMemoryBound(to: UInt8.self)
//					let buffer = UnsafeBufferPointer(start: uint8Ptr, count: Int(event.data_len))
//					let messageString = String(decoding: buffer, as: UTF8.self)
//					
//					delegate?.mqttClient(self, didReceiveMessage: messageString, onTopic: topic)
//				}
//				
//			default:
//				break
//		}
	}
	
}

public protocol HTTPClientDelegate: AnyObject {
	func httpClient(_ client: HTTPClient, didReceiveData data: String)
}
