import SwiftUI

@main
struct SquatCounterWatchExtensionApp: App {
    private let internalDebugEnabled = ProcessInfo.processInfo.arguments.contains("--enable-internal-detection-debug")

    var body: some Scene {
        WindowGroup {
            WatchArchitectureOverviewView(
                healthManager: WatchWorkoutHealthManager(),
                motionSampler: WatchLiveSquatMotionSampler(),
                internalDebugEnabled: internalDebugEnabled
            )
        }
    }
}
