//
//  DIPswitch.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 22/04/2025.
//

public class DIPswitch{
	
	let digitalInputs: [DigitalInput]
	
	var value: UInt8 {
		var result: UInt8 = 0
		for (index, input) in digitalInputs.prefix(8).enumerated() {
			if input.logicalValue {
				result |= (1 << index)
			}
		}
		return result
	}
	
	init(digitalInputs: [DigitalInput]) {
		self.digitalInputs = digitalInputs
	}
		
}

