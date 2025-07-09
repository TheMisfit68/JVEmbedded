class Timer {
	public typealias TimerCallback = (Timer) -> Void  // Base class callback
	
	private var timerHandle: esp_timer_handle_t?
	public let name: String
	private let delay: TimeInterval
	public var callback: TimerCallback
	
	var isRunning: Bool {
		guard let timer = timerHandle else {
			return false
		}
		return esp_timer_is_active(timer)
	}
	
	init(name: String, delay: TimeInterval, callback: @escaping TimerCallback) {
		self.name = name
		self.delay = delay
		self.callback = callback
	}
	
	func start() {
		stop() // Ensure any existing timer is stopped
		
		let args = Unmanaged.passRetained(TimerCallbackWrapper(timer: self, callback: callback)).toOpaque()
		
		name.withCString { timerName in
			var timerConfig = esp_timer_create_args_t(
				callback: { arg in
					guard let arg = arg else { return }
					let wrapper = Unmanaged<TimerCallbackWrapper>.fromOpaque(arg).takeRetainedValue()
					wrapper.callback(wrapper.timer)
				},
				arg: args,
				dispatch_method: ESP_TIMER_TASK,
				name: timerName,
				skip_unhandled_events: false
			)
			
			var espTimer: esp_timer_handle_t?
			esp_timer_create(&timerConfig, &espTimer)
			esp_timer_start_once(espTimer, UInt64(delay * 1_000_000)) // Convert seconds to microseconds
			timerHandle = espTimer
		}
	}
	
	func restart() {
		start()
	}
	
	func stop() {
		if let timer = timerHandle {
			esp_timer_stop(timer)
			esp_timer_delete(timer)
			timerHandle = nil
		}
	}
	
	deinit {
		stop()
	}
}

class TimerCallbackWrapper {
	let timer: Timer
	let callback: (Timer) -> ()
	
	init(timer: Timer, callback: @escaping (Timer) -> ()) {
		self.timer = timer
		self.callback = callback
	}
}

// MARK: - Digital Timers
class OnDelayTimer: Timer {
	typealias OnDelayTimerCallback = (OnDelayTimer) -> Void
	
	var input: Bool = false {
		didSet {
			if input {
				start()
			} else {
				stop()
				output = false
			}
		}
	}
	
	var output: Bool = false
	
	override init(name: String, delay: TimeInterval, callback: @escaping OnDelayTimerCallback) {
		let tempCallback: TimerCallback = { _ in } // Temporary placeholder callback
		super.init(name: name, delay: delay, callback: tempCallback)
		
		// Adjust the actual callback after the super's initialization
		self.callback = { [self] _ in
			self.output = true
			callback(self)
		}
	}
	
	func updateInput(value: Bool) {
		input = value
	}
}

class OffDelayTimer: Timer {
	typealias OffDelayTimerCallback = (OffDelayTimer) -> Void
	
	var input: Bool = false {
		didSet {
			if input {
				output = true
				stop()
			} else {
				start()
			}
		}
	}
	
	var output: Bool = false
	
	override init(name: String, delay: TimeInterval, callback: @escaping OffDelayTimerCallback) {
		let tempCallback: TimerCallback = { _ in } // Temporary placeholder callback
		super.init(name: name, delay: delay, callback: tempCallback)
		
		// Adjust the actual callback after the super's initialization
		self.callback = { [self] _ in
			self.output = false
			callback(self)
		}
	}
	
	func updateInput(value: Bool) {
		input = value
	}
}

class PulseLimitingTimer: Timer {
	typealias PulseLimitingTimerCallback = (PulseLimitingTimer) -> Void
	
	var input: Bool = false {
		didSet {
			if input {
				start()
			} else {
				stop()
				output = false
			}
		}
	}
	
	var output: Bool = false
	
	override init(name: String, delay: TimeInterval, callback: @escaping PulseLimitingTimerCallback) {
		let tempCallback: TimerCallback = { _ in } // Temporary placeholder callback
		super.init(name: name, delay: delay, callback: tempCallback)
		
		// Adjust the actual callback after the super's initialization
		self.callback = { [self] _ in
			self.output = false
			callback(self)
		}
	}
	
	func updateInput(value: Bool) {
		input = value
	}
}

class ExactPulseTimer: Timer {
	typealias ExactPulseTimerCallback = (ExactPulseTimer) -> Void
	
	var input: Bool = false {
		didSet {
			if input {
				start()
			} else {
				stop()
				output = false
			}
		}
	}
	
	var output: Bool = false
	
	override init(name: String, delay: TimeInterval, callback: @escaping ExactPulseTimerCallback) {
		let tempCallback: TimerCallback = { _ in } // Temporary placeholder callback
		super.init(name: name, delay: delay, callback: tempCallback)
		
		// Adjust the actual callback after the super's initialization
		self.callback = { [self] _ in
			self.output = false
			callback(self)
		}
	}
	
	func updateInput(value: Bool) {
		input = value
	}
}

class Oscillator: Timer {
	typealias OscillatorCallback = (Oscillator) -> Void
	
	var enable: Bool = false {
		didSet {
			if enable && !oldValue {
				start()
			} else if !enable {
				stop()
				output = false
			}
		}
	}
	
	var output: Bool = false
	
	override init(name: String, delay: TimeInterval, callback: @escaping OscillatorCallback) {
		let tempCallback: TimerCallback = { _ in } // Temporary placeholder callback
		super.init(name: name, delay: delay, callback: tempCallback)
		
		// Adjust the actual callback after the super's initialization
		self.callback = { [self] _ in
			
			self.output = true
			callback(self)
			self.output = false
			
			// If the oscillator is still enabled, restart it for continuous oscillation
			if self.enable {
				self.restart()
			}
		}
	}
	
	func updateEnable(value: Bool) {

		enable = value
	}

}
