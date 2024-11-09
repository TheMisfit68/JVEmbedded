// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "JVEmbedded",
	platforms: [
		.macOS("10.15"),
	],
	products: [
		.library(name: "dummyTarget", targets: ["dummyTarget"]),
	],
	dependencies: [
		.package(path: "~/Documents/Development/Projects/Personal/Embedded Controllers/MatTerMasterPlugin"),
	],
	targets: [
		.target(
			name: "dummyTarget"
		)
	]
)
