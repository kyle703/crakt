# Tech Spec — Global Sessions View

## Context
The Global Sessions View is a new **analytics dashboard** that aggregates all user sessions into one view.  
Focus: **local-first analytics** (no backend dependency in v1).  
Purpose: provide the climber with **progression, volume, efficiency, and distribution insights** across sessions.

---

## Data Model

### Session (existing)
- `id: UUID`
- `startDate: Date`
- `endDate: Date?`
- `routes: [Route]`
- `elapsedTime: Int` (seconds)
- `highestGradeSent: String?`

### Required Additions
- `hardestGradeDI: Int` — DI-normalized hardest send.  
- `medianGradeDI: Int` — DI-normalized median send.  
- `sendCount: Int` — total sends in session.  
- `attemptCount: Int` — total attempts in session.  
- `sendPercent: Double` — sendCount ÷ attemptCount.  
- `attemptsPerSend: Double` — attemptCount ÷ max(1, sendCount).  

### Utility Functions
- `Session.computeSummaryMetrics() -> SessionSummary`  
- `SessionSummary` struct (hardestGradeDI, medianGradeDI, sendCount, attemptCount, sendPercent, attemptsPerSend).

---

## Local Analytics (Aggregations)

### Progression
- **Hardest Grade Trend**: max DI per session.  
- **Median Grade Trend**: median DI per session.  
- **PR Detection**: detect when session’s hardestGradeDI exceeds all previous sessions.

### Volume & Efficiency
- **Weekly Volume**: sum of attempts/sends grouped by week.  
- **Send % Over Time**: rolling average of sendPercent.  
- **Attempts per Send Trend**: smoothed line chart across sessions.

### Distribution
- **Grade Distribution**: histogram of sends grouped by DI bands.  
- Bands: e.g., V0–2, V3–5, V6+, based on normalized DI.  
- Compare: last 10 sessions vs lifetime.

### Streaks
- **Consistency**: count of consecutive weeks with at least 1 session.  

### Fatigue Flag (optional)
- If rolling 3-session average sendPercent drops by >20% compared to baseline.

---

## UI Design (SwiftUI)

### Entry Point
- New tab: **Analytics** on the bottom tab bar.

### Layout
1. **Top Summary**
   - Hardest grade this month vs last 3 months.
   - Success % this month vs last 3 months.
   - Attempts per send ratio (trend arrow).

2. **Charts**
   - **Line Chart**: Hardest + Median Grade DI per session (progression curve).
   - **Bar Chart**: Weekly attempts + sends (volume).
   - **Line Chart**: Send % over sessions.
   - **Histogram**: Grade distribution (last 10 vs lifetime).

3. **Highlights**
   - PR badges (first V5, first 5.12, etc.).
   - Consistency streak.
   - Fatigue flag (if triggered).

### Components
- `GlobalSessionsView`: main container.
- `ProgressionChart`: SwiftUI Chart line view for hardest/median DI.
- `VolumeChart`: bar chart of weekly volume.
- `EfficiencyChart`: line chart for send % and attempts/send.
- `DistributionChart`: histogram comparing grade bands.
- `HighlightsView`: badges and streak indicators.

---

## Computation Details

### DI Normalization
- All grades normalized to Difficulty Index (DI).
- Use pre-defined French scale as canonical axis.
- Conversion functions:
  - `normalizeToDI(grade: String, system: GradeSystem, type: ClimbType) -> Int`
  - `denormalizeFromDI(DI: Int, system: GradeSystem, type: ClimbType) -> String`

### Trends
- **Hardest Grade Trend**: `max(hardestGradeDI per session)`.
- **Median Grade Trend**: median DI across sends in session.
- **Rolling averages**: exponential decay half-life = 30 days.

---

## Milestones & Tasks

### Milestone 1 — Data Layer
- [ ] Extend Session model with summary metrics.
- [ ] Implement `computeSummaryMetrics()` per session.
- [ ] Unit tests with synthetic sessions.

### Milestone 2 — Aggregation Utilities
- [ ] Implement functions:
  - `getHardestTrend(sessions: [Session])`
  - `getMedianTrend(sessions: [Session])`
  - `getWeeklyVolume(sessions: [Session])`
  - `getSendPercentTrend(sessions: [Session])`
  - `getAttemptsPerSendTrend(sessions: [Session])`
  - `getGradeDistribution(sessions: [Session], window: Int?)`
- [ ] Unit tests for aggregation correctness.

### Milestone 3 — UI Dashboard
- [ ] Create `GlobalSessionsView` container.
- [ ] Build SwiftUI Charts for progression, volume, efficiency, distribution.
- [ ] Add Highlights section with PRs, streaks, fatigue flag.

### Milestone 4 — QA & Iteration
- [ ] Verify all metrics compute locally with no backend calls.
- [ ] Validate PR detection and streak logic.
- [ ] Optimize UI performance for large session histories.

---

## Deliverable Summary
- Local-first **analytics dashboard** for climbers.
- Provides **progression, volume, efficiency, distribution** insights.
- Uses **DI normalization** for cross-system grade consistency.
- Clear **milestones** for engineering delivery.
