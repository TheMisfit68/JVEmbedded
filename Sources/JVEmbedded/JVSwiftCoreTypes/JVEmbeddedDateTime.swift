//
//  JVDateTime.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 28/12/2024.
//

typealias TimeInterval = Double // TimeInterval is a typealias for Double but not net supported in Embedded Swift

extension JVEmbedded{
	
	struct Date{
		
		public static var now:TimeInterval{
			let microseconds = esp_timer_get_time() // Replace with platform-specific function
			return TimeInterval(microseconds) / 1_000_000.0 // Convert microseconds to seconds
		}
		
	}

	struct Time{
		
		public static func sleep(ms: Int){
			let delay = UInt32(ms) / (1000 / UInt32(configTICK_RATE_HZ))
			vTaskDelay(delay)
		}
		
	}
	
}
