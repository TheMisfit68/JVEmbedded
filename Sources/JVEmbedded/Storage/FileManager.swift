// FileManager.swift
//
// A blend of human creativity by TheMisfit68  and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

// A simple file manager
// capable of mounting SPIFFS partitions and reading and writing files from it,
// as well as reading and writing key-value pairs using stand nvs partitions.

public class FileManager {
	
	public static let shared = FileManager()
	
	private let partitionName: String
	private let partitionLabel: String?
	
	public init(partitionName: String = "/Storage", partitionLabel: String? = nil) {
		
		// Initialize a SPIFFS partition for file storage
		self.partitionName = partitionName
		self.partitionLabel = partitionLabel
		
		try? self.mountPartition()
		nvs_flash_init() // Also lways initialize/enable te default NVS partition for key-value storage.
	}
	
	// Enable custum NVS partition to use for easy Key-Value storage.
	public func setcustomNVSPartition(_ partitionName: String) throws(StorageError) {
		var error = ESP_OK
		partitionName.withCString { partitionNameCStr in
			error = nvs_flash_init_partition(partitionNameCStr)
		}
		try? StorageError.check(error)
	}
	
	public func mountPartition() throws(StorageError) {
		var conf:esp_vfs_spiffs_conf_t = esp_vfs_spiffs_conf_t()

		partitionName.withCString { partitionNameCStr in
			
			if let partitionLabel = self.partitionLabel {
				
				partitionLabel.withCString { labelCStr in
					conf = esp_vfs_spiffs_conf_t(
						base_path: partitionNameCStr,
						partition_label: labelCStr,
						max_files: 5,
						format_if_mount_failed: false
					)
					
				}
			} else {
				conf = esp_vfs_spiffs_conf_t(
					base_path: partitionNameCStr,
					partition_label: nil,
					max_files: 5,
					format_if_mount_failed: false
				)
			}
		}
		
		try StorageError.check(esp_vfs_spiffs_register(&conf))
		
#if DEBUG
		print("✅ 🚀 [FileManager] Successfully mounted SPIFFS partition '\(partitionName)'")
#endif
	}
	
	public func readFile(named fileName: String) -> String? {
		
		// Compose full path in Swift
		let fullPath = "/\(fileName)"
		
		return fullPath.withCString { fullPathCStr in
			// Open the file using the C string
			guard let file = fopen(fullPathCStr, "r") else {
				print("❌ 📂 [FileManager] Failed to open file at: '\(fullPath)'")
				return nil
			}
			defer { fclose(file) }
			
			// Read contents line by line
			var result = ""
			var buffer = [CChar](repeating: 0, count: 512)
			
			while fgets(&buffer, Int32(buffer.count), file) != nil {
				result += String(cString: buffer)
			}
#if debug
			print("✅ 📄 [FileManager] Successfully read file at: '\(fullPath)'")
#endif
			return result
		}
	}
	
	// TODO: - Make sure this method displays the correct partition info
	/// Prints size info for the SPIFFS partition
	public func printSizeInfo() {
#if debug
		var total: size_t = 0
		var used: size_t = 0
		
		if let partitionLabel = self.partitionLabel {
			partitionLabel.withCString { labelCStr in
				let result = esp_spiffs_info(labelCStr, &total, &used)
				if result == ESP_OK {
					print(
 """
 📊 [FileManager] SPIFFS Partition Info:
  - Total size: \(total) bytes
  - Used size:  \(used) bytes
  - Free size:  \(total - used) bytes
 """
					)
				}
			}
		}
#endif
	}
}


// MARK: - NVS Storage,
// reading and writing keys and values from a defined namespace
extension FileManager {
	
	public func readNVS<T: NVSStorable>(partition:String = "nvs", key: String, namespace: String = "storage") throws(StorageError) -> T {
		var handle: nvs_handle_t = 0
		try StorageError.check(nvs_open_from_partition(partition, namespace, NVS_READONLY, &handle), "Opening NVS namespace \(namespace) failed")
		defer { nvs_close(handle) }
		
		return try T.read(from: handle, key: key)
	}
	
	public func writeNVS<T: NVSStorable>(_ value: T, partition:String = "nvs", key: String, namespace: String = "storage") throws(StorageError) {
		var handle: nvs_handle_t = 0
		try StorageError.check(nvs_open_from_partition(partition, namespace, NVS_READWRITE, &handle), "Opening NVS namespace \(namespace) failed")
		defer { nvs_close(handle) }
		
		try value.write(to: handle, key: key)
		try StorageError.check(nvs_commit(handle), "Committing to NVS failed")
	}
}
