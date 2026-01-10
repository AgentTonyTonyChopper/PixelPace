import ActivityKit
import SwiftUI
import WidgetKit

/// Live Activity configuration for Pixel Pal.
/// Displays an animated sprite on Lock Screen and Dynamic Island.
///
/// UI Rules (v1.1):
/// - Default (Idle): character only, no step numbers
/// - On-demand: step count shown only in expanded view OR during active walking state
/// - Milestones: brief step text allowed (e.g., "5k!") for 3-5 seconds
/// - Never show guilt messages or warnings
struct PixelPalLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PixelPalAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }
            } compactLeading: {
                // Compact Leading: Mini sprite
                CompactLeadingView(context: context)
            } compactTrailing: {
                // Compact Trailing: Context-aware display
                CompactTrailingView(context: context)
            } minimal: {
                // Minimal: Tiny sprite only
                MinimalView(context: context)
            }
        }
    }
}

// MARK: - Lock Screen View

private struct LockScreenView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    private var spriteName: String {
        if context.state.isWalking {
            return SpriteAssets.walkingSpriteName(
                genderRaw: context.state.genderRaw,
                frame: context.state.walkingFrame
            )
        } else {
            return SpriteAssets.spriteName(
                genderRaw: context.state.genderRaw,
                stateRaw: context.state.stateRaw,
                frame: 1
            )
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            if let uiImage = UIImage(named: spriteName) {
                Image(uiImage: uiImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: context.state.isWalking ? 80 : 50,
                           height: context.state.isWalking ? 80 : 50)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Show milestone if celebrating, otherwise show step count (allowed on Lock Screen)
                if let milestone = context.state.milestoneText {
                    Text(milestone)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                } else if context.state.showStepCount || context.state.isWalking {
                    Text("\(context.state.steps) steps")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                // Phase indicator (visual, not metrics)
                PhaseIndicatorView(phase: context.state.currentPhase)
            }

            Spacer()
        }
        .padding()
        .activityBackgroundTint(.black)
    }
}

// MARK: - Phase Indicator

private struct PhaseIndicatorView: View {
    let phase: Int

    private var phaseColor: Color {
        switch phase {
        case 1: return .gray
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        default: return .gray
        }
    }

    private var phaseIcon: String {
        switch phase {
        case 1: return "circle"
        case 2: return "circle.fill"
        case 3: return "star.fill"
        case 4: return "sparkles"
        default: return "circle"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: phaseIcon)
                .font(.caption2)
                .foregroundColor(phaseColor)
            Text("Phase \(phase)")
                .font(.caption2)
                .foregroundColor(phaseColor.opacity(0.8))
        }
    }
}

// MARK: - Dynamic Island Expanded Views

private struct ExpandedLeadingView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    var body: some View {
        // Show sprite on leading side always
        let spriteName = context.state.isWalking
            ? SpriteAssets.walkingSpriteName(
                genderRaw: context.state.genderRaw,
                frame: context.state.walkingFrame
            )
            : SpriteAssets.spriteName(
                genderRaw: context.state.genderRaw,
                stateRaw: context.state.stateRaw,
                frame: 1
            )

        if let uiImage = UIImage(named: spriteName) {
            Image(uiImage: uiImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        }
    }
}

private struct ExpandedTrailingView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    var body: some View {
        // Expanded view: step count is allowed per UI rules
        VStack(alignment: .trailing, spacing: 2) {
            if let milestone = context.state.milestoneText {
                // Milestone celebration
                Text(milestone)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            } else {
                // Step count (allowed in expanded view)
                Text("\(context.state.steps)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("steps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct ExpandedCenterView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    var body: some View {
        // Phase indicator only (no state text per UI rules)
        PhaseIndicatorView(phase: context.state.currentPhase)
    }
}

private struct ExpandedBottomView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    private var walkingSpriteName: String {
        SpriteAssets.walkingSpriteName(
            genderRaw: context.state.genderRaw,
            frame: context.state.walkingFrame
        )
    }

    var body: some View {
        if context.state.isWalking {
            // Large walking animation covering most of the expanded island
            if let uiImage = UIImage(named: walkingSpriteName) {
                Image(uiImage: uiImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .offset(y: -36) // Raise up to prevent cutoff
            }
        } else {
            // No text per UI rules - just empty or subtle visual
            EmptyView()
        }
    }
}

// MARK: - Dynamic Island Compact Views

private struct CompactLeadingView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    private var spriteName: String {
        if context.state.isWalking {
            return SpriteAssets.walkingSpriteName(
                genderRaw: context.state.genderRaw,
                frame: context.state.walkingFrame
            )
        } else {
            return SpriteAssets.spriteName(
                genderRaw: context.state.genderRaw,
                stateRaw: context.state.stateRaw,
                frame: 1
            )
        }
    }

    var body: some View {
        if let uiImage = UIImage(named: spriteName) {
            Image(uiImage: uiImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
    }
}

private struct CompactTrailingView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    var body: some View {
        // UI Rules:
        // - Idle: character only (no step count)
        // - Walking: step count allowed
        // - Milestone: brief text like "5k!"
        if let milestone = context.state.milestoneText {
            // Milestone celebration (3-5 seconds)
            Text(milestone)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.green)
        } else if context.state.isWalking || context.state.showStepCount {
            // Walking state: show step count
            Text("\(context.state.steps)")
                .font(.caption)
                .fontWeight(.semibold)
        } else {
            // Idle: just show phase icon (character presence is the signal)
            Image(systemName: phaseIcon(for: context.state.currentPhase))
                .font(.caption)
                .foregroundColor(phaseColor(for: context.state.currentPhase))
        }
    }

    private func phaseIcon(for phase: Int) -> String {
        switch phase {
        case 1: return "circle"
        case 2: return "circle.fill"
        case 3: return "star.fill"
        case 4: return "sparkles"
        default: return "circle"
        }
    }

    private func phaseColor(for phase: Int) -> Color {
        switch phase {
        case 1: return .gray
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        default: return .gray
        }
    }
}

// MARK: - Dynamic Island Minimal View

private struct MinimalView: View {
    let context: ActivityViewContext<PixelPalAttributes>

    private var spriteName: String {
        if context.state.isWalking {
            return SpriteAssets.walkingSpriteName(
                genderRaw: context.state.genderRaw,
                frame: context.state.walkingFrame
            )
        } else {
            return SpriteAssets.spriteName(
                genderRaw: context.state.genderRaw,
                stateRaw: context.state.stateRaw,
                frame: 1
            )
        }
    }

    var body: some View {
        if let uiImage = UIImage(named: spriteName) {
            Image(uiImage: uiImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
        }
    }
}
