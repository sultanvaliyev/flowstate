import SwiftUI

/// The main focus timer view displayed in the FocusPanel window
/// Features a circular progress ring, tree growth visualization, timer display, and controls
struct FocusView: View {
    @ObservedObject var timerState: FocusTimerState
    @ObservedObject var spotifyManager: SpotifyManager

    /// Selected duration in minutes for the duration picker
    @State private var selectedMinutes: Int = 25

    /// Whether to show the history popover
    @State private var showHistory: Bool = false

    /// Height of the title bar area to avoid overlapping with window controls
    private let titleBarHeight: CGFloat = 28

    var body: some View {
        GeometryReader { geometry in
            let sizeClass = LayoutSizeClass.from(size: geometry.size)

            ZStack {
                AppColors.forestGreen
                    .ignoresSafeArea()

                if sizeClass.isCompact {
                    compactLayout
                } else {
                    regularLayout
                }
            }
        }
        .frame(minWidth: 220, maxWidth: 400, minHeight: 280, maxHeight: 700)
        .onAppear {
            selectedMinutes = timerState.targetDurationSeconds / 60
            spotifyManager.startPolling()
        }
        .onDisappear {
            spotifyManager.stopPolling()
        }
    }

    // MARK: - Layout Variants

    private var compactLayout: some View {
        VStack(spacing: 16) {
            timerSection

            // Minimal control button
            compactControlButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, titleBarHeight + 8)
        .padding(.bottom, 16)
    }

    private var compactControlButton: some View {
        Group {
            switch timerState.timerPhase {
            case .idle, .completed, .cancelled:
                Button(action: { timerState.start() }) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AppColors.buttonGreen))
                }
                .buttonStyle(.plain)
            case .running:
                Button(action: { timerState.pause() }) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textOnGreen)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                }
                .buttonStyle(.plain)
            case .paused:
                Button(action: { timerState.resume() }) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AppColors.buttonGreen))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var regularLayout: some View {
        VStack(spacing: 20) {
            headerSection
            Spacer()
            timerSection
            Spacer()
            if !timerState.timerPhase.isActive {
                durationSection
            }
            controlSection
            SpotifyPlayerView(spotifyManager: spotifyManager, isCompact: true)
                .padding(.top, 8)
            motivationalSection
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 20)
        .padding(.top, titleBarHeight + 8)
        .padding(.bottom, 16)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            // Session label editor
            SessionLabelEditor(label: $timerState.sessionLabel)
                .disabled(timerState.timerPhase.isActive)

            Spacer()

            // History button
            Button(action: { showHistory.toggle() }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppColors.textOnGreen)
            }
            .buttonStyle(.plain)
            .help("View session history")
            .popover(isPresented: $showHistory, arrowEdge: .bottom) {
                HistoryView()
                    .frame(width: 280, height: 360)
            }
        }
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        ZStack {
            // Progress ring
            CircularProgressRing(
                progress: timerState.progress,
                ringColor: AppColors.ringGreen,
                lineWidth: 14,
                size: 200
            )

            // Center content
            VStack(spacing: 8) {
                // Tree growth visualization
                TreeGrowthView(progress: timerState.progress, size: 50)

                // Time display
                Text(timerState.formattedRemaining)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textOnGreen)
                    .monospacedDigit()

                // Phase indicator
                if timerState.timerPhase == .paused {
                    Text("PAUSED")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.warning)
                }
            }
        }
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        DurationPicker(
            selectedMinutes: $selectedMinutes,
            textColor: AppColors.textOnGreen
        )
        .onChange(of: selectedMinutes) { oldValue, newValue in
            timerState.setDuration(newValue * 60)
        }
    }

    // MARK: - Control Section

    private var controlSection: some View {
        HStack(spacing: 24) {
            switch timerState.timerPhase {
            case .idle, .completed, .cancelled:
                // Start button
                startButton

            case .running:
                // Pause and Cancel buttons
                pauseButton
                cancelButton

            case .paused:
                // Resume and Cancel buttons
                resumeButton
                cancelButton
            }
        }
    }

    private var startButton: some View {
        Button(action: {
            timerState.start()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 16))
                Text("Plant")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(AppColors.buttonGreen)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var pauseButton: some View {
        Button(action: {
            timerState.pause()
        }) {
            Image(systemName: "pause.fill")
                .font(.system(size: 20))
                .foregroundColor(AppColors.textOnGreen)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                )
        }
        .buttonStyle(.plain)
        .help("Pause session")
    }

    private var resumeButton: some View {
        Button(action: {
            timerState.resume()
        }) {
            Image(systemName: "play.fill")
                .font(.system(size: 20))
                .foregroundColor(AppColors.textOnGreen)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(AppColors.buttonGreen)
                )
        }
        .buttonStyle(.plain)
        .help("Resume session")
    }

    private var cancelButton: some View {
        Button(action: {
            timerState.cancel()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.buttonCancel)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
        .help("Cancel session")
    }

    // MARK: - Motivational Section

    private var motivationalSection: some View {
        Text(timerState.motivationalText)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(AppColors.textOnGreenSecondary)
            .multilineTextAlignment(.center)
            .animation(.easeInOut, value: timerState.motivationalText)
    }
}

// MARK: - Preview

#Preview("Focus View - Idle") {
    let mockService = MockSpotifyService.playing()
    let spotifyManager = SpotifyManager(service: mockService)
    return FocusView(timerState: FocusTimerState(), spotifyManager: spotifyManager)
}

#Preview("Focus View - Running") {
    let state = FocusTimerState()
    state.setDuration(1500)
    let mockService = MockSpotifyService.playing()
    let spotifyManager = SpotifyManager(service: mockService)
    return FocusView(timerState: state, spotifyManager: spotifyManager)
}

#Preview("Focus View - Spotify Disconnected") {
    let mockService = MockSpotifyService.disconnected()
    let spotifyManager = SpotifyManager(service: mockService)
    return FocusView(timerState: FocusTimerState(), spotifyManager: spotifyManager)
}
