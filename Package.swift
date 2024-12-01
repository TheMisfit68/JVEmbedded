// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "JVEmbedded",
	platforms: [
		.macOS("10.15"),
	],
	products: [
		// This package doesn't actually build anything,
		// The build process is configured with CMake and executed using idf.py from the terminal
			.library(name: "SPMdummyTarget", targets: ["SPMdummyTarget"])
	],
	dependencies:[
		.package(path: "~/Documents/Development/Projects/Personal/Embedded Controllers/MatTerMaster"),
	],
	targets: [
		.target(
			name: "SPMdummyTarget"
		)
	]
)
