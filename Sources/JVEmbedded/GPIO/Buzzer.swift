struct Buzzer {}

extension Buzzer {
	// MARK: - Passive buzzer using software tone generation
	public final class Passive {
		private let pinNumber: Int
		
		public init(pinNumber: Int) {
			self.pinNumber = pinNumber
			// Configure GPIO/PWM setup if needed
		}
		
		public func play(frequencyHz: Int, durationMs: Int) {
			// Direct tone generation at frequency
			// Placeholder for square wave logic or PWM driver
			print("🔊 Passive buzzer: playing \(frequencyHz)Hz for \(durationMs)ms on pin-number \(pinNumber)")
			// TODO: Use Timer or hardware call
		}
		
		public func stop() {
			// Stop tone
			print("🔇 Passive buzzer: stop")
			// TODO: stop PWM or square wave
		}
		
		public func play(tone tag: ToneGenerator.ToneTag) {
			guard let tone = ToneGenerator.tones[tag] else {
				print("❌ Tone '\(tag)' not found")
				return
			}
			self.play(frequencyHz: tone.frequencyHz, durationMs: tone.durationMs)
		}
		
		public func play(pattern tag: ToneGenerator.PatternTag) {
			guard let pattern = ToneGenerator.patterns[tag] else {
				print("❌ Pattern '\(tag)' not found")
				return
			}
			
			for _ in 0..<pattern.repeatCount {
				for tone in pattern.tones {
					if tone.frequencyHz > 0 {
						self.play(frequencyHz: tone.frequencyHz, durationMs: tone.durationMs)
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
	
	public static let tones: [ToneTag: Tone] = [
		.shortBeep: Tone(frequencyHz: 3000, durationMs: 100),
		.longBeep: Tone(frequencyHz: 1000, durationMs: 500),
		.doubleBeep: Tone(frequencyHz: 2000, durationMs: 200),
		.alarmTone1: Tone(frequencyHz: 3000, durationMs: 150),
		.alarmTone2: Tone(frequencyHz: 3000, durationMs: 150),
		.ackBeep: Tone(frequencyHz: 1000, durationMs: 100),
		.silence: Tone(frequencyHz: 0, durationMs: 100)
	]
	
	public static let patterns: [PatternTag: Pattern] = [
		.MAXMAXalarm: Pattern(
			tones: [
				tones[.alarmTone1]!,
				tones[.silence]!,
				tones[.alarmTone2]!
			],
			repeatCount: 4,
			interToneDelayMs: 80,
			interCycleDelayMs: 200
		),
		.MAXalarm: Pattern(
			tones: [
				tones[.ackBeep]!
			],
			repeatCount: 1,
			interToneDelayMs: 100,
			interCycleDelayMs: 100
		)
	]
}
