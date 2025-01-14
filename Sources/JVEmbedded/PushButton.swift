// [PushButton].swift
//
// A blend of human creativity by Jan Verrept and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

protocol PushButtonDelegate: AnyObject {
	func onClick()
	func onDoubleClick()
	func onLongPress()
	func onMultipleClicks(count: Int)
}

class PushButton: GPIOedgeDelegate {
	
	private var digitalInput: DigitalInput
	
	// Configurable intervals and durations (in seconds)
	private var multipleClickInterval: TimeInterval = 0.5 // 500 milliseconds
	private var multipleClickTimer: Timer!
	private var longPressTimer: Timer!
	
	private var currentClickCount: Int = 0
	public var delegate: PushButtonDelegate?
	
	init(pinNumber: Int, logic: DigitalLogic = .straight) {
		
		// Phase 1: Initialize stored properties
		self.digitalInput = DigitalInput(pinNumber, logic: logic, interruptType: .anyEdge)
		
		// Phase 2: Initialize timers after `self` is fully initialized
		self.multipleClickTimer = Timer(name: "PushButton.multipleClickTimer", delay: multipleClickInterval) {
			
			// Either the button was kept pressed all the time and the clickcount just goes up
			if self.longPressTimer.isRunning {
				self.currentClickCount += 1
			}else{
				// Or the button was released at some time and the clickcount should be parsed
				self.parseMultipleClickCount()
			}
		}
		
		self.longPressTimer = Timer(name: "PushButton.longPressTimer", delay: 1.0) {
			self.handleLongPress()
		}
		
		// Set the delegate after everything is initialized
		self.digitalInput.delegate = self
	}
	
	func onPositiveEdge() {
		if currentClickCount == 0 {
			multipleClickTimer.start()
		}
		multipleClickTimer.restart()
		currentClickCount += 1
	}
	
	func onNegativeEdge() {
		longPressTimer.stop()
	}
	
	private func parseMultipleClickCount() {
		
		if currentClickCount == 1 {
			handleSingleClick()
		} else if currentClickCount == 2 {
			handleDoubleClick()
		} else if currentClickCount > 2 {
			handleMultipleClicks()
		}
		multipleClickTimer.stop()
		currentClickCount = 0
	}
	
	private func handleSingleClick() {
		delegate?.onClick()
		print("👉🔘 Single click detected")
	}
	
	private func handleDoubleClick() {
		delegate?.onDoubleClick()
		delegate?.onMultipleClicks(count: 2)
		print("👉🔘👉🔘 Double click detected")
	}
	
	private func handleLongPress() {
		delegate?.onLongPress()
		print("⏱️👉🔘 Long press detected")
	}
	
	private func handleMultipleClicks() {
		print("👉🔘👉🔘…👉🔘 Multiple clicks detected: \(currentClickCount)")
		delegate?.onMultipleClicks(count: currentClickCount)
	}
	
}
