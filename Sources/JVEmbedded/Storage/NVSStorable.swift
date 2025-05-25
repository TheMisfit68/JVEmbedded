//
//  NVSStorable.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 24/05/2025.
//

public protocol NVSStorable {
	static func read(from handle: nvs_handle_t, key: String) throws(StorageError) -> Self
	func write(to handle: nvs_handle_t, key: String) throws(StorageError)
}

extension String: NVSStorable {
	public static func read(from handle: nvs_handle_t, key: String) throws(StorageError) -> String {
		var length: Int = 0
		// First call to get the required length
		var err = nvs_get_str(handle, key, nil, &length)
		try StorageError.check(err, "Getting string length for key \(key)")
		
		let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: length)
		defer { buffer.deallocate() }
		
		err = nvs_get_str(handle, key, buffer, &length)
		try StorageError.check(err, "Reading string value for key \(key)")
		
		guard let str = String(validatingUTF8: buffer) else {
			throw StorageError.readError
		}
		return str
	}
	
	public func write(to handle: nvs_handle_t, key: String) throws(StorageError) {
		var err = ESP_OK
		try withCString { cString in
			err = nvs_set_str(handle, key, cString)
		}
		try StorageError.check(err, "Writing string value for key \(key)")
	}
}

extension Int32: NVSStorable {
	
	public static func read(from handle: nvs_handle_t, key: String) throws(StorageError) -> Int32 {
		let keyCString = key.utf8CString
		guard let keyPtr = keyCString.withUnsafeBufferPointer({ $0.baseAddress }) else {
			throw StorageError.readError
		}
		
		var value: Int32 = 0
		let err = nvs_get_i32(handle, keyPtr, &value)
		try StorageError.check(err, "Reading Int32 for key \(key) failed")
		return value
	}
	
	public func write(to handle: nvs_handle_t, key: String) throws(StorageError) {
		let keyCString = key.utf8CString
		let err = keyCString.withUnsafeBufferPointer { keyPtr in
			nvs_set_i32(handle, keyPtr.baseAddress, self)
		}
		try StorageError.check(err, "Writing Int32 for key \(key) failed")
	}
	
}
