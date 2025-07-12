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
public class GPIO {
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
	func onPositiveEdge(onInput input:DigitalInput)
	func onNegativeEdge(onInput input:DigitalInput)
}

// Subclass for Digital Input
public final class DigitalInput: GPIO {
	
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
	var delegate: GPIOedgeDelegate? {
		didSet {
			if delegate != nil && interruptType != .none {
				startEdgeDetectionService()
			}
		}
	}
	private var debounceTimer: Timer?
	private var debounceDuration: TimeInterval = 0.05 // Default debounce duration in seconds
	private var previousLogicalValue: Bool!
	
	init(_ pinNumber: Int, logic: DigitalLogic = .straight, interruptType: InterruptType = .none, debounceDuration: TimeInterval = 0.05) {
		self.digitalLogic = logic
		self.interruptType = interruptType
		self.debounceDuration = debounceDuration
		super.init(pinNumber)
		configureGPIO()
		self.previousLogicalValue = logicalValue
	}
	
	override func configureGPIO() {
		resetPin()
		guard gpio_set_direction(gpioPinNumber, GPIO_MODE_INPUT) == ESP_OK,
			  gpio_pullup_dis(gpioPinNumber) == ESP_OK,
			  gpio_pulldown_en(gpioPinNumber) == ESP_OK, // Enable pull-down to prevent floating input
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
		debounceTimer?.stop() // Stop any running debounce timer
		debounceTimer = Timer(name: "DebounceTimer", delay: debounceDuration) { [self] _ in
			let currentLogicalValue = logicalValue
			if !previousLogicalValue && currentLogicalValue {
				delegate?.onPositiveEdge(onInput:self)
			} else if previousLogicalValue && !currentLogicalValue {
				delegate?.onNegativeEdge(onInput:self)
			}
			previousLogicalValue = currentLogicalValue
		}
		debounceTimer?.start()
	}
}

// Subclass for Digital Output
public final class DigitalOutput: GPIO {
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

// Struct to conviniently store and pass PWM configurations at the application level
public struct PWMConfiguration {
	let pin: Int
	let channel: Int
}

public final class PWMOutput: GPIO {
	
	private static let defaultFrequency: UInt32 = 5000
	
	private let timer: ledc_timer_t
	private let pwmChannel: ledc_channel_t
	private var dutyResolution: ledc_timer_bit_t = LEDC_TIMER_13_BIT
	
	/// Public property for frequency in Hz. Changing this reconfigures the timer.
	public var frequency: UInt32 = defaultFrequency {
		didSet {
			reconfigureTimerAndSyncDuty()
		}
	}
	
	/// Percentage of the cycle that is HIGH (0–100%). Internally recalculates duty cycle.
	private var percentage: Int = 50 {
		didSet {
			percentage = max(0, min(100, percentage))
			updateDuty()
		}
	}
	
	/// Computed raw duty cycle based on resolution and percentage.
	private var dutyCycle: UInt32 {
		let scale = 1 << dutyResolution.rawValue
		return UInt32((Double(percentage) / 100.0) * Double(scale))
	}
	
	/// Set PWM output to a specific percentage (0–100).
	public func setPercentage(to newPercentage: Int) {
		self.percentage = newPercentage
	}
	
	/// Smoothly fades PWM to a new percentage over time.
	public func fadeToPercentage(_ targetPercentage: Int, durationMs: Int) {
		let clamped = max(0, min(100, targetPercentage))
		percentage = clamped // update state immediately for consistency
		
		let fadeDuty = UInt32((Double(clamped) / 100.0) * Double(1 << dutyResolution.rawValue))
		
		guard ledc_set_fade_with_time(LEDC_LOW_SPEED_MODE, pwmChannel, fadeDuty, Int32(durationMs)) == ESP_OK,
			  ledc_fade_start(LEDC_LOW_SPEED_MODE, pwmChannel, LEDC_FADE_NO_WAIT) == ESP_OK else {
			fatalError("Failed to fade duty cycle")
		}
	}
	
	/// Call this once in app setup to enable LEDC fade functionality.
	public static func installFadingService() {
		guard ledc_fade_func_install(0) == ESP_OK else {
			fatalError("Failed to install LEDC fade service")
		}
	}
	
	/// Designated initializer. Allows selecting pin, channel, and timer.
	public init(_ pinNumber: Int, timerNumber: Int = 0, channelNumber: Int = 0, percentage: Int = 50) {
		self.percentage = percentage
		
		switch timerNumber {
			case 0: self.timer = LEDC_TIMER_0
			case 1: self.timer = LEDC_TIMER_1
			case 2: self.timer = LEDC_TIMER_2
			case 3: self.timer = LEDC_TIMER_3
			default: fatalError("Invalid timer number")
		}
		
		switch channelNumber {
			case 0: self.pwmChannel = LEDC_CHANNEL_0
			case 1: self.pwmChannel = LEDC_CHANNEL_1
			case 2: self.pwmChannel = LEDC_CHANNEL_2
			case 3: self.pwmChannel = LEDC_CHANNEL_3
			case 4: self.pwmChannel = LEDC_CHANNEL_4
			case 5: self.pwmChannel = LEDC_CHANNEL_5
			default: fatalError("Invalid channel number")
		}
		
		super.init(pinNumber)
		configureGPIO()
	}
	
	override func configureGPIO() {
		resetPin()
		reconfigureTimerAndSyncDuty()
		
		var channelConfig = ledc_channel_config_t(
			gpio_num: Int32(pinNumber),
			speed_mode: LEDC_LOW_SPEED_MODE,
			channel: pwmChannel,
			intr_type: LEDC_INTR_DISABLE,
			timer_sel: timer,
			duty: dutyCycle,
			hpoint: 0,
			flags: .init(output_invert: 0)
		)
		
		guard ledc_channel_config(&channelConfig) == ESP_OK else {
			fatalError("LEDC channel configuration failed")
		}
	}
	
	private func reconfigureTimerAndSyncDuty() {
		let srcClkHz: UInt32 = 80_000_000 // APB_CLK
		let rawResolution = ledc_find_suitable_duty_resolution(srcClkHz, frequency)
		
		guard rawResolution < UInt32(LEDC_TIMER_BIT_MAX.rawValue) else {
			fatalError("No suitable duty resolution found for frequency \(frequency)Hz")
		}
		
		let resolution = ledc_timer_bit_t(rawValue: rawResolution)
		self.dutyResolution = resolution
		
		var timerConfig = ledc_timer_config_t(
			speed_mode: LEDC_LOW_SPEED_MODE,
			duty_resolution: resolution,
			timer_num: timer,
			freq_hz: frequency,
			clk_cfg: LEDC_AUTO_CLK,
			deconfigure: false
		)
		
		guard ledc_timer_config(&timerConfig) == ESP_OK else {
			fatalError("LEDC timer configuration failed")
		}
		
		updateDuty()
	}
	
	private func updateDuty() {
		guard ledc_set_duty(LEDC_LOW_SPEED_MODE, pwmChannel, dutyCycle) == ESP_OK else {
			fatalError("Failed to set duty")
		}
		guard ledc_update_duty(LEDC_LOW_SPEED_MODE, pwmChannel) == ESP_OK else {
			fatalError("Failed to update duty")
		}
	}
}
