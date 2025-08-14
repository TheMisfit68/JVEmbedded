// Counter.swift
//
// A blend of human creativity by TheMisfit68  and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

public class Counter {
	
	public let pulsePinNumber: GPIO.PinNumber
	public let controlPinNumber: GPIO.PinNumber
	public var handle: pcnt_unit_handle_t?
	public var channelHandle: pcnt_channel_handle_t?
	
	public init(pulsePinNumber: GPIO.PinNumber,
				controlPinNumber: GPIO.PinNumber,
				highLimit: Int32 = 32767,
				lowLimit: Int32 = -32768) throws(ESPError) {
		
		self.pulsePinNumber = pulsePinNumber
		self.controlPinNumber = controlPinNumber
		
		var config = pcnt_unit_config_t()
		config.high_limit = highLimit
		config.low_limit = lowLimit
		
		try ESPError.check(pcnt_new_unit(&config, &handle))
		
		if let handle = handle {
			var channelConfig = pcnt_chan_config_t()
			channelConfig.edge_gpio_num = Int32(pulsePinNumber.rawValue)
			channelConfig.level_gpio_num = Int32(controlPinNumber.rawValue)
			
			var channelHandle: pcnt_channel_handle_t?
			
			try ESPError.check(pcnt_new_channel(handle, &channelConfig, &channelHandle))
			
			pcnt_channel_set_edge_action(channelHandle, PCNT_CHANNEL_EDGE_ACTION_DECREASE, PCNT_CHANNEL_EDGE_ACTION_INCREASE)
			pcnt_channel_set_level_action(channelHandle, PCNT_CHANNEL_LEVEL_ACTION_KEEP, PCNT_CHANNEL_LEVEL_ACTION_INVERSE)
			self.channelHandle = channelHandle
			
			// Start counting
			pcnt_unit_enable(handle)
			pcnt_unit_start(handle)
		}
	}
	
	public func read() -> Int16 {
		var value: Int32 = 0
		if let handle = handle {
			pcnt_unit_get_count(handle, &value)
		}
		return Int16(clamping: value)
	}
	
	// Just an alias for clear()
	public func reset() {
		clear()
	}
	
	public func clear() {
		if let handle = handle {
			pcnt_unit_clear_count(handle)
		}
	}
	
	public func pause() {
		if let handle = handle {
			pcnt_unit_disable(handle)
		}
	}
	
	public func resume() {
		if let handle = handle {
			pcnt_unit_enable(handle)
		}
	}
}
