// Timer.swift
//
// A blend of human creativity by Jan Verrept and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.


/// A reusable timer class for embedded Swift using ESP-IDF's `esp_timer`.
class Timer {
	
	private var timerHandle: esp_timer_handle_t?
	private let name: String
	private let delay: TimeInterval
	private let callback: () -> Void
	
	/// A computed property that checks if the timer is currently active.
	var isRunning: Bool {
		guard let timer = timerHandle else {
			return false
		}
		return esp_timer_is_active(timer)
	}
	
	/// Initialize the timer with a unique name, delay, and callback.
	/// - Parameters:
	///   - name: A unique name for the timer.
	///   - delay: The delay in seconds.
	///   - callback: The closure to execute after the delay.
	init(name: String, delay: TimeInterval, callback: @escaping () -> Void) {
		self.name = name
		self.delay = delay
		self.callback = callback
	}
	
	/// Starts the timer.
	func start() {
		stop() // Ensure any existing timer is stopped
		
		let args = Unmanaged.passRetained(TimerCallbackWrapper(callback: callback)).toOpaque()
		
		name.withCString { timerName in
			var timerConfig = esp_timer_create_args_t(
				callback: { arg in
					guard let arg = arg else { return }
					let wrapper = Unmanaged<TimerCallbackWrapper>.fromOpaque(arg).takeRetainedValue()
					wrapper.callback()
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
	
	/// Restarts the timer using the same delay and callback.
	func restart() {
		start()
	}
	
	/// Stops the timer if it is running.
	func stop() {
		if let timer = timerHandle {
			esp_timer_stop(timer)
			esp_timer_delete(timer)
			timerHandle = nil
		}
	}
	
	deinit {
		stop() // Clean up the timer on deinitialization
	}
}

/// A wrapper for storing the timer's callback closure.
private class TimerCallbackWrapper {
	let callback: () -> Void
	init(callback: @escaping () -> Void) {
		self.callback = callback
	}
}
