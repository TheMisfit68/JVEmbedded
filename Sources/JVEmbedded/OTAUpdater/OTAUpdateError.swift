//
//  OTAUpdateError.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 26/05/2025.
//


public enum OTAUpdateError: Error, ESPErrorProtocol {
		case failedToGetPartition
		case failedToGetState
	}
