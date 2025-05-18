//
//  MQTTclient.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 02/05/2025.
//

public enum MQTTclientError: Error {
	case operationFailed(code: esp_err_t)
}

public class MQTTclient {
	
	private var clientHandle: OpaquePointer?
	
	static func installGlobalCAstore(rootCAcertificate: String) throws(MQTTclientError) {
		
		var caCertBytes = Array(rootCAcertificate.utf8)
		caCertBytes.append(0) // Manually null-terminate
		
		let initResult = esp_tls_init_global_ca_store()
		guard initResult == ESP_OK else {
			throw MQTTclientError.operationFailed(code: initResult)
		}
		
		let setResult = caCertBytes.withUnsafeBufferPointer { buffer in
			esp_tls_set_global_ca_store(buffer.baseAddress, UInt32(buffer.count))
		}
		
		if setResult != ESP_OK {
			throw MQTTclientError.operationFailed(code: setResult)
		}
	}
	
	public init(connectTo hostName: String,
				port: UInt32 = 8883,
				userName: String,
				password: String,
				clientId: String = "ESP32client") throws(MQTTclientError) {
		
		// Hold strong references to null-terminated UTF8 C strings
		let cHostName = strdup(hostName)
		let cUserName = strdup(userName)
		let cPassword = strdup(password)
		let cClientId = strdup(clientId)
		var config = make_mqtt_config(cHostName, port, cClientId, cUserName, cPassword)
		
		let clientHandle = esp_mqtt_client_init(&config)
		guard clientHandle != nil else {
			throw MQTTclientError.operationFailed(code: ESP_FAIL)
		}
		print ("✅ MQTT client initialized")

		let startResult = esp_mqtt_client_start(clientHandle)
		guard startResult == ESP_OK else {
			throw MQTTclientError.operationFailed(code: startResult)
		}
		print ("✅ MQTT client started")
		
		self.clientHandle = clientHandle
	}
	
	
	public func publish(topic: String, message: String, qos: Int32 = 1, retain: Int32 = 0) throws(MQTTclientError) {
		
		guard let clientHandle = self.clientHandle else {
			throw MQTTclientError.operationFailed(code: ESP_FAIL)
		}
		
		let result = topic.withCString { topicCString in
			message.withCString { messageCString in
				let length = Int32(strlen(messageCString))
				return esp_mqtt_client_publish(clientHandle, topicCString, messageCString, length, qos, retain)
			}
		}
		
		if result < 0 {
			throw MQTTclientError.operationFailed(code: result)
		}
	}
	
	public func subscribe(topic: String, qos: Int32 = 1) throws(MQTTclientError) {
		guard let clientHandle = self.clientHandle else {
			throw MQTTclientError.operationFailed(code: ESP_FAIL)
		}
		
		let result = topic.withCString { topicCString in
			esp_mqtt_client_subscribe_single(clientHandle, topicCString, qos)
		}
		
		if result < 0 {
			throw MQTTclientError.operationFailed(code: result)
		}
	}
	
	public func unsubscribe(topic: String) throws(MQTTclientError) {
		guard let clientHandle = self.clientHandle else {
			throw MQTTclientError.operationFailed(code: ESP_FAIL)
		}
		
		let result = topic.withCString { topicCString in
			esp_mqtt_client_unsubscribe(clientHandle, topicCString)
		}
		
		if result < 0 {
			throw MQTTclientError.operationFailed(code: result)
		}
	}
	
}
