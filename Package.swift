// swift-tools-version:6.0

// The JVEmbedded package is an embedded codebase designed for execution on ESP32 devices.
// The build process is managed entirely by CMake and executed using idf.py from the terminal.
//
// SPM is utilized exclusively for source file organization, dependency management,
// and documentation purposes. The actual building and flashing of the firmware
// are not handled within SPM or Xcode.
//
// © 2023 Jan Verrept. All rights reserved.
//

import PackageDescription

let package = Package(
	name: "JVEmbedded",
	platforms: [
		.macOS("10.15"),
	],
	products: [
			.library(name: "JVEmbedded", targets: ["JVEmbedded"])
	],
	dependencies:[
		// A Swift plugin package that might be useful in future
		.package(path: "~/Documents/Development/Projects/Personal/Embedded Controllers/MatTerMaster"),
	],
	targets: [
		.target(
			name: "JVEmbedded",
			sources: ["dummyFile.swift"]
		)
	]
)

