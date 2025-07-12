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
	
	private var timeOutInterval: TimeInterval = 0.50
	private var timeOutTimer: OffDelayTimer!
	
	private var longPressDuration: TimeInterval = 1.0
	private var longPressTimer: OnDelayTimer!
	
	open var currentClickCount: Int = 0{
		didSet {
			if currentClickCount > 0 {
				parseCurrentClickCount()
			}
		}
	}
	let maxClickCount: Int
	var delegate: PushButtonDelegate?
	
	init(pinNumber: Int, logic: DigitalLogic = .straight, maxClickCount:Int = 2) {
		
		self.currentClickCount = 0
		self.digitalInput = DigitalInput(pinNumber, logic: logic, interruptType: .anyEdge)
		self.maxClickCount = maxClickCount
		
		self.longPressTimer = OnDelayTimer(name: "PushButton.longPressTimer", delay: longPressDuration) { [self] longPressTimer in
			self.delegate?.onLongPress()
			longPressTimer.updateInput(value: false)
		}
		
		self.timeOutTimer = OffDelayTimer(name: "PushButton.timeOutTimer", delay: timeOutInterval) {offDelayTimer in
			self.currentClickCount = 0
		}
		
		self.digitalInput.delegate = self
	}
	
	func onPositiveEdge(onInput input:DigitalInput){
		longPressTimer.updateInput(value: true)
		timeOutTimer.updateInput(value: true)
		currentClickCount += 1
	}
	
	func onNegativeEdge(onInput input:DigitalInput) {
		longPressTimer.updateInput(value: false)
		timeOutTimer.updateInput(value: false)
	}
	
	func parseCurrentClickCount() {
		
		switch currentClickCount {
			case 1:
				delegate?.onClick()
			case 2:
				delegate?.onDoubleClick()
				delegate?.onMultipleClicks(count: 2)
			case 3...:
				delegate?.onMultipleClicks(count: currentClickCount)
			default:
				break // No action for zero or negative counts
		}
		
		if currentClickCount >= maxClickCount {
			currentClickCount = 0 // Reset after reaching max count
		}
		
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
