//
//  RotaryEncoder.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 10/07/2025.
//

public protocol RotaryEncoderDelegate: AnyObject {
	func valueChanged(on rotaryEncoder:RotaryEncoder, newValue: Double)
}

public final class RotaryEncoder {
	
	let fastCounter:Counter
	
	public private(set) var value: Double = 0.0 {
		didSet {
			if value != oldValue {
				delegate?.valueChanged(on: self, newValue: value)
#if DEBUG
				let stringValue:String = String(value)
				print("🎛️ RotaryEncoder value changed: \(stringValue)")
#endif
			}
		}
	}
	
	private let stepValue: Double
	private let range: ClosedRange<Double>
	
	public var delegate: RotaryEncoderDelegate? = nil
	public var resetButton: DigitalInput? = nil
	
	public init(
		clockPinNumber:Int32,
		dataPinNumber:Int32? = nil,
		switchPinNumber:Int? = nil,
		stepValue:Double = 1.0,
		range:ClosedRange<Double> = 0.0...100.0,
		unit:Counter.Unit = .unit0
	) throws(ESPError) {
		self.stepValue = stepValue
		self.range = range
		self.fastCounter = try Counter(pulsePinNumber: clockPinNumber, controlPinNumber: dataPinNumber, unit: unit)
		if let switchPin = switchPinNumber {
			let button = DigitalInput(switchPin, interruptType: .negativeEdge)
			self.resetButton = button
			self.resetButton?.delegate = self
		}
	}
	
	public func reset() {
		self.value = 0.0
	}
	
	public func update() {
		let count = fastCounter.read()
		fastCounter.reset()
		let delta = Double(count) * stepValue
		value = (value + delta).clamped(to: range)
	}
	
}

extension RotaryEncoder:GPIOedgeDelegate{
	
	public func onPositiveEdge(onInput input: DigitalInput) {}
	
	public func onNegativeEdge(onInput input: DigitalInput) {
		print("😄😄 RotaryEncoder reset button pressed")

		if input === resetButton {
			reset()
		}
	}
	
}
