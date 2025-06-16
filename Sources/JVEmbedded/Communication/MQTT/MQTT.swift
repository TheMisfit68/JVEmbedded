//
//  MQTTClient.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 02/05/2025.
//

public class MQTTClient {
	
	private var clientConfig: esp_mqtt_client_config_t!
	private var clientHandle: OpaquePointer?
	public var isConnected: Bool = false
	private var pendingSubscriptions:[(topic: String, qos: Int32)] = []
	public var delegate: MQTTClientDelegate?

	// C-callback that will be used to pass events onto the Swift message handler
	private static let cCallback: esp_event_handler_t = { context, eventBase, eventId, eventData in
		guard let context else { return }
		guard let eventData else { return }
		
		let mqttClient = Unmanaged<MQTTClient>.fromOpaque(context).takeUnretainedValue()
		
		// Reinterpret eventData as `esp_mqtt_event_t`
		let event = eventData.assumingMemoryBound(to: esp_mqtt_event_t.self).pointee
		
		mqttClient.handleEvent(event)
	}
	
	static func installGlobalCAstore(rootCAcertificate: String) throws(MQTTerror) {
		var caCertBytes = Array(rootCAcertificate.utf8)
		caCertBytes.append(0) // Manually null-terminate
		
		try MQTTerror.check(esp_tls_init_global_ca_store())
		
		let setResult = caCertBytes.withUnsafeBufferPointer { buffer in
			esp_tls_set_global_ca_store(buffer.baseAddress, UInt32(buffer.count))
		}
		
		try MQTTerror.check(setResult)
	}
	
	public init(hostName: String,
				port: UInt32 = 8883,
				userName: String,
				password: String,
				clientId: String = "ESP32client") throws(MQTTerror) {
		
		
		// Hold strong references to null-terminated UTF8 C strings
		let cHostName = strdup(hostName)
		let cUserName = strdup(userName)
		let cPassword = strdup(password)
		let cClientId = strdup(clientId)
		defer {
			free(cHostName)
			free(cUserName)
			free(cPassword)
			free(cClientId)
		}
		
		var config = make_mqtt_config(cHostName, port, cClientId, cUserName, cPassword)
		self.clientConfig = config
		self.clientHandle = esp_mqtt_client_init(&self.clientConfig)
		
		// Register the C-callback/event handler
		let unmanagedSelf = Unmanaged.passUnretained(self).toOpaque()
		let registrationResult = esp_mqtt_client_register_event(
			self.clientHandle,
			esp_mqtt_event_id_t(ESP_EVENT_ANY_ID),
			MQTTClient.cCallback,
			unmanagedSelf
		)
		
		try MQTTerror.check(registrationResult)
		
#if DEBUG
		print("✅ MQTT client initialized with event handler")
#endif
		
	}
	
	deinit {
		if let client = clientHandle {
			esp_mqtt_client_destroy(client)
		}
	}
	
	public func connect() throws(MQTTerror) {
		
		guard clientHandle != nil else {
			throw MQTTerror.operationFailed
		}
		let startResult = esp_mqtt_client_start(clientHandle)
		guard startResult == ESP_OK else {
			throw MQTTerror.operationFailed
		}
#if DEBUG
		print ("✅ MQTT client started")
#endif
	}
	
	
	public func publish(topic: String, message: String, qos: Int32 = 1, retain: Int32 = 0) throws(MQTTerror) {
		
		guard let clientHandle = self.clientHandle else {
			throw MQTTerror.operationFailed
		}
		
		let result = topic.withCString { topicCString in
			message.withCString { messageCString in
				let length = Int32(strlen(messageCString))
				return esp_mqtt_client_publish(clientHandle, topicCString, messageCString, length, qos, retain)
			}
		}
		
		if result < 0 {
			throw MQTTerror.operationFailed
		}
	}
	
	public func subscribe(topic: String, qos: Int32 = 1) throws(MQTTerror) {
		
		if !isConnected {
			pendingSubscriptions.append((topic, qos))
			return
		}
		
		guard let clientHandle = self.clientHandle else { throw MQTTerror.operationFailed }
		
		let result = topic.withCString { topicCString in
			esp_mqtt_client_subscribe_single(clientHandle, topicCString, qos)
		}
		
		if result < 0 { throw MQTTerror.operationFailed }
		
	}
	
	public func unsubscribe(topic: String) throws(MQTTerror) {
		guard let clientHandle = self.clientHandle else {
			throw MQTTerror.operationFailed
		}
		
		let result = topic.withCString { topicCString in
			esp_mqtt_client_unsubscribe(clientHandle, topicCString)
		}
		
		if result < 0 {
			throw MQTTerror.operationFailed
		}
	}
	
	// The actual Swift event handler that will be called by the C-callback and
	// passes the event to the delegate
	func handleEvent(_ event: esp_mqtt_event_t) {
		switch event.event_id {
			case MQTT_EVENT_CONNECTED:
				
				self.isConnected = true
				self.delegate?.mqttClientDidConnect(self)
				
				// Flush pending subscriptions
				for (topic, qos) in pendingSubscriptions {
					try? subscribe(topic: topic, qos: qos)
				}
				pendingSubscriptions.removeAll()
				
			case MQTT_EVENT_DISCONNECTED:
				
				self.isConnected = false
				self.delegate?.mqttClient(self, didDisconnectWithError: .operationFailed)
				
			case MQTT_EVENT_DATA:
				
				if let topicCString = event.topic, let messagePtr = event.data {
					let topic = String(cString: topicCString)
					
					// Convert Int8* to UInt8* for proper UTF-8 decoding
					let uint8Ptr = UnsafeRawPointer(messagePtr).assumingMemoryBound(to: UInt8.self)
					let buffer = UnsafeBufferPointer(start: uint8Ptr, count: Int(event.data_len))
					let messageString = String(decoding: buffer, as: UTF8.self)
					
					delegate?.mqttClient(self, didReceiveMessage: messageString, onTopic: topic)
				}
				
			default:
				break
		}
	}
}


public protocol MQTTClientDelegate: AnyObject {
	func mqttClientDidConnect(_ client: MQTTClient)
	func mqttClient(_ client: MQTTClient, didDisconnectWithError error: MQTTerror?)
	func mqttClient(_ client: MQTTClient, didReceiveMessage message: String, onTopic topic: String)
}
