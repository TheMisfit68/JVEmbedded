//
//  MQTTclient.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 02/05/2025.
//

public class MQTTclient {
	
	private var clientHandle: OpaquePointer?
	
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
		
		var config = make_mqtt_config(cHostName, port, cClientId, cUserName, cPassword)
		self.clientHandle = esp_mqtt_client_init(&config)
		
#if DEBUG
		print ("✅ MQTT client initialized")
#endif
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
		guard let clientHandle = self.clientHandle else {
			throw MQTTerror.operationFailed
		}
		
		let result = topic.withCString { topicCString in
			esp_mqtt_client_subscribe_single(clientHandle, topicCString, qos)
		}
		
		if result < 0 {
			throw MQTTerror.operationFailed
		}
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
	
}
