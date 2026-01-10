# Pixel Pal - iOS Fitness Companion

A pixel art fitness companion app that displays an animated character in the Dynamic Island and Lock Screen based on your daily step count.

## Project Structure

```
PixelPalFit/
├── PixelPal/                          # Main iOS App Target
│   ├── Sources/
│   │   ├── App/
│   │   │   └── PixelPalApp.swift      # App entry point, scene setup
│   │   ├── Core/
│   │   │   ├── AvatarState.swift      # Energy states (vital/neutral/low), Gender enum
│   │   │   ├── HealthKitManager.swift # HealthKit step count queries
│   │   │   ├── LiveActivityManager.swift # Live Activity lifecycle, walking animation
│   │   │   ├── PixelPalAttributes.swift  # ActivityKit attributes & content state
│   │   │   ├── SharedData.swift       # App Group UserDefaults for widget communication
│   │   │   └── SpriteAssets.swift     # Centralized sprite naming helpers
│   │   └── Views/
│   │       ├── AvatarView.swift       # Animated pixel character view
│   │       ├── ContentView.swift      # Main app UI with step count display
│   │       ├── OnboardingView.swift   # Gender selection onboarding
│   │       └── SpriteTestView.swift   # Debug view for testing sprites
│   ├── Resources/
│   │   ├── Assets.xcassets/           # 76 sprite imagesets
│   │   ├── Info.plist
│   │   └── PrivacyInfo.xcprivacy
│   └── PixelPal.entitlements
│
├── PixelPalWidget/                    # Widget Extension Target
│   ├── Sources/
│   │   ├── PixelPalLiveActivity.swift # Dynamic Island & Lock Screen UI
│   │   └── PixelPalWidget.swift       # Home Screen widget
│   ├── Resources/
│   │   ├── Info.plist
│   │   └── PrivacyInfo.xcprivacy
│   └── PixelPalWidget.entitlements
│
├── PixelPalTests/                     # Unit Tests
│   ├── AvatarStateTests.swift
│   └── SpriteAssetsTests.swift
│
├── demo/
│   └── iphone-simulator.html          # Browser-based iPhone simulator
│
├── project.yml                        # XcodeGen configuration
└── CLAUDE.md                          # AI agent instructions
```

## Core Components

### Data Models

**Gender** (`AvatarState.swift`)
- `male` | `female`
- Stored in App Group UserDefaults

**AvatarState** (`AvatarState.swift`)
- `vital` (7500+ steps)
- `neutral` (2000-7499 steps)
- `low` (0-1999 steps)

### Managers

**HealthKitManager** - Queries HealthKit for daily step count
- Uses `HKStatisticsQuery` with `cumulativeSum`
- Requests read access to `stepCount`

**LiveActivityManager** - Controls Live Activity lifecycle
- Starts/stops Live Activities
- Manages walking animation timer (32 frames @ 24fps)
- Detects walking state from step count changes

**SharedData** - App Group communication
- Shares state between app and widget extension
- Uses `group.com.pixelpal.shared` suite

### Sprite System

**Asset Naming Convention:**
- State sprites: `{gender}_{state}_{frame}` (e.g., `male_vital_1`)
- Walking sprites: `{gender}_walking_{frame}` (e.g., `female_walking_24`)

**Asset Counts:**
- State sprites: 12 (2 genders × 3 states × 2 frames)
- Walking sprites: 64 (2 genders × 32 frames)
- Total: 76 imagesets

### Animation Settings

| Animation | Frames | FPS | Interval |
|-----------|--------|-----|----------|
| Walking   | 32     | 24  | 42ms     |
| Idle/State| 2      | ~1  | 600-1000ms |

## Live Activity Views

**Dynamic Island Compact:** Step count centered with walking sprite
**Dynamic Island Expanded:** Larger sprite with centered step count
**Lock Screen:** Full Live Activity banner with sprite and steps

## Build & Run

```bash
# Generate Xcode project
xcodegen generate

# Open in Xcode
open PixelPal.xcodeproj

# Build (requires signing in Xcode)
xcodebuild -scheme PixelPal -destination 'generic/platform=iOS'
```

## Browser Demo

```bash
# Start local server
python3 -m http.server 8000

# Open demo
open http://localhost:8000/demo/iphone-simulator.html
```

## Entitlements

