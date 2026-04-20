import SwiftUI

@main
struct SquatCounterWatchExtensionApp: App {
    private let internalDebugEnabled: Bool = {
#if DEBUG
        true
#else
        false
#endif
    }()

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
