// Buzzer.swift
//
// A blend of human creativity by TheMisfit68  and
// AI assistance from ChatGPT.
// Crafting the future, one line of Swift at a time.
// Copyright © 2023 Jan Verrept. All rights reserved.

struct Buzzer {}

extension Buzzer {
	
	// MARK: - Passive buzzer using software tone generation
	public final class Passive {
		
		private let output: PWMOutput
		
		public init(pinNumber: Int, channel: Int = 0) {
			self.output = PWMOutput(pinNumber, channelNumber: channel, percentage: 0)
			self.stop() // Ensure it's off initially
		}
		
		public func play(frequencyHz: Int, durationMs: Int) {
			output.frequency = UInt32(frequencyHz)
			output.setPercentage(to: 50) // 50% duty cycle for square wave
			JVEmbedded.Time.sleep(ms: durationMs)
			stop()
		}
		
		public func stop() {
			output.setPercentage(to: 0)
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
