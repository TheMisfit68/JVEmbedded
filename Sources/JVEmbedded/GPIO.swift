// GPIO.swift
// JVembedded
//
// Created by Jan Verrept on 05/11/2024.
//

// Digital Logic Enum for input/output inversion
// Can be used as a inverter using XOR
enum DigitalLogic: Int {
	case straight
	case inverse
}

// Protocol to standardize basic GPIO configurations
protocol GPIO {
	typealias GPIOpinNumber = gpio_num_t
	var pinNumber: Int { get }
	var gpioPinNumber: GPIOpinNumber { get }
	func configureGPIO()
}

extension GPIO {
	var gpioPinNumber: GPIOpinNumber {
		GPIOpinNumber(Int32(pinNumber))
	}
}

// DigitalInput GPIO configuration
struct DigitalInput: GPIO {
	let pinNumber: Int
	let digitalLogic: DigitalLogic
	
	init(_ pinNumber: Int, logic: DigitalLogic = .straight) {
		self.pinNumber = pinNumber
		self.digitalLogic = logic
		configureGPIO()
	}
	
	func configureGPIO() {
		guard (gpio_reset_pin(self.gpioPinNumber) == ESP_OK) else {
			fatalError("GPIO reset failed")
		}
		guard gpio_set_direction(gpioPinNumber, GPIO_MODE_INPUT) == ESP_OK,
			  gpio_pullup_dis(gpioPinNumber) == ESP_OK,
			  gpio_pulldown_dis(gpioPinNumber) == ESP_OK,
			  gpio_set_intr_type(gpioPinNumber, GPIO_INTR_DISABLE) == ESP_OK else {
			fatalError("Digital input configuration failed")
		}
	}
	
	// Read the logical value based on the configured DigitalLogic,
	// using an logical XOR as a 'controllable inverter'
	var logicalValue: Bool {
		return (ioValue ^^ (digitalLogic == .inverse)) // Boolean XOR to invert the bit based on the logic set
	}
	
	var ioValue: Bool {
		return ( gpio_get_level(gpioPinNumber) == 1 )
	}
}

// DigitalOutput GPIO configuration
struct DigitalOutput: GPIO {
	let pinNumber:Int
	let digitalLogic: DigitalLogic
	
	init(_ pinNumber: Int, logic: DigitalLogic = .straight) {
		self.pinNumber = pinNumber
		self.digitalLogic = logic
		configureGPIO()
	}
	
	func configureGPIO() {
		guard (gpio_reset_pin(self.gpioPinNumber) == ESP_OK) else {
			fatalError("GPIO reset failed")
		}
		guard gpio_set_direction(gpioPinNumber, GPIO_MODE_INPUT_OUTPUT) == ESP_OK,
			  gpio_pullup_dis(gpioPinNumber) == ESP_OK,
			  gpio_pulldown_dis(gpioPinNumber) == ESP_OK else{
			fatalError("Digital output configuration failed")
		}
	}
	
	// Write the logical value based on the configured DigitalLogic
	public var logicalValue: Bool = false {
		didSet {
			// Passing the logical value to the IO level, preserving the DigitalLogic behind it,
			// using a logical XOR as a 'controllable inverter'
			ioValue = (logicalValue ^^ (digitalLogic == .inverse))
		}
	}
	
	// IO value that reflects the hardware state
	public var ioValue: Bool {
		get {
			let gpioValue = gpio_get_level(gpioPinNumber)
			return (gpioValue == 1)
			
		}
		set {
			let newGpioValue: UInt32 = newValue ? 1 : 0
			gpio_set_level(gpioPinNumber, newGpioValue)
		}
	}
}

// AlarmInput GPIO configuration
struct AlarmInput: GPIO {
	let pinNumber: Int
	let digitalLogic: DigitalLogic
	
	init(_ pinNumber: Int, logic: DigitalLogic = .straight) {
		self.pinNumber = pinNumber
		self.digitalLogic = logic
		configureGPIO()
	}
	
