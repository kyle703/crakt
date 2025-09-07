# Enhanced Active Session Experience - Technical Roadmap & Epics

## Overview

This document outlines the implementation plan for transforming the active climbing session into a gym-optimized, gesture-based interface with proactive workout guidance. The focus is on P0 gym viability before advancing to P1 analytics features.

## Table of Contents

- [UX Critique of Current Active Session](#ux-critique-of-current-active-session)
- [Interaction Model & Flows](#interaction-model--flows)
- [Card-Only Routes Tab](#card-only-routes-tab)
- [Metrics & Instrumentation](#metrics--instrumentation)
- [Revised P0 Acceptance Criteria](#revised-p0-acceptance-criteria)
- [P0: Gym Viability](#p0-gym-viability)
- [P1: Enhanced Experience](#p1-enhanced-experience)
- [Technical Infrastructure](#technical-infrastructure)
- [Testing Strategy](#testing-strategy)
- [Risk Mitigation](#risk-mitigation)

---

## UX Critique of Current Active Session

Observed from current screenshots of the session view:

- Problem: Too many steps to log. Selecting result (Fall/Send) and then tapping "Log It!" adds an extra confirmation. In a gym, this increases time-to-log and cognitive load when pumped.
- Problem: Route switching friction. The active route card is visually dense; switching between v0/v1 lists requires precise taps on small chips or disclosure controls. No single-gesture next/previous.
- Problem: Fragmented focus. The timer, active workout card, and bottom grade chips compete for attention. Primary action is not consistently top-of-hierarchy.
- Problem: Redundant affordances. Big Fall/Send buttons plus a separate Log button creates ambiguity about state vs action. Users may tap Fall/Send expecting immediate logging.
- Problem: Progress visibility. Percent bar lacks immediate meaning during climbing; set/rep text is small relative to distance and lighting conditions.
- Problem: Undo discoverability. No clear, low-cost undo immediately after logging, which discourages aggressive one-gesture logging.
- Problem: One-handed ergonomics. Primary actions sit mid-screen or require reach. The thumb zone (bottom half) should host most interactions.
- Problem: Mode switching. "Climb On" as a central CTA suggests a mode shift, but its relationship to logging, rest timers, and routing is unclear.

Opportunities:

- Replace "select then confirm" with single-gesture logging plus haptic confirmation and a brief undo snackbar.
- Introduce horizontal paging for routes with edge swipes and large next/previous targets; support auto-advance for structured workouts.
- Elevate a persistent HUD: grade, route name, attempt count, rest timer when applicable. Keep it legible from 6+ feet.
- Consolidate primary actions into a single bottom action bar with gesture shortcuts.
- Clarify workout context (set/rep) with large tokens and progress rings rather than small text.

---

## Interaction Model & Flows

Design principles:

- One gesture to log; one gesture to switch routes. No required confirmations.
- Every action gives immediate haptic/audio feedback and a 3–5s undo affordance.
- Keep hands-in-chalk usability: large targets, high contrast, minimal text.

Primary interactions:

- Swipe up anywhere on the active route card: Log Send.
- Swipe down anywhere on the active route card: Log Fall.
- Long-press (700ms) on card: Start/stop Rest (toggles rest timer overlay).
- Double-tap card: Quick Repeat same outcome as previous attempt (with haptic).
- Edge swipe left/right (or horizontal pager): Previous/Next route.
- Long-press-and-drag on grade rail: Scrub to route; release to select.

Bottom action bar (thumb zone):

- Left button: Undo last attempt (visible for 5s after log, then moves to overflow).
- Center pill: Displays current route grade/name; tap to open Route Picker; swipe left/right to switch routes.
- Right button: Toggle Rest Timer.

Flow constraints and microcopy:

- After logging, show lightweight toast: "Send logged — v1 (Attempt 3)" with Undo.
- Auto-advance: If in a structured workout, auto-advance on successful completion of the set/rep for the route; otherwise stay and increment attempt.
- Error handling: If auto-advance target is unavailable, vibrate with warning haptic and keep user on current route with toast guidance.

Tap/gesture budgets (targets for usability):

- Log attempt: ≤1 gesture, median time-to-log ≤1.0s from screen wake.
- Switch route: ≤1 gesture, median ≤0.8s.
- Start/stop rest: ≤1 gesture.

### Grade Change & Attempt Status Details

Grade change interactions:

- Long-press on HUD grade chip → haptic tick → horizontal scrub to change; release to commit; Undo toast appears.
- Center route pill → tap → Route Picker sheet; grade rail at top; drag to filter; select route/grade.
- API impact: persists to current route instance within the session context; updates orchestrator if part of a structured workout.

Attempt status visibility:

- HUD attempt token shows A:N with S:x and F:y sublabels; tap opens Attempt History.
- Attempt History sheet: paginated list of attempts with time, outcome, route time, rest preceding; supports swipe-to-delete to correct mistakes.
- Quick Repeat: double-tap card logs the same outcome as previous attempt; counters update instantly with haptic.

---

## Card-Only Routes Tab

Single, full-screen card is the only element on the Routes tab during an active session. It "pages" horizontally to complete the route card and move onto the next active route (if free climbing keep the same grade) and vertically supports logging.

Layout:

- Top HUD: large grade chip, attempt count (A:N/S:F), small set/rep/token, compact progress ring. Tappable area opens Route Details sheet.
- Body: the swipeable card (Tinder-like). Visual states: neutral, success (green flash), fall (red flash). Shows last outcome icon subtly.
- Bottom action bar (thumb zone): Undo, Large rounded square center route pill (also route picker), Rest toggle.

Grade changes:

- Long-press the grade chip in the bottom action bar open a grade scrubber. Drag horizontally to adjust grade; release to confirm. Haptic ticks at each grade step. Undo appears for 5s.
- While active session has route attempts, lock the button (indicate it's locked with a lock icon badge) You can only change grade on a fresh route, if a user taps this button too many times, trigger the suggestion wizard helper animation for the card swipe.

Attempt status visibility:

- Attempt counter in HUD shows total attempts and send/fall split (e.g., A:3/S:1/F:2). Tap to open Attempt History sheet with a compact list (timestamp, outcome, route time, rest between attempts).
- Swipe up/down gesture feedback animates an outcome icon and increments counters immediately with haptic; Undo reverts the counter and event.

Empty/edge states:

- Choose the p25 grade difficulty to auto-populate the current route by default
- Structured workout: next route token appears ghosted on the right edge; auto-advance animates card to next on completion.

Accessibility:

- All interactive targets ≥60pt; supports VoiceOver labels for gestures via actions menu; high-contrast color tokens.

---

## Revised P0 Acceptance Criteria

- One-gesture logging for Send/Fall with immediate haptic feedback and 3–5s Undo.
- Route switching achievable with a single horizontal swipe; large on-screen next/prev targets available.
- Median time-to-log ≤1.0s; median time-to-switch ≤0.8s measured in-gym.
- Primary controls occupy thumb zone; minimum target size 60pt; contrast ratio ≥7:1.
- Auto-advance for structured workouts with clear toast and haptic confirmation.
- Rest timer accessible via one gesture (long-press or dedicated button), visible overlay with progress.

---

## Feature TODOs & Dev Criteria

1. Implement swipe logging on `ActiveRouteCard`

- Dev: Add `DragGesture` vertical detection with thresholds; map to send/fall; trigger haptic; fire `attempt_logged` event; show Undo.
- Criteria: p50 time-to-log ≤1.0s; zero-confirm logging; Undo functional within 5s; no dropped frames during animation.

2. Add horizontal pager for route switching

- Dev: Wrap card in `TabView(.page)` or custom pager; add edge-swipe areas and accessibility next/prev buttons.
- Criteria: p50 time-to-switch ≤0.8s; swipe recognition ≥95% success in testing; auto-advance integration.

3. Build top HUD with grade chip, route name, attempt token, set/rep ring

- Dev: Route HUD functionality consolidated into `UnifiedSessionHeader`; large typography; long-press on grade chip to open grade scrubber.
- Criteria: 6+ ft readability; long-press-to-scrub works with haptic ticks; updates session model immediately.

4. Grade scrubber and Route Picker

- Dev: Grade rail component with `DragGesture` snapping to grades; sheet-based Route Picker with search and rail filter.
- Criteria: Grade change in ≤2s; persistence to session; Undo available; analytics events emitted.

5. Attempt History sheet

- Dev: Lightweight list of attempts with outcome, times, and delete.
- Criteria: Opens in ≤200ms; delete updates counters and emits correction event.

6. Rest timer overlay and toggle

- Dev: Long-press to toggle; overlay with progress ring and countdown; integrates with orchestrator for rest durations.
- Criteria: Timer drift <100ms/min; auto-advance upon rest completion when configured.

7. Undo system

- Dev: Global `UndoManager`-like helper for last N actions (attempt, grade change, delete); snackbar UI.
- Criteria: Undo latency ≤150ms; correct state rollback including metrics emission.

8. Analytics wiring

- Dev: Implement event emitter and queue; add events defined in Metrics section; unit tests for payload.
- Criteria: 100% event schema conformance; sampling guards; privacy review.

9. Performance & haptics tuning

- Dev: Measure haptic start latency; optimize animations; Instruments for dropped frames and energy.
- Criteria: Haptic ≤40ms from gesture; ≤1 dropped frame per log/switch.

10. Accessibility pass

- Dev: VoiceOver actions for send/fall/switch; large targets; color-contrast checks.
- Criteria: WCAG AA contrast; full operability without gestures via actions.

---

## P0: Gym Viability (Weeks 1-6)

### Epic 1: Core Gym Interface (Week 1-2)

**Goal:** Transform the app into a usable gym tool with oversized, gesture-friendly controls

#### User Stories

**US-PO-1.1:** As a climber, I want oversized action buttons so I can log attempts with one hand while climbing
**US-PO-1.2:** As a climber, I want haptic feedback when logging attempts so I know my action was registered
**US-PO-1.3:** As a climber, I want the phone to stay awake during sessions so I don't need to unlock it repeatedly

#### Technical Tasks

**TT-PO-1.1:** Create `RouteStripView` component with always-visible route info

- Fields: route name, grade, progress bar, attempt count
- Font sizes: 28pt (primary), 20pt (secondary)
- High contrast colors for gym lighting
- Testing: Visibility from 6+ feet

**TT-PO-1.2:** Enhance action buttons for gym use

- Increase button height to 60pt minimum
- Implement full-width button layout
- Add `CoreHaptics` feedback integration
- Testing: One-handed operation in various positions

**TT-PO-1.3:** Implement iOS tab navigation

- Create `SessionTabView` with Routes/Progress/Menu tabs
- Follow iOS design guidelines for tab bar styling
- Implement state-driven content switching
- Testing: Tab switching performance and accessibility

**TT-PO-1.4:** Add auto-lock prevention

- Set `UIApplication.shared.isIdleTimerDisabled = true`
- Implement session-based activation/deactivation
- Testing: Battery impact assessment

#### Acceptance Criteria

- [ ] All buttons are 60pt+ height and full-width
- [ ] Haptic feedback works on all supported devices
- [ ] Phone stays awake during active climbing sessions
- [ ] Route strip visible from 6+ feet in gym lighting
- [ ] Tab navigation follows iOS design guidelines

#### Dependencies

- iOS 15.0+ for modern SwiftUI features
- CoreHaptics framework availability

---

### Epic 2: Route Navigation System (Week 3-4)

**Goal:** Implement seamless route selection and progression

#### User Stories

**US-PO-2.1:** As a climber, I want to automatically advance to the next route in structured workouts
**US-PO-2.2:** As a climber, I want to browse and select routes during free climbing sessions
**US-PO-2.3:** As a climber, I want to swipe between routes without tapping small buttons

#### Technical Tasks

**TT-PO-2.2:** Implement auto-advance logic

- Extend `WorkoutOrchestrator` for smart progression
- Handle different workout types (pyramid, intervals, etc.)
- Implement error handling for invalid transitions
- Testing: All workout type progressions

**TT-PO-2.3:** Add gesture navigation

- Implement swipe left/right for route navigation
- Add tap gestures for expanding route details
- Create long press menu for quick actions
- Testing: Gesture accuracy and conflict resolution

#### Acceptance Criteria

- [ ] Auto-advance works for all workout types
- [ ] Route picker loads in <2 seconds with 100 routes
- [ ] Swipe gestures work reliably in gym conditions
- [ ] Route cards show all essential information
- [ ] Search filters work across grade, name, and status

#### Dependencies

- WorkoutOrchestrator state management
- Route data model with status tracking

---

### Epic 3: Voice & Sensor Integration (Week 5-6)

**Goal:** Add voice-activated logging and proximity features

#### User Stories

**US-PO-3.1:** As a climber, I want to log attempts using voice commands
**US-PO-3.2:** As a climber, I want the phone to wake when I approach during climbing
**US-PO-3.3:** As a climber, I want multi-modal feedback for all actions

#### Technical Tasks

**TT-PO-3.1:** Implement voice command system

- Create `VoiceCommandManager` using Speech framework
- Define climbing vocabulary: "Send!", "Fall!", "Rest!"
- Handle audio session management for gym noise
- Testing: Recognition accuracy in noisy environments

**TT-PO-3.2:** Add proximity detection

- Implement device motion detection for auto-wake
- Optional camera-based proximity sensing
- Battery optimization for continuous monitoring
- Testing: Battery drain assessment

**TT-PO-3.3:** Create enhanced feedback system

- Implement multi-modal feedback (haptic + audio + visual)
- Create custom vibration patterns per action
- Add audio confirmation for voice commands
- Testing: Feedback timing and user preference

#### Acceptance Criteria

- [ ] Voice commands work in typical gym noise levels
- [ ] Proximity detection activates within 2 seconds
- [ ] Multi-modal feedback provides clear confirmation
- [ ] Battery drain <5% per hour during sessions
- [ ] Microphone permission handling is user-friendly

#### Dependencies

- Speech framework for voice recognition
- CoreMotion for proximity detection
- CoreHaptics for advanced feedback

---

## P1: Enhanced Experience (Weeks 7-12)

### Epic 4: Proactive Workout Guidance (Week 7-8)

**Goal:** Add intelligent workout progression and guidance

#### User Stories

**US-P1-4.1:** As a climber, I want to see suggested grades for my next climb
**US-P1-4.2:** As a climber, I want visual rest timers during workout breaks
**US-P1-4.3:** As a climber, I want real-time performance feedback

#### Technical Tasks

**TT-P1-4.1:** Build grade suggestion engine

- Create `GradeSuggestionEngine` with rule-based logic
- Implement workout type-specific algorithms
- Add performance-based grade adjustments
- Testing: Suggestion accuracy against user performance

**TT-P1-4.2:** Implement rest timer integration

- Create `RestTimerView` with progress rings
- Configure durations by workout type and intensity
- Add completion notifications and auto-advance
- Testing: Timer accuracy and battery impact

**TT-P1-4.3:** Add performance context display

- Build `PerformanceContextView` for live metrics
- Implement real-time send rate calculations
- Create motivational feedback system
- Testing: Metric calculation performance

#### Acceptance Criteria

- [ ] Grade suggestions match user's current performance level
- [ ] Rest timer visually shows remaining time clearly
- [ ] Performance feedback appears at appropriate moments
- [ ] Live metrics update without UI lag
- [ ] Motivational messages are encouraging and accurate

#### Dependencies

- Enhanced WorkoutOrchestrator
- Real-time performance tracking data

---

### Epic 5: Advanced Metrics (Week 9-10)

**Goal:** Implement comprehensive climbing analytics

#### User Stories

**US-P1-5.1:** As a climber, I want to track detailed performance metrics
**US-P1-5.2:** As a climber, I want to see performance trends over time
**US-P1-5.3:** As a climber, I want personalized coaching insights

#### Technical Tasks

**TT-P1-5.1:** Create metrics collection engine

- Build `MetricsCollector` for hang time tracking
- Implement fall location categorization
- Add movement quality rating storage
- Testing: Metric accuracy and storage efficiency

**TT-P1-5.2:** Develop analytics dashboard

- Create `AnalyticsDashboardView` with charts
- Implement comparative analysis features
- Add data export capabilities
- Testing: Chart rendering performance

**TT-P1-5.3:** Build insight engine

- Develop `InsightEngine` for pattern recognition
- Create personalized recommendations
- Implement goal progress tracking
- Testing: Insight relevance and accuracy

## Metrics & Instrumentation

Goals: Quantify friction, learning curve, and workout effectiveness. All events include `sessionId`, `routeId`, `workoutId?`, `timestamp`, `appVersion`, `device`.

Core events:

- session_start, session_end
- route_viewed, route_switched {fromRouteId, toRouteId, method: swipe|picker|auto}
- attempt_logged {outcome: send|fall, attemptIndex, timeToLogMs, gesture: swipeUp|swipeDown|tap, autoAdvance: bool}
- undo_used {eventIdUndone, timeSinceEventMs}
- rest_started {source: auto|manual}, rest_ended {durationMs}
- workout_auto_advanced {reason: setComplete|timerComplete|rule}, auto_advance_blocked {reason}

Friction metrics (computed):

- TTR (time-to-record): From attempt outcome decision to confirmed log; target p50 ≤1.0s, p95 ≤2.0s.
- TTS (time-to-switch): From intent (first gesture) to next route visible; target p50 ≤0.8s.
- Taps/Gestures per Attempt: target mean ≤1.2.
- Undo rate: healthy range 3–10%; spikes suggest gesture confusion.
- Navigation method mix: swipe dominance ≥70% for mature users; lower implies discoverability issues.

Performance & reliability:

- Haptic latency: time from gesture recognition to haptic begin; target ≤40ms.
- UI frame drops during log/switch: target ≤1 dropped frame (60Hz baseline).
- Battery per hour during active session: ≤5%.

Payload shape examples:

```json
{
  "type": "attempt_logged",
  "sessionId": "s_123",
  "routeId": "r_456",
  "workoutId": "w_789",
  "attemptIndex": 3,
  "outcome": "send",
  "gesture": "swipeUp",
  "timeToLogMs": 620,
  "autoAdvance": true
}
```

---

#### Acceptance Criteria

- [ ] All metrics collected accurately and efficiently
- [ ] Analytics dashboard loads in <3 seconds
- [ ] Insights provide actionable coaching advice
- [ ] Data export works for common formats
- [ ] Privacy controls are clearly accessible

#### Dependencies

- Extended data models for detailed metrics
- Chart rendering libraries (SwiftUI Charts)

---

### Epic 6: Advanced Features (Week 11-12)

**Goal:** Add premium features and integrations

#### User Stories

**US-P1-6.1:** As a climber, I want to use pre-built workout templates
**US-P1-6.2:** As a climber, I want to share my sessions with others
**US-P1-6.3:** As a climber, I want to customize the app experience

#### Technical Tasks

**TT-P1-6.1:** Implement workout templates

- Create `WorkoutTemplateManager` for pre-built configs
- Build custom workout builder interface
- Add template sharing and import features
- Testing: Template application and customization

**TT-P1-6.2:** Add social features

- Develop `SocialIntegrationManager`
- Implement session sharing capabilities
- Add performance comparison features
- Testing: Social feature privacy and performance

**TT-P1-6.3:** Create customization options

- Add theme customization
- Implement custom grading system support
- Enhance accessibility features
- Testing: Customization persistence and performance

#### Acceptance Criteria

- [ ] Workout templates cover major climbing disciplines
- [ ] Social sharing respects user privacy preferences
- [ ] Customization options don't impact core performance
- [ ] Accessibility features meet WCAG guidelines
- [ ] All features work offline when possible

#### Dependencies

- Cross-device synchronization infrastructure
- Social platform API integrations

---

## Technical Infrastructure

### Development Environment

- **Xcode:** 15.x (latest stable)
- **iOS Target:** iOS 15.0+
- **Swift Version:** 5.9+
- **Package Manager:** Swift Package Manager

### Key Dependencies

- **Speech:** Voice command recognition
- **CoreHaptics:** Advanced tactile feedback
- **CoreMotion:** Proximity detection
- **SwiftUI:** Modern UI implementation
- **Combine:** Reactive state management

### Architecture Patterns

- **MVVM:** For UI state management
- **Repository Pattern:** For data access
- **Observer Pattern:** For workout state changes
- **Factory Pattern:** For workout type creation

---

## Testing Strategy

### Unit Testing

- **Coverage Target:** 80%+ code coverage
- **Focus Areas:** Core logic, algorithms, state management
- **Tools:** XCTest framework with Swift Testing (future)

### UI Testing

- **Coverage:** Critical user flows and gesture interactions
- **Tools:** Xcode UI Testing framework
- **Test Data:** Mock workout sessions and route data

### Integration Testing

- **Scope:** End-to-end workout scenarios
- **Focus:** State transitions and data persistence
- **Environment:** Simulated gym conditions

### Performance Testing

- **Metrics:** UI response times (<100ms), memory usage, battery drain
- **Tools:** Xcode Instruments, custom performance monitoring
- **Thresholds:** <5% battery drain per hour, <2s app launch

### User Testing

- **Method:** In-gym testing sessions with real climbers
- **Metrics:** Task completion rates, error rates, satisfaction scores
- **Sample Size:** 20+ climbers across different experience levels

---

## Risk Mitigation

### Technical Risks

**Risk:** Voice recognition accuracy in noisy gyms
**Mitigation:** Fallback to manual controls, noise filtering algorithms

**Risk:** Battery drain from proximity detection
**Mitigation:** Feature flags for optional features, battery monitoring

**Risk:** Performance issues with large route lists
**Mitigation:** Lazy loading, pagination, memory optimization

### Product Risks

**Risk:** Feature complexity reduces usability
**Mitigation:** Progressive disclosure, user testing, feature flags

**Risk:** iOS compatibility issues
**Mitigation:** Regular testing on target iOS versions, graceful degradation

### Timeline Risks

**Risk:** Dependencies delay implementation
**Mitigation:** Parallel development tracks, MVP-first approach

---

## Success Metrics

### P0 Success Criteria (End of Week 6)

- [ ] 95%+ users can log attempts one-handed in gym
- [ ] Voice commands work in typical gym noise
- [ ] App maintains <5% battery drain per hour
- [ ] All UI elements visible from 6+ feet
- [ ] Tab navigation response time <100ms

### P1 Success Criteria (End of Week 12)

- [ ] 80%+ user engagement with enhanced features
- [ ] Analytics dashboard provides actionable insights
- [ ] Grade suggestions improve with usage
- [ ] Social features increase user retention

### Overall Project Success

- [ ] User satisfaction score >4.5/5 in gym testing
- [ ] Session completion rate increases by 50%
- [ ] App store rating improves to 4.5+ stars
- [ ] User acquisition through word-of-mouth

---

## Implementation Notes

### Code Organization

```
/Views/Session/
  ├── RouteStripView.swift
  ├── SessionTabView.swift
  ├── RoutePickerView.swift
  └── RestTimerView.swift

/Models/
  ├── VoiceCommandManager.swift
  ├── GradeSuggestionEngine.swift
  └── MetricsCollector.swift

/ViewModels/
  ├── SessionViewModel.swift
  └── WorkoutViewModel.swift
```

### Version Control Strategy

- **Branching:** Feature branches for each epic
- **Pull Requests:** Code review for all changes
- **Release:** Weekly releases for P0, bi-weekly for P1

### Documentation

- **API Documentation:** Inline code documentation
- **User Documentation:** In-app help and onboarding
- **Technical Documentation:** This roadmap and implementation guides

---

_Last Updated: [Current Date]_
_Document Owner: Product Team_
_Review Cycle: Weekly during active development_
