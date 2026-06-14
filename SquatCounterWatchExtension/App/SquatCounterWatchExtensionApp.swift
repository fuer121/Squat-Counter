import SwiftUI

@main
struct SquatCounterWatchExtensionApp: App {
    var body: some Scene {
        WindowGroup {
            WorkoutRootView(healthManager: WatchWorkoutHealthManager())
        }
    }
}
