// FileManager.swift
//
// A blend of human creativity by TheMisfit68  and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

public class FileManager {
	
	public static let shared = FileManager()
	
	private let basePath: String
	private let partitionLabel: String?
	
	private init(basePath: String = "/Storage", partitionLabel: String? = nil) {
		self.basePath = basePath
		self.partitionLabel = partitionLabel
		
		self.mountPartition()
	}
	
	/// Mount the SPIFFS partition
	@discardableResult
	public func mountPartition() -> Bool {
		var mounted = false
		basePath.withCString { basePathCStr in
			if let partitionLabel = self.partitionLabel {
				partitionLabel.withCString { labelCStr in
					var conf = esp_vfs_spiffs_conf_t(
						base_path: basePathCStr,
						partition_label: labelCStr,
						max_files: 5,
						format_if_mount_failed: false
					)
					let result = esp_vfs_spiffs_register(&conf)
					mounted = (result == ESP_OK)
					if mounted {
						print("✅ 🚀 [FileManager] Successfully mounted SPIFFS at '\(basePath)'")
					} else {
						var errBuffer = [CChar](repeating: 0, count: 64)
						let errString = esp_err_to_name_r(result, &errBuffer, errBuffer.count)
						print("❌ [FileManager] Failed to mount SPIFFS: \(String(cString: errString!)) ❗️")
					}
				}
			} else {
				var conf = esp_vfs_spiffs_conf_t(
					base_path: basePathCStr,
					partition_label: nil,
					max_files: 5,
					format_if_mount_failed: false
				)
				let result = esp_vfs_spiffs_register(&conf)
				mounted = (result == ESP_OK)
				if mounted {
					print("✅ 🚀 [FileManager] Successfully mounted SPIFFS at '\(basePath)'")
				} else {
					var errBuffer = [CChar](repeating: 0, count: 64)
					let errString = esp_err_to_name_r(result, &errBuffer, errBuffer.count)
					print("❌ [FileManager] Failed to mount SPIFFS: \(String(cString: errString!)) ❗️")
				}
			}
		}
		return mounted
	}
	
	public func readFile(named fileName: String) -> String? {
		
		// Compose full path in Swift
		let fullPath = "\(basePath)/\(fileName)"
		
		return fullPath.withCString { fullPathCStr in
			// Open the file using the C string
			guard let file = fopen(fullPathCStr, "r") else {
				print("❌ 📂 [FileManager] Failed to open file: '\(fileName)'")
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
			print("✅ 📄 [FileManager] Successfully read file: '\(fileName)'")
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
