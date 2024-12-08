// BoardType.swift
//
// A blend of human creativity by TheMisfit68 and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

import Foundation

/// An enum representing different ESP32 board types with their built-in LED GPIO pins.
enum BoardType: Int {
	
	// The raw values are the GPIO pin numbers the built-in LED is connected to
	case XIAO_ESP32C6 = 15
	case ESP32_C6_DevKitC_1 = 8
	case DOIT_ESP32_devkit = 2
	
	/// The GPIO pin number of the built-in LED.
	var ledPin: Int {
		return self.rawValue
	}
	
	/// The type of built-in LED.
	var ledType: LedType {
		switch self {
			case .XIAO_ESP32C6: return .normal
			case .ESP32_C6_DevKitC_1: return .addressable
			case .DOIT_ESP32_devkit: return .normal
		}
	}
	
}

/// An enum representing the type of LED.
enum LedType: String {
	case normal       // Standard single-color LED
	case addressable // Addressable LEDs like WS2812
}
