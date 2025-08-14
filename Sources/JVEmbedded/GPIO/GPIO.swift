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
	
	// MARK: - GPIO Configuration Enums
	// Values restricted to ESP32 value ranges
	public enum PinNumber: Int, RawRepresentable {
		
		case pin0 = 0
		case pin1 = 1
		case pin2 = 2
		case pin3 = 3
		case pin4 = 4
		case pin5 = 5
		case pin6 = 6
		case pin7 = 7
		case pin8 = 8
		case pin9 = 9
		case pin10 = 10
		case pin11 = 11
		case pin12 = 12
		case pin13 = 13
		case pin14 = 14
		case pin15 = 15
		case pin16 = 16
		case pin17 = 17
		case pin18 = 18
		case pin19 = 19
		case pin20 = 20
		case pin21 = 21
		case pin22 = 22
		case pin23 = 23
		
		var espValue: gpio_num_t {
			gpio_num_t(Int32(rawValue))
		}
	}
	
	
	public enum ChannelNumber: Int, RawRepresentable {
		
		case channel0 = 0
		case channel1 = 1
		case channel2 = 2
		case channel3 = 3
		case channel4 = 4
		case channel5 = 5
		
		var espValue: ledc_channel_t {
			switch self {
				case .channel0: return LEDC_CHANNEL_0
				case .channel1: return LEDC_CHANNEL_1
				case .channel2: return LEDC_CHANNEL_2
				case .channel3: return LEDC_CHANNEL_3
				case .channel4: return LEDC_CHANNEL_4
				case .channel5: return LEDC_CHANNEL_5
			}
		}
	}
	
	public enum TimerNumber: Int, RawRepresentable {
		
		case timer0 = 0
		case timer1 = 1
		case timer2 = 2
		case timer3 = 3
		
		var espValue: ledc_timer_t {
			switch self {
				case .timer0: return LEDC_TIMER_0
				case .timer1: return LEDC_TIMER_1
				case .timer2: return LEDC_TIMER_2
				case .timer3: return LEDC_TIMER_3
			}
		}
	}
	
	// Enum for Digital Logic
	public enum DigitalLogic: Int, RawRepresentable {
		
		case straight
		case inverse
		
		var espValue: UInt32 {
			self == .inverse ? 1 : 0
		}
	}
	
	let pinNumber: GPIO.PinNumber
	
	init(_ pinNumber: GPIO.PinNumber) {
		self.pinNumber = pinNumber
	}
	
	func configureGPIO() {
		fatalError("This method should be overridden in subclasses")
	}
	
	func resetPin() {
		guard gpio_reset_pin(self.pinNumber.espValue) == ESP_OK else {
			fatalError("GPIO reset failed")
		}
	}
}

protocol GPIOedgeDelegate: AnyObject {
	func onPositiveEdge(onInput input: DigitalInput)
	func onNegativeEdge(onInput input: DigitalInput)
}

// Subclass for Digital Input
public final class DigitalInput: GPIO {
	
	enum InterruptType {
		case positiveEdge
		case negativeEdge
		case anyEdge
		case none
		
		var espValue: gpio_int_type_t {
			switch self {
				case .positiveEdge: return GPIO_INTR_POSEDGE
				case .negativeEdge: return GPIO_INTR_NEGEDGE
				case .anyEdge: return GPIO_INTR_ANYEDGE
				case .none: return GPIO_INTR_DISABLE
			}
		}
	}
	
	let digitalLogic: GPIO.DigitalLogic
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
	
	init(_ pinNumber: GPIO.PinNumber, logic: GPIO.DigitalLogic = .straight, interruptType: InterruptType = .none, debounceDuration: TimeInterval = 0.05) {
		self.digitalLogic = logic
		self.interruptType = interruptType
		self.debounceDuration = debounceDuration
		super.init(pinNumber)
		configureGPIO()
		self.previousLogicalValue = logicalValue
	}
	
