// GPIO.swift
// JVembedded
//
// Created by Jan Verrept on 05/11/2024.
//
// A blend of human creativity by TheMisfit68 and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.
//


// Base class to standardize GPIO configurations
class GPIO {
	typealias GPIOpinNumber = gpio_num_t
	
	let pinNumber: Int
	var gpioPinNumber: GPIOpinNumber {
		GPIOpinNumber(Int32(pinNumber))
	}
	
	init(_ pinNumber: Int) {
		self.pinNumber = pinNumber
	}
	
	func configureGPIO() {
		fatalError("This method should be overridden in subclasses")
	}
	
	func resetPin() {
		guard gpio_reset_pin(self.gpioPinNumber) == ESP_OK else {
			fatalError("GPIO reset failed")
		}
	}
}

// Enum for Digital Logic
enum DigitalLogic: Int {
	case straight
	case inverse
}

protocol GPIOedgeDelegate: AnyObject {
	func onPositiveEdge()
	func onNegativeEdge()
}

// Subclass for Digital Input
class DigitalInput: GPIO {
	
	enum InterruptType {
		case positiveEdge
		case negativeEdge
		case anyEdge
		case none
		
		var rawValue: gpio_int_type_t {
			switch self {
				case .positiveEdge: return GPIO_INTR_POSEDGE
				case .negativeEdge: return GPIO_INTR_NEGEDGE
				case .anyEdge: return GPIO_INTR_ANYEDGE
				case .none: return GPIO_INTR_DISABLE
			}
		}
	}
	
	let digitalLogic: DigitalLogic
	let interruptType: InterruptType
	var delegate: GPIOedgeDelegate?
	private var previousLogicalValue: Bool!
	
	init(_ pinNumber: Int, logic: DigitalLogic = .straight, interruptType: InterruptType = .none) {
		self.digitalLogic = logic
		self.interruptType = interruptType
		super.init(pinNumber)
		configureGPIO()
		self.previousLogicalValue = logicalValue
	}
	
	override func configureGPIO() {
		resetPin()
		guard gpio_set_direction(gpioPinNumber, GPIO_MODE_INPUT) == ESP_OK,
			  gpio_pullup_dis(gpioPinNumber) == ESP_OK,
			  gpio_pulldown_dis(gpioPinNumber) == ESP_OK,
			  gpio_set_intr_type(gpioPinNumber, interruptType.rawValue) == ESP_OK else {
			fatalError("Digital input configuration failed")
		}
		if delegate != nil && interruptType != .none {
			startEdgeDetectionService()
		}
	}
	
	public var logicalValue: Bool {
		ioValue ^^ (digitalLogic == .inverse)
	}
	
	private var ioValue: Bool {
		gpio_get_level(gpioPinNumber) == 1
	}
	
	private func startEdgeDetectionService() {
		gpio_install_isr_service(0)
		gpio_isr_handler_add(gpioPinNumber, { arg in
			guard let rawPointer = arg else { return }
			let instance = Unmanaged<DigitalInput>.fromOpaque(rawPointer).takeUnretainedValue()
			instance.handleInterrupt()
		}, Unmanaged.passUnretained(self).toOpaque())
	}
	
	private func handleInterrupt() {
		guard let delegate else { return }
		if !previousLogicalValue && logicalValue {
			delegate.onPositiveEdge()
		} else if previousLogicalValue && !logicalValue {
			delegate.onNegativeEdge()
		} else {
			return
		}
		previousLogicalValue = logicalValue
	}
}

// Subclass for Digital Output
class DigitalOutput: GPIO {
	let digitalLogic: DigitalLogic
	
	
	init(_ pinNumber: Int, logic: DigitalLogic = .straight) {
		self.digitalLogic = logic
		super.init(pinNumber)
		configureGPIO()
	}
	
	override func configureGPIO() {
		resetPin()
		guard gpio_set_direction(gpioPinNumber, GPIO_MODE_OUTPUT) == ESP_OK,
			  gpio_pullup_dis(gpioPinNumber) == ESP_OK,
			  gpio_pulldown_dis(gpioPinNumber) == ESP_OK else {
			fatalError("Digital output configuration failed")
		}
	}
	
	public var logicalValue: Bool = false {
		didSet {
			ioValue = logicalValue ^^ (digitalLogic == .inverse)
		}
	}
	
	private var ioValue: Bool {
		get {
			gpio_get_level(gpioPinNumber) == 1
		}
		set {
			gpio_set_level(gpioPinNumber, newValue ? 1 : 0)
		}
	}
}

// Subclass for PWM Output
class PWMOutput: GPIO {
	private static let frequency: UInt32 = 5000
	private static let maxScale: UInt32 = 8192
	
	private let pwmChannel: ledc_channel_t
	private var percentage: Int = 50 {
		didSet {
			percentage = min(100, max(0, percentage))
		}
	}
	
	private var dutyCycle: UInt32 {
		UInt32((Double(percentage) / 100.0) * Double(Self.maxScale))
	}
	
	init(_ pinNumber: Int, channelNumber: Int, percentage: Int = 50) {
		self.percentage = percentage
		switch channelNumber {
			case 0: pwmChannel = LEDC_CHANNEL_0
			case 1: pwmChannel = LEDC_CHANNEL_1
			case 2: pwmChannel = LEDC_CHANNEL_2
			case 3: pwmChannel = LEDC_CHANNEL_3
			case 4: pwmChannel = LEDC_CHANNEL_4
			case 5: pwmChannel = LEDC_CHANNEL_5
			default: fatalError("Invalid channel number")
		}
		super.init(pinNumber)
		configureGPIO()
	}
	
	override func configureGPIO() {
		resetPin()
		var timerConfig = ledc_timer_config_t(
			speed_mode: LEDC_LOW_SPEED_MODE,
			duty_resolution: LEDC_TIMER_13_BIT,
			timer_num: LEDC_TIMER_0,
			freq_hz: Self.frequency,
			clk_cfg: LEDC_AUTO_CLK,
			deconfigure: false
		)
		guard ledc_timer_config(&timerConfig) == ESP_OK else {
			fatalError("LEDC timer configuration failed")
		}
		
		var channelConfig = ledc_channel_config_t(
			gpio_num: Int32(pinNumber),
			speed_mode: LEDC_LOW_SPEED_MODE,
			channel: pwmChannel,
			intr_type: LEDC_INTR_DISABLE,
			timer_sel: LEDC_TIMER_0,
			duty: dutyCycle,
			hpoint: 0,
			flags: .init(output_invert: 0)
		)
		guard ledc_channel_config(&channelConfig) == ESP_OK else {
			fatalError("LEDC channel configuration failed")
		}
	}
	
	func setPercentage(to newPercentage: Int) {
		percentage = newPercentage
		guard ledc_set_duty(LEDC_LOW_SPEED_MODE, pwmChannel, dutyCycle) == ESP_OK else {
			fatalError("Failed to set duty")
		}
		guard ledc_update_duty(LEDC_LOW_SPEED_MODE, pwmChannel) == ESP_OK else {
			fatalError("Failed to update duty")
		}
	}
	
	func fadeToPercentage(_ targetPercentage: Int, durationMs: Int) {
		percentage = targetPercentage
		guard ledc_set_fade_with_time(LEDC_LOW_SPEED_MODE, pwmChannel, dutyCycle, Int32(durationMs)) == ESP_OK,
			  ledc_fade_start(LEDC_LOW_SPEED_MODE, pwmChannel, LEDC_FADE_NO_WAIT) == ESP_OK else {
			fatalError("Failed to fade duty cycle")
		}
	}
}
