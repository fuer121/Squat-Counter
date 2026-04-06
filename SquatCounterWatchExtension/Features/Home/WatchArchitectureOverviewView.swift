import SwiftUI

struct WatchArchitectureOverviewView: View {
    @StateObject private var viewModel = WorkoutSessionViewModel()
    @State private var isEndWorkoutAlertPresented = false

    var body: some View {
        activeContent
            .alert("结束训练？", isPresented: $isEndWorkoutAlertPresented) {
                Button("继续训练", role: .cancel) {}
                Button("结束", role: .destructive) {
                    viewModel.confirmEndWorkout()
                }
            } message: {
                Text("确认后会丢弃当前进度并返回首页。")
            }
    }

    @ViewBuilder
    private var activeContent: some View {
        switch viewModel.state {
        case .idle:
            configView
        case .countdown, .training:
            sessionView(
                state: viewModel.state,
                secondaryActionTitle: viewModel.state == .countdown ? "取消" : "暂停",
                onSecondaryAction: viewModel.state == .countdown ? viewModel.cancelCountdown : viewModel.pauseWorkout,
                showsEndAction: viewModel.state != .countdown
            )
        case .resting:
            restView(isPaused: false, onPrimaryAction: viewModel.completeRest, onPauseAction: viewModel.pauseWorkout)
        case .paused:
            pausedContent
        case .completed:
            completeView
        }
    }

    private var configView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Squat Counter")
                    .font(.headline)

                Text("开始一轮最小训练闭环")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Stepper(value: repsBinding, in: WorkoutConfig.repsRange) {
                    settingLabel(title: "每组次数", value: "\(viewModel.config.repsPerSet)")
                }

                Stepper(value: setsBinding, in: WorkoutConfig.setsRange) {
                    settingLabel(title: "总组数", value: "\(viewModel.config.totalSets)")
                }

                Stepper(value: restBinding, in: WorkoutConfig.restRange, step: 5) {
                    settingLabel(title: "休息时间", value: "\(viewModel.config.restSeconds) 秒")
                }

                Button("Start", action: viewModel.startWorkout)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

    private func sessionView(
        state: WorkoutState,
        secondaryActionTitle: String?,
        onSecondaryAction: (() -> Void)?,
        showsEndAction: Bool
    ) -> some View {
        VStack(spacing: 10) {
            Text(sessionTitle(for: state))
                .font(.headline)

            Text("第 \(viewModel.progress.currentSet) / \(viewModel.config.totalSets) 组")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(viewModel.progress.currentRep) / \(viewModel.config.repsPerSet)")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text(sessionHint(for: state))
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button(primaryButtonTitle(for: state), action: primaryActionForSessionState)
                .buttonStyle(.borderedProminent)

            if state == .training {
                HStack {
                    Button("-1", action: viewModel.decrementRep)
                    Button("+1", action: viewModel.incrementRep)
                }
            }

            HStack {
                if let secondaryActionTitle, let onSecondaryAction {
                    Button(secondaryActionTitle, action: onSecondaryAction)
                }

                if showsEndAction {
                    Button("结束", role: .destructive) {
                        isEndWorkoutAlertPresented = true
                    }
                }
            }
        }
        .padding()
    }

    private func restView(
        isPaused: Bool,
        onPrimaryAction: @escaping () -> Void,
        onPauseAction: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 10) {
            Text(isPaused ? "休息已暂停" : "本组完成")
                .font(.headline)

            Text(isPaused ? "继续后返回休息态" : "即将开始第 \(viewModel.progress.currentSet) / \(viewModel.config.totalSets) 组")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Text("\(viewModel.progress.remainingRestSeconds)s")
                .font(.system(size: 26, weight: .bold, design: .rounded))

            Button(isPaused ? "继续休息" : "开始下一组", action: onPrimaryAction)
                .buttonStyle(.borderedProminent)

            HStack {
                Button(isPaused ? "继续" : "暂停", action: onPauseAction)
                Button("结束", role: .destructive) {
                    isEndWorkoutAlertPresented = true
                }
            }
        }
        .padding()
    }

    private var completeView: some View {
        VStack(spacing: 10) {
            Text("训练完成")
                .font(.headline)

            Text("完成 \(viewModel.progress.currentSet) 组")
                .foregroundStyle(.secondary)

            Text("\(viewModel.progress.totalCompletedReps) 次")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Button("再来一次", action: viewModel.restartWorkout)
                .buttonStyle(.borderedProminent)

            Button("返回首页", action: viewModel.returnToHome)
        }
        .padding()
    }

    @ViewBuilder
    private var pausedContent: some View {
        switch viewModel.pauseContext?.resumeTarget {
        case .resting:
            restView(isPaused: true, onPrimaryAction: viewModel.resumeWorkout, onPauseAction: viewModel.resumeWorkout)
        case .training:
            sessionView(state: .paused, secondaryActionTitle: nil, onSecondaryAction: nil, showsEndAction: true)
        default:
            configView
        }
    }

    private var repsBinding: Binding<Int> {
        Binding(
            get: { viewModel.config.repsPerSet },
            set: { newValue in
                viewModel.config = updatedConfig(repsPerSet: newValue)
            }
        )
    }

    private var setsBinding: Binding<Int> {
        Binding(
            get: { viewModel.config.totalSets },
            set: { newValue in
                viewModel.config = updatedConfig(totalSets: newValue)
            }
        )
    }

    private var restBinding: Binding<Int> {
        Binding(
            get: { viewModel.config.restSeconds },
            set: { newValue in
                viewModel.config = updatedConfig(restSeconds: newValue)
            }
        )
    }

    private func updatedConfig(
        repsPerSet: Int? = nil,
        totalSets: Int? = nil,
        restSeconds: Int? = nil
    ) -> WorkoutConfig {
        WorkoutConfig(
            repsPerSet: repsPerSet ?? viewModel.config.repsPerSet,
            totalSets: totalSets ?? viewModel.config.totalSets,
            restSeconds: restSeconds ?? viewModel.config.restSeconds,
            countdownSeconds: viewModel.config.countdownSeconds,
            tempoCueEnabled: viewModel.config.tempoCueEnabled
        )
    }

    private func primaryActionForSessionState() {
        switch viewModel.state {
        case .countdown:
            viewModel.completeCountdown()
        case .training:
            viewModel.incrementRep()
        case .paused:
            viewModel.resumeWorkout()
        default:
            break
        }
    }

    private func settingLabel(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
        }
    }

    private func sessionTitle(for state: WorkoutState) -> String {
        switch state {
        case .countdown:
            return "准备开始"
        case .paused:
            return "已暂停"
        default:
            return "训练中"
        }
    }

    private func sessionHint(for state: WorkoutState) -> String {
        switch state {
        case .countdown:
            return "固定倒计时 3 秒，当前用按钮推进到训练态。"
        case .paused:
            return "保持当前训练进度，恢复后继续。"
        default:
            return "当前先用手动 +1 / -1 模拟主流程。"
        }
    }

    private func primaryButtonTitle(for state: WorkoutState) -> String {
        switch state {
        case .countdown:
            return "进入训练"
        case .paused:
            return "继续"
        default:
            return "模拟 +1"
        }
    }
}

#Preview {
    WatchArchitectureOverviewView()
}
