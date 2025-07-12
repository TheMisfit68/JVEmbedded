// Counter.swift
//
// A blend of human creativity by TheMisfit68  and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

public class Counter {
	
	public enum Channel: Int32 {
		case channel0 = 0
		case channel1 = 1
	}
	
	public enum Unit: Int32 {
		case unit0 = 0
		case unit1 = 1
		case unit2 = 2
		case unit3 = 3
		case unit4 = 4
		case unit5 = 5
		case unit6 = 6
		case unit7 = 7
	}
	
	public let unit: Unit
	public let pulseGPIO: Int32
	public let controlGPIO: Int32?
	public var handle: pcnt_unit_handle_t?
	public var channelHandle: pcnt_channel_handle_t?
	
	public init(pulsePinNumber: Int32,
				controlPinNumber: Int32? = nil,
				unit: Unit = .unit0,
				channel: Channel = .channel0,
				highLimit: Int32 = 32767,
				lowLimit: Int32 = -32768) throws(ESPError) {
		
		self.pulseGPIO = pulsePinNumber
		self.controlGPIO = controlPinNumber
		self.unit = unit
		
		var config = pcnt_unit_config_t()
		config.high_limit = highLimit
		config.low_limit = lowLimit
		
		try ESPError.check(pcnt_new_unit(&config, &handle))
		
		if let handle = handle {
			var chanConfig = pcnt_chan_config_t()
			chanConfig.edge_gpio_num = pulsePinNumber
			chanConfig.level_gpio_num = controlPinNumber ?? -1
			
			var channelHandle: pcnt_channel_handle_t?
			
			try ESPError.check(pcnt_new_channel(handle, &chanConfig, &channelHandle))
			
			pcnt_channel_set_edge_action(channelHandle, PCNT_CHANNEL_EDGE_ACTION_DECREASE, PCNT_CHANNEL_EDGE_ACTION_INCREASE)
			pcnt_channel_set_level_action(channelHandle, PCNT_CHANNEL_LEVEL_ACTION_KEEP, PCNT_CHANNEL_LEVEL_ACTION_INVERSE)
			self.channelHandle = channelHandle
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