	override func configureGPIO() {
		resetPin()
		guard gpio_set_direction(pinNumber.espValue, GPIO_MODE_INPUT) == ESP_OK,
			  gpio_pullup_dis(pinNumber.espValue) == ESP_OK,
			  gpio_pulldown_en(pinNumber.espValue) == ESP_OK, // Enable pull-down to prevent floating input
			  gpio_set_intr_type(pinNumber.espValue, interruptType.espValue) == ESP_OK else {
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
		gpio_get_level(pinNumber.espValue) == 1
	}
	
	private func startEdgeDetectionService() {
		gpio_install_isr_service(0)
		gpio_isr_handler_add(pinNumber.espValue, { arg in
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
	let digitalLogic: GPIO.DigitalLogic
	
	
	init(_ pinNumber: GPIO.PinNumber, logic: GPIO.DigitalLogic = .straight) {
		self.digitalLogic = logic
		super.init(pinNumber)
		configureGPIO()
	}
	
	override func configureGPIO() {
		resetPin()
		guard gpio_set_direction(pinNumber.espValue, GPIO_MODE_OUTPUT) == ESP_OK,
			  gpio_pullup_dis(pinNumber.espValue) == ESP_OK,
			  gpio_pulldown_en(pinNumber.espValue) == ESP_OK else { // Enable pull-down to prevent floating output
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
			gpio_get_level(pinNumber.espValue) == 1
		}
		set {
			gpio_set_level(pinNumber.espValue, newValue ? 1 : 0)
		}
	}
}

// Subclass for PWM Output
public final class PWMOutput: GPIO {
	
	static var preconfiguredTimers:[Int] = []
	
	/// Call this once in app setup to enable LEDC fade functionality.
	public static func installFadingService() {
		guard ledc_fade_func_install(0) == ESP_OK else {
			fatalError("Failed to install LEDC fade service")
		}
	}
	
	private let timerNumber: GPIO.TimerNumber
	private let channelNumber: GPIO.ChannelNumber
	private let digitalLogic: GPIO.DigitalLogic
	
	
	/// Public property for frequency in Hz. Changing this reconfigures the timer.
	public var frequency: UInt32 = 0 {
		didSet {
			if (frequency <= 0) && !(oldValue <= 0) {
				stop() // Disable PWM if frequency is set to 0
			} else if (frequency > 0) {
				restart() // Resume PWM if frequency is valid
			}
		}
	}
	
	/// Percentage of the cycle that is HIGH (0–100%). Internally recalculates duty cycle.
	private var percentage: Int{
		didSet {
			restart()
		}
	}
	
	/// Computed raw duty cycle based on resolution and percentage.
	private var dutyCycle: UInt32 {
		let scale = 1 << dutyResolution.rawValue
		return UInt32((Double(percentage) / 100.0) * Double(scale))
	}
	
	private var dutyResolution:ledc_timer_bit_t {
		let srcClkHz: UInt32 = 80_000_000 // APB_CLK
		let rawResolution = ledc_find_suitable_duty_resolution(srcClkHz, frequency)
		
		guard rawResolution < UInt32(LEDC_TIMER_BIT_MAX.rawValue) else {
			fatalError("No suitable duty resolution found for frequency \(frequency)Hz")
		}
		
		return ledc_timer_bit_t(rawValue: rawResolution)
	}
	
	
	public init(_ pinNumber: GPIO.PinNumber, channelNumber: GPIO.ChannelNumber, timerNumber: GPIO.TimerNumber, percentage: Int = 50, logic: GPIO.DigitalLogic = .straight) {
		
		self.channelNumber = channelNumber
		self.timerNumber = timerNumber
		
		self.frequency = 1000 // Default frequency in Hz
		self.percentage = percentage.clamped(to: 0...100)
		
		self.digitalLogic = logic
		
		super.init(pinNumber)
		
		resetPin()
		configureGPIO()
		stop()
	}
	
	override func configureGPIO() {
		
		// Configure the timer
		setupTimer()

		// Configure the channel
		var channelConfig = ledc_channel_config_t(
			gpio_num: Int32(self.pinNumber.rawValue),
			speed_mode: LEDC_LOW_SPEED_MODE,
			channel: self.channelNumber.espValue,
			intr_type: LEDC_INTR_DISABLE,
			timer_sel: self.timerNumber.espValue,
			duty: self.dutyCycle,
			hpoint: 0,
			flags: .init(output_invert: self.digitalLogic.espValue)
		)
		
		guard ledc_channel_config(&channelConfig) == ESP_OK else {
			fatalError("LEDC channel configuration failed")
		}
	
	}
	
	/// Set PWM output to a specific percentage (0–100).
	public func setPercentage(to newPercentage: Int) {
		self.percentage = newPercentage.clamped(to: 0...100)
	}
	
	/// Smoothly fades PWM to a new percentage over time.
	public func fadeToPercentage(_ targetPercentage: Int, durationMs: Int) {
		setPercentage(to: targetPercentage)
		let fadeDuty = dutyCycle
		
		guard ledc_set_fade_with_time(LEDC_LOW_SPEED_MODE, channelNumber.espValue, fadeDuty, Int32(durationMs)) == ESP_OK,
			  ledc_fade_start(LEDC_LOW_SPEED_MODE, channelNumber.espValue, LEDC_FADE_NO_WAIT) == ESP_OK else {
			fatalError("Failed to fade duty cycle")
		}
	}
	
	public func start() {
		
		guard ledc_set_duty(LEDC_LOW_SPEED_MODE, channelNumber.espValue, dutyCycle) == ESP_OK else {
			fatalError("Failed to set duty")
		}
		guard ledc_update_duty(LEDC_LOW_SPEED_MODE, channelNumber.espValue) == ESP_OK else {
			fatalError("Failed to update duty")
		}
		
	}
	
	// Just an alias for start()
	// to make it sound more intuitive.
	public func restart() {
		start() // Resumes the PWM signal
	}
	
	// Stop the PWM signal.
	public func stop() {
		ledc_stop(LEDC_LOW_SPEED_MODE, channelNumber.espValue, 0)  // LOW level stop
	}
	
	// Mark: - Private helper Methods
	private func setupTimer() {
		
		// PWM outputs might share timers when used in tandem (e.g., for buzzers),
		// so we need to ensure the timer is configured only once.
		guard !PWMOutput.preconfiguredTimers.contains(timerNumber.rawValue) else { return }
				
		var timerConfig = ledc_timer_config_t(
			speed_mode: LEDC_LOW_SPEED_MODE,
			duty_resolution: self.dutyResolution,
			timer_num:self.timerNumber.espValue,
			freq_hz: self.frequency,
			clk_cfg: LEDC_AUTO_CLK,
			deconfigure: false
		)
		
		guard ledc_timer_config(&timerConfig) == ESP_OK else {
			fatalError("LEDC timer configuration failed")
		}
		
		PWMOutput.preconfiguredTimers.append(timerNumber.rawValue)
	}
	
}