- HealthKit
- App Groups (`group.com.pixelpal.shared`)
- Live Activities (Push to Talk capability)

## Key Files Reference

| File | Purpose |
|------|---------|
| `LiveActivityManager.swift` | Animation timing, frame cycling |
| `SpriteAssets.swift` | Frame count constants, asset naming |
| `PixelPalLiveActivity.swift` | Dynamic Island layout |
| `PixelPalAttributes.swift` | Live Activity data model |

---

# PixelPal – Project Specification (v1.1)

## 1. Product Overview

PixelPal is a step-based identity reinforcement app that turns real-world movement into a living pixel character visible in the iOS Dynamic Island and Lock Screen.

PixelPal is NOT a fitness tracker.
PixelPal is NOT a habit nag.
PixelPal is an ambient identity system.

Movement creates visible growth.
Inaction creates stillness, not punishment.

---

## 2. Core Philosophy

PixelPal follows four rules:

1. Visibility beats notifications
2. Pride beats guilt
3. Progress beats streaks
4. Identity beats metrics

If a feature violates one of these, it does not ship.

---

## 3. Core Psychological Loop

Trigger:
User walks naturally

Action:
Steps increment via HealthKit

Reward:
Character animates and evolves

Reinforcement:
Character is visible all day

Identity Shift:
"I am someone who moves"

No shame.
No streak anxiety.
No punishment mechanics.

---

## 4. Onboarding Flow (90 seconds max)

### Screen 1: Identity Hook
Title:
Your steps tell a story

Subtitle:
PixelPal turns movement into a living character you see all day.

Visual:
Idle pixel character
Dynamic Island mock

CTA:
Start my PixelPal

---

### Screen 2: Character Selection
Title:
Choose your PixelPal

Options:
- Gender: Male / Female
- Starter palette or outfit

Copy:
This character grows when you move.

Selection is permanent for v1.

---

### Screen 3: Truth Moment
Title:
Most people walk less than they think

Content:
- Average daily steps benchmark
- Estimated personal range (soft range, not accusation)

Copy:
PixelPal shows the truth in real time.

---

### Screen 4: Differentiation
Title:
This isn't another step counter

Bullets:
- Evolves as you walk
- Lives in Dynamic Island and Lock Screen
- Motivation without notifications

---

### Screen 5: Permissions
Title:
Let PixelPal walk with you

Requirement:
HealthKit step access

Copy:
We only use steps to evolve your character.
No data leaves your device.

CTA:
Enable steps

---

## 5. Evolution System (CRITICAL)

Evolution is cumulative.
It never resets.
It never reverses.

### Evolution Phases

Phase 1: Dormant
Steps: 0 to 25,000
State:
- Idle animation
- Minimal expression
- Slow blink
Message:
"This is the beginning."

Phase 2: Active
Steps: 25,001 to 75,000
State:
- More frequent movement
- Subtle bounce
- Brighter palette
Message:
"Movement is becoming part of you."

Phase 3: Energized
Steps: 75,001 to 200,000
State:
- Dynamic idle animation
- Expressive reactions
- Confident posture
Message:
"This is momentum."

Phase 4: Ascended (Premium)
Steps: 200,001+
State:
- Rare animations
- Glow effects
- Expanded sprite frames
Message:
"You've changed."

Rules:
- Evolution triggers instantly when threshold crossed
- No countdown timers
- No streak dependency
- User cannot rush evolution without movement

---

## 6. Dynamic Island Behavior (v1)

Dynamic Island is passive and ambient.

### States

Idle:
- Character peeks occasionally
- Minimal animation

Walking Detected:
- Character animates immediately
- Small bounce or run cycle

Evolution Trigger:
- Brief highlight animation
- Visual flourish only

Rules:
- No text in Dynamic Island
- No alerts
- No notifications
- Character presence is the signal

---

## 7. Lock Screen Widget Behavior

Displays:
- Current character state
- Phase indicator (icon only)
- No numbers

Behavior:
- Updates when steps change meaningfully
- Shows evolution visually, not numerically

Goal:
User checks lock screen and sees identity progress, not metrics.

---

## 8. Monetization Strategy

PixelPal monetizes aspiration, not fear.

### Free Tier
- Live step tracking
- Phase 1 and Phase 2
- Dynamic Island presence
- Base character

### Premium Tier
- Phase 3 and Phase 4
- Lock Screen widgets
- Progress history
- Seasonal skins
- Animation effects
- Multiple characters

