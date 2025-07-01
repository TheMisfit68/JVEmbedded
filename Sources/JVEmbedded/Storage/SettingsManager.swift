//
//  SettingsManager.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 01/06/2025.
//

// A simple settings manager
// capable of reading and writing key-value pairs using nvs partitions.

public final class SettingsManager {
	
	public static let shared = SettingsManager()
	
	init() {
		
		// Initialize NVS Flash
		try? StorageError.check(nvs_flash_init(), "Failed to initialize NVS Flash")
	}
	
	// Enable custom NVS partition to use for easy Key-Value storage.
	public func setcustomNVSPartition(_ partitionName: String) throws(StorageError) {
		var error = ESP_OK
		partitionName.withCString { partitionNameCStr in
			error = nvs_flash_init_partition(partitionNameCStr)
		}
		try? StorageError.check(error)
	}
	
	public func readNVS<T: NVSStorable>(partition:String = "nvs", namespace: String = "storage", key: String) throws(StorageError) -> T {
		var handle: nvs_handle_t = 0
		try StorageError.check(nvs_open_from_partition(partition, namespace, NVS_READONLY, &handle), "Opening NVS namespace \(namespace) failed")
		defer { nvs_close(handle) }
		
		return try T.read(from: handle, key: key)
	}
	
	public func writeNVS<T: NVSStorable>(_ value: T, partition:String = "nvs", namespace: String = "storage", key: String) throws(StorageError) {
		var handle: nvs_handle_t = 0
		try StorageError.check(nvs_open_from_partition(partition, namespace, NVS_READWRITE, &handle), "Opening NVS namespace \(namespace) failed")
		defer { nvs_close(handle) }
		
		try value.write(to: handle, key: key)
		try StorageError.check(nvs_commit(handle), "Committing to NVS failed")
	}
}
