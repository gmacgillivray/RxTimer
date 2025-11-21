// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RxTimer",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "RxTimer", targets: ["RxTimer"])
    ],
    targets: [
        .target(
            name: "RxTimer",
            path: "Sources",
            resources: [
                .process("Persistence/WorkoutTimer.xcdatamodeld")
            ]
        ),
        .testTarget(
            name: "RxTimerTests",
            dependencies: ["RxTimer"],
            path: "Tests"
        )
    ]
)
