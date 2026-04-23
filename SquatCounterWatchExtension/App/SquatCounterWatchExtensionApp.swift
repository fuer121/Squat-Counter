import SwiftUI

@main
struct SquatCounterWatchExtensionApp: App {
    #if DEBUG || BETA
    private let buildChannelDebugEnabled = true
    #else
    private let buildChannelDebugEnabled = false
    #endif

    private var internalDebugEnabled: Bool {
        buildChannelDebugEnabled
            || ProcessInfo.processInfo.arguments.contains("--enable-internal-detection-debug")
    }

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
