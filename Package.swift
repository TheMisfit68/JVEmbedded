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
			.library(name: "JVEmbedded", targets: ["JVEmbedded"]),
	],
	dependencies:[
		.package(path: "~/Documents/Development/Projects/Personal/Embedded Controllers/MatTerMaster"),
		// Just pull in some extra Embedded examples from Apple
		.package(url: "https://github.com/apple/swift-embedded-examples.git", branch: "main")
	],
	targets: [
		.target(
			name: "JVEmbedded",
			exclude: ["Exclude"]
		)
	]
)
