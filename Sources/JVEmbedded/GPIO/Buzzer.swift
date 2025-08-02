// Buzzer.swift
//
// A blend of human creativity by TheMisfit68  and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

struct Buzzer {}

extension Buzzer {
	
	public enum BridgeMode {
		case phaseEnable
		case inIn
	}
	
	// MARK: - Passive buzzer using software tone generation
	public final class Passive {
		
		private let bridgeMode: Buzzer.BridgeMode
		private let pwmOutput1: PWMOutput
		private let pwmOutput2: PWMOutput
		private let toneGen = ToneGenerator()
		
		// MARK: - Public initializer
		public init(pin1: Int, pin2: Int, bridgeMode: BridgeMode) {
			
			self.bridgeMode = bridgeMode
			// Initialize the PWM outputs with a duty cycle of 50% for a buzzer
			self.pwmOutput1 = PWMOutput(pin1, channelNumber: 0, percentage: 50)
			
			switch bridgeMode {
				case .phaseEnable:
					// If the bridge type is passivePhaseEnable, we use the second output as a constant enable signal
					self.pwmOutput2 = PWMOutput(pin2, channelNumber: 1, percentage: 100)
				case .inIn:
					// If the bridge type is inIn, we need a second output for the opposite phase
					self.pwmOutput2 = PWMOutput(pin2, channelNumber: 1, percentage: 50, logic: .inverse)
			}
			self.stop()
			
		}
		
		public func play(pattern:ToneGenerator.Pattern) {
			
			for _ in 0..<pattern.repeatCount {
				for toneTag in pattern.tones {
					guard let tone = ToneGenerator.tones.value(forKey: toneTag) else {
						print("❌ Tone '\(toneTag)' not found")
						continue
					}
					if tone.frequencyHz > 0 {
						play(frequencyHz: tone.frequencyHz, durationMs: tone.durationMs)
					}
					JVEmbedded.Time.sleep(ms: pattern.interToneDelayMs)
				}
				JVEmbedded.Time.sleep(ms: pattern.interCycleDelayMs)
			}
			
		}
		
		public func play(tone tag: ToneGenerator.ToneTag) {
			
			guard let tone = ToneGenerator.tones.value(forKey: tag) else {
				print("❌ Tone '\(tag)' not found")
				return
			}
			play(frequencyHz: tone.frequencyHz, durationMs: tone.durationMs)
		}
		
		public func stop() {
			pwmOutput1.enabled = false
			pwmOutput2.enabled = false
		}
		
		// MARK: - Private helper methods
		
		private func play(frequencyHz: Int, durationMs: Int) {
			
			// set the frequency for the correct tone hight
			switch bridgeMode {
				case .phaseEnable:
					
					pwmOutput1.frequency = UInt32(frequencyHz)
					
				case .inIn:
					
					// Both outputs are used to create the same square wave (but in opposite phases)
					pwmOutput1.frequency = UInt32(frequencyHz)
					pwmOutput2.frequency = UInt32(frequencyHz)
			}
			
			JVEmbedded.Time.sleep(ms: durationMs)
			stop()
		}
		
	}
	
	// MARK: - Active buzzer (on/off only)
	public final class Active {
		
		private let output: DigitalOutput
		
		public init(pin: Int) {
			self.output = DigitalOutput(pin)
			self.stop() // Ensure it's off initially
		}
		
		public func start() {
			output.logicalValue = true
		}
		
		public func stop() {
			output.logicalValue = false
		}
		
		public func beep(durationMs: Int) {
			start()
			JVEmbedded.Time.sleep(ms: durationMs)
			stop()
		}
	}
}


// ToneGenerator.swift
// used with a passive buzzer for generating various tones and patterns
public struct ToneGenerator {
	
	public enum ToneTag: String {
		case lowBeep
		case midBeep
		case highBeep
		case shortClick
		case silence
	}
	
	// MARK: - Tone Struct
	public struct Tone {
		
		public let frequencyHz: Int
		public let durationMs: Int
		
		public init(frequencyHz: Int, durationMs: Int) {
			self.frequencyHz = frequencyHz
			self.durationMs = durationMs
		}
		
	}
	
	public static let tones = JVEmbedded.Dictionary<ToneTag, Tone>([
		JVEmbedded.KeyValuePair(key: .lowBeep,   value: Tone(frequencyHz: 250, durationMs: 200)),
		JVEmbedded.KeyValuePair(key: .midBeep,    value: Tone(frequencyHz: 700, durationMs: 200)),
		JVEmbedded.KeyValuePair(key: .highBeep,  value: Tone(frequencyHz: 2000, durationMs: 200)),
		JVEmbedded.KeyValuePair(key: .shortClick,  value: Tone(frequencyHz: 1000, durationMs: 80)),
		JVEmbedded.KeyValuePair(key: .silence, value: Tone(frequencyHz: 0, durationMs: 100))
	])
	
	// MARK: - Pattern Definition
	public struct Pattern {
		public let tones: [ToneTag]
		public let repeatCount: Int
		public let interToneDelayMs: Int
		public let interCycleDelayMs: Int
	}
	
	public static let toneScale = ToneGenerator.Pattern(
		tones: [
			.lowBeep,
			.midBeep,
			.highBeep
		],
		repeatCount: 2,
		interToneDelayMs: 80,
		interCycleDelayMs: 100
	)

}