Premium is about expansion, not restriction.

---

## 9. Paywall Placement and Design

### Timing
- First shown after Phase 2 unlock
- Never shown during onboarding

User must feel momentum first.

---

### Paywall Copy

Title:
Your PixelPal is evolving

Subtitle:
Unlock what this character can become.

Bullets:
- Advanced evolutions
- Exclusive pixel skins
- Full progress history

CTA:
Unlock PixelPal

Tone:
Calm
Confident
Aspirational

No guilt language.
No urgency tricks.

---

## 10. Retention Loops

### Week 1
- Curiosity driven
- Character animation novelty
- First evolution milestone

### Week 4
- Anticipation of next phase
- Lock Screen presence reinforces habit
- Pride-based reinforcement

### Week 12
- Identity solidified
- Character feels personal
- Evolution completion becomes status

Retention is passive, not forced.

---

## 11. Technical Stack

Platform:
iOS only

Framework:
SwiftUI

APIs:
- HealthKit (steps)
- ActivityKit (Dynamic Island)
- WidgetKit (Lock Screen)

Data:
- On-device only
- No backend required for v1

---

## 12. Explicit Non-Goals

PixelPal will not:
- Track calories
- Track weight
- Shame inactivity
- Use streak resets
- Block apps
- Compete with fitness trackers

---

## 13. Success Metrics

Early:
- Onboarding completion rate
- HealthKit permission acceptance
- Phase 2 unlock rate

Mid:
- Daily Dynamic Island impressions
- Lock Screen widget usage

Long:
- Free to paid conversion
- Character attachment
- Low churn

---

## 14. Final Product Principle

PixelPal does not nag.
PixelPal does not judge.
PixelPal waits.

If the user moves, PixelPal grows.
If they don't, PixelPal stays.

That restraint is the advantage.

---

## 15. Implementation Addendum (Required for Claude)

### iOS Targets
- Minimum iOS version: iOS 17.0 (preferred) or iOS 16.2 minimum if required.
- Live Activities enabled (ActivityKit) with Dynamic Island support.
- WidgetKit Lock Screen widget supported.

### Data Model
Persist on device using AppStorage + Codable JSON in Application Support.

Entities:
- UserProfile
  - selectedGender: male|female
  - selectedStarterStyle: string
  - createdAt: Date
- ProgressState
  - totalStepsSinceStart: Int
  - lastHealthKitSync: Date
  - currentPhase: Int (1-4)
  - hasSeenPaywall: Bool
- Entitlements
  - isPremium: Bool
  - premiumSince: Date?

Evolution calculation:
- totalStepsSinceStart drives phase thresholds.
- Phase thresholds:
  - Phase 1: 0-25000
  - Phase 2: 25001-75000
  - Phase 3: 75001-200000 (Premium)
  - Phase 4: 200001+ (Premium)

### HealthKit Strategy
- Request read permission for step count.
- Use StatisticsQuery for daily steps and anchor queries for updates.
- Define totalStepsSinceStart as:
  - Sum of daily steps from UserProfile.createdAt to now.
- Cache computed totals to avoid re-summing too often.
- Refresh cadence:
  - Foreground: on app open + every 30-60 seconds while active
  - Background: best effort using background refresh, but never promise real time.

### Live Activity UI Rules
- Default (Idle): character only, no step numbers.
- On-demand: step count shown only in expanded view or during active walking state.
- Milestones: brief step text allowed (eg "5k!") for 3-5 seconds, then revert to character-only.
- Never show guilt messages or warnings in the Dynamic Island.
- Update Live Activity when:
  - walking state changes
  - phase changes
  - at most once every few minutes to avoid update throttling

### Widget Rules
- Lock Screen widget shows:
  - character sprite + phase icon
  - no numbers
- Widget timeline updates:
  - at reasonable cadence (eg every 1-4 hours) plus manual refresh triggers

### Monetization
Use StoreKit 2 subscriptions.
Products:
- com.pixelpal.premium.monthly
- com.pixelpal.premium.yearly

Premium unlocks:
- Phase 3 and Phase 4
- Lock Screen widget
- Progress history
- Skins and effects

Free tier:
- Phase 1 and Phase 2
- Dynamic Island Live Activity

Paywall trigger:
- Show after Phase 2 unlock event, not before.

