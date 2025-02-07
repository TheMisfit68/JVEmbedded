// [PushButton].swift
//
// A blend of human creativity by Jan Verrept and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

public protocol PushButtonDelegate: AnyObject {
	func onClick()
	func onDoubleClick()
	func onLongPress()
	func onMultipleClicks(count: Int)
}

open class PushButton: GPIOedgeDelegate {
	
	public var digitalInput: DigitalInput
	
	// Configurable intervals and durations (in seconds)
	private var multipleClickInterval: TimeInterval = 0.5 // 500 milliseconds
	private var multipleClickTimer: Timer!
	private var longPressDuration: TimeInterval = 1.0 // 1 second
	private var longPressTimer: Timer!
	
	open var currentClickCount: Int = 0
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
		
		self.longPressTimer = Timer(name: "PushButton.longPressTimer", delay: longPressDuration) {
			self.handleLongPress()
			self.multipleClickTimer.stop()
			self.currentClickCount = 0
		}
		
		// Set the delegate after everything is initialized
		self.digitalInput.delegate = self
	}
	
	func onPositiveEdge() {
		longPressTimer.start()
		multipleClickTimer.start()
		
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
	}
	
	private func handleDoubleClick() {
		delegate?.onDoubleClick()
		delegate?.onMultipleClicks(count: 2)
	}
	
	private func handleLongPress() {
		delegate?.onLongPress()
	}
	
	private func handleMultipleClicks() {
		delegate?.onMultipleClicks(count: currentClickCount)
	}
	
}

extension PushButton: PushButtonDelegate {
	
	public func onClick() {
#if DEBUG
		print("👉🔘 Single click detected")
#endif
	}
	
	public func onDoubleClick() {
#if DEBUG
		print("👉🔘👉🔘 Double click detected")
#endif
	}
	
	public func onLongPress() {
#if DEBUG
		print("⏱️👉🔘 Long press detected")
#endif
	}
	
	public func onMultipleClicks(count: Int) {
#if DEBUG
		print("👉🔘👉🔘…👉🔘 Multiple clicks detected: \(count)")
#endif
	}
}
