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
		
		public func play(frequencyHz: Int, durationMs: Int) {
			switch bridgeMode {
				case .phaseEnable:
					
					// set the frequency for the correct tone hight
					pwmOutput1.frequency = UInt32(frequencyHz)
					pwmOutput2.setPercentage(to: 100) // Enable the second output at full duty cycle
					
				case .inIn:
					
					// Both outputs are used to create the same square wave (but in opposite phases)
					pwmOutput1.frequency = UInt32(frequencyHz)
					pwmOutput2.frequency = UInt32(frequencyHz)
					pwmOutput1.setPercentage(to: 50)
					
			}
			
			JVEmbedded.Time.sleep(ms: durationMs)
			stop()
		}
		
		public func stop() {
			pwmOutput1.setPercentage(to: 0)
			pwmOutput2.setPercentage(to: 0)
		}
		
		public func play(tone tag: ToneGenerator.ToneTag) {
			guard let tone = ToneGenerator.tones.value(forKey: tag) else {
				print("❌ Tone '\(tag)' not found")
				return
			}
			play(frequencyHz: tone.frequencyHz, durationMs: tone.durationMs)
		}
		
		public func play(pattern tag: ToneGenerator.PatternTag) {
			guard let pattern = ToneGenerator.patterns.value(forKey: tag) else {
				print("❌ Pattern '\(tag)' not found")
				return
			}
			
			for _ in 0..<pattern.repeatCount {
				for tone in pattern.tones {
					if tone.frequencyHz > 0 {
						play(frequencyHz: tone.frequencyHz, durationMs: tone.durationMs)
					}
					JVEmbedded.Time.sleep(ms: pattern.interToneDelayMs)
				}
				JVEmbedded.Time.sleep(ms: pattern.interCycleDelayMs)
			}
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
public struct ToneGenerator {
	
	public enum ToneTag: String {
		case shortBeep
		case longBeep
		case doubleBeep
		case alarmTone1
		case alarmTone2
		case ackBeep
		case silence
	}
	
	public enum PatternTag: String {
		case MAXMAXalarm
		case MAXalarm
		case idle
	}
	
	public struct Tone {
		public let frequencyHz: Int
		public let durationMs: Int
	}
	
	public struct Pattern {
		public let tones: [Tone]
		public let repeatCount: Int
		public let interToneDelayMs: Int
		public let interCycleDelayMs: Int
	}
	
	public static let tones = JVEmbedded.Dictionary<ToneTag, Tone>([
		JVEmbedded.KeyValuePair(key: .shortBeep,   value: Tone(frequencyHz: 3000, durationMs: 100)),
		JVEmbedded.KeyValuePair(key: .longBeep,    value: Tone(frequencyHz: 1000, durationMs: 500)),
		JVEmbedded.KeyValuePair(key: .doubleBeep,  value: Tone(frequencyHz: 2000, durationMs: 200)),
		JVEmbedded.KeyValuePair(key: .alarmTone1,  value: Tone(frequencyHz: 3000, durationMs: 150)),
		JVEmbedded.KeyValuePair(key: .alarmTone2,  value: Tone(frequencyHz: 3000, durationMs: 150)),
		JVEmbedded.KeyValuePair(key: .ackBeep,     value: Tone(frequencyHz: 1000, durationMs: 100)),
		JVEmbedded.KeyValuePair(key: .silence,     value: Tone(frequencyHz: 0,    durationMs: 100))
	])
	
	public static let patterns = JVEmbedded.Dictionary<PatternTag, Pattern>([
		JVEmbedded.KeyValuePair(key: .MAXMAXalarm, value: Pattern(
			tones: [
				tones.value(forKey: .alarmTone1)!,
				tones.value(forKey: .silence)!,
				tones.value(forKey: .alarmTone2)!
			],
			repeatCount: 4,
			interToneDelayMs: 80,
			interCycleDelayMs: 200
		)),
		
		JVEmbedded.KeyValuePair(key: .MAXalarm, value: Pattern(
			tones: [
				tones.value(forKey: .ackBeep)!
			],
			repeatCount: 1,
			interToneDelayMs: 100,
			interCycleDelayMs: 100
		))
	])
}
