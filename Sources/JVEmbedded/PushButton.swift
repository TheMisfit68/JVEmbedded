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

open class PushButton: GPIOedgeDelegate {
	
	public var digitalInput: DigitalInput
	private var clickIncrementInterval: TimeInterval = 0.5
	private var clickIncrementTimer: Oscillator!
	private var longPressDuration: TimeInterval = 1.0
	private var longPressTimer: OnDelayTimer!
	
	open var currentClickCount: Int = 0
	var delegate: PushButtonDelegate?
	
	init(pinNumber: Int, logic: DigitalLogic = .straight) {
		
		self.currentClickCount = 0
		self.digitalInput = DigitalInput(pinNumber, logic: logic, interruptType: .anyEdge)

		self.clickIncrementTimer = Oscillator(name: "PushButton.clickIncrementTimer", delay: clickIncrementInterval) { [self] clickIncrementTimer in
			if clickIncrementTimer.output {
				self.currentClickCount += 1
			}
			self.parseCurrentClickCount()
		}
		
		
		self.longPressTimer = OnDelayTimer(name: "PushButton.longPressTimer", delay: longPressDuration) { [self] longPressTimer in
			self.delegate?.onLongPress()
			longPressTimer.updateInput(value: false)
		}
		
		self.digitalInput.delegate = self
	}
	
	func onPositiveEdge() {
		clickIncrementTimer.updateEnable(value: true)
		longPressTimer.updateInput(value: true)
		currentClickCount += 1
	}
	
	func onNegativeEdge() {
		clickIncrementTimer.updateEnable(value: false)
		longPressTimer.updateInput(value: false)
	}
	
	func parseCurrentClickCount() {
		
		switch currentClickCount {
			case 1:
				delegate?.onClick()
			case 2:
				delegate?.onMultipleClicks(count: 2)
				delegate?.onDoubleClick()
			default:
				if currentClickCount > 2 {
					delegate?.onMultipleClicks(count: currentClickCount)
				}
		}
		currentClickCount = 0
	}
	
}


extension PushButtonDelegate {
	
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