	func configureGPIO() {
		guard (gpio_reset_pin(self.gpioPinNumber) == ESP_OK) else {
			fatalError("GPIO reset failed")
		}
		guard gpio_set_direction(gpioPinNumber, GPIO_MODE_INPUT) == ESP_OK,
			  gpio_pullup_dis(gpioPinNumber) == ESP_OK,
			  gpio_pulldown_dis(gpioPinNumber) == ESP_OK,
			  gpio_set_intr_type(gpioPinNumber, GPIO_INTR_POSEDGE) == ESP_OK else {
			fatalError("Alarm input configuration failed")
		}
	}
}

struct PWMOutput: GPIO {
	
	static public func installFadingService() {
		// Install the fade service
		guard ledc_fade_func_install(0) == ESP_OK else {
			fatalError("Failed to install LEDC fade service")
		}
	}
	
	private static let frequency: UInt32 = 5000 // Constant frequency of 5 kHz
	private static let maxScale: UInt32 = 8192  // Top scale at a 13-bit resolution
	
	let pinNumber: Int
	private var pwmChannel: ledc_channel_t
	private var percentage: Int = 50 {
		didSet {
			// Clamp between 0 and 100
			percentage = min(100, max(0, percentage))
		}
	}
	
	private var dutyCycle: UInt32 {
		return UInt32((Double(percentage) / 100.0) * Double(PWMOutput.maxScale))
	}
	
	init(_ pinNumber: Int, channelNumber: Int, percentage: Int = 50) {
		self.pinNumber = pinNumber
		self.percentage = percentage
		
		// Set pwmChannel based on channelNumber
		switch channelNumber {
			case 0: pwmChannel = LEDC_CHANNEL_0
			case 1: pwmChannel = LEDC_CHANNEL_1
			case 2: pwmChannel = LEDC_CHANNEL_2
			case 3: pwmChannel = LEDC_CHANNEL_3
			case 4: pwmChannel = LEDC_CHANNEL_4
			case 5: pwmChannel = LEDC_CHANNEL_5
			default:
				fatalError("Invalid channel number. Must be between 0 and 7.")
		}
		
		configureGPIO()
	}
	
	func configureGPIO() {
		
		guard gpio_reset_pin(self.gpioPinNumber) == ESP_OK else {
			fatalError("GPIO reset failed")
		}
		
		var timerConfig = ledc_timer_config_t(
			speed_mode: LEDC_LOW_SPEED_MODE,
			duty_resolution: LEDC_TIMER_13_BIT,
			timer_num: LEDC_TIMER_0,
			freq_hz: PWMOutput.frequency,
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
	
	mutating func setPercentage(to newPercentage: Int) {
		self.percentage = newPercentage
		guard ledc_set_duty(LEDC_LOW_SPEED_MODE, pwmChannel, dutyCycle) == ESP_OK else {
			fatalError("Failed to set LEDC duty")
		}
		guard ledc_update_duty(LEDC_LOW_SPEED_MODE, pwmChannel) == ESP_OK else {
			fatalError("Failed to update LEDC duty")
		}
	}
	
	// Fade to a specified percentage over a given duration in milliseconds
	mutating func fadeToPercentage(_ targetPercentage: Int, durationMs: Int) {
		// Set percentage, which will clamp it between 0 and 100
		self.percentage = targetPercentage
		
		// Use the clamped `dutyCycle` value for fading
		guard ledc_set_fade_with_time(LEDC_LOW_SPEED_MODE, pwmChannel, dutyCycle, Int32(durationMs)) == ESP_OK else {
			fatalError("Failed to set LEDC fade")
		}
		guard ledc_fade_start(LEDC_LOW_SPEED_MODE, pwmChannel, LEDC_FADE_NO_WAIT) == ESP_OK else {
			fatalError("Failed to start LEDC fade")
		}
	}
}
