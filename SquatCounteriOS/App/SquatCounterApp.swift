import SwiftUI

@main
struct SquatCounterApp: App {
    @StateObject private var viewModel = PhoneCompanionViewModel()

    var body: some Scene {
        WindowGroup {
            PhoneCompanionHomeView(viewModel: viewModel)
        }
    }
}

