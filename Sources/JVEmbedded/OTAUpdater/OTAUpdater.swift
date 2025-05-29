//
//  OTAUpdater.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 26/05/2025.
//

final class OTAUpdater {
	
	static let shared = OTAUpdater()
	private init() {}
	
	func verifyUpdate() throws(OTAUpdateError) {
		
		let runningPartition = esp_ota_get_running_partition()
		
		var otaState:esp_ota_img_states_t
		let result = esp_ota_get_state_partition(runningPartition, &otaState)
		OTAUpdateError.check( result )
		
		if (ota_state == ESP_OTA_IMG_PENDING_VERIFY) {
			
			// run diagnostics
			let isOK:Bool = diagnostic()
			if isOK {
				#if DEBUG
				print("❌ [OTAUpdater.verifyUpdate] Diagnostics completed successfully! Continuing execution ...")
				#endif
				esp_ota_mark_app_valid_cancel_rollback();
			}else{
				#if DEBUG
				print("❌ [OTAUpdater.verifyUpdate] Diagnostics failed! Start rollback to the previous version ...")
				#endif
				esp_ota_mark_app_invalid_rollback_and_reboot()
			}
			
			
		}
	}
}
