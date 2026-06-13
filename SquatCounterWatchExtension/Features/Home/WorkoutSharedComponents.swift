import SwiftUI

/// A non-intrusive status line for HealthKit messages, shown across every
/// workout state when the view model has something to report.
struct HealthStatusBanner: View {
    let message: String?

    var body: some View {
        if let message {
            Text(message)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }
}

/// A compact title/value pair used by the configuration steppers.
struct WorkoutSettingLabel: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
        }
    }
}

/// The destructive "结束" button shared by the active and rest states.
struct EndWorkoutButton: View {
    let onRequestEnd: () -> Void

    var body: some View {
        Button("结束", role: .destructive, action: onRequestEnd)
    }
}
