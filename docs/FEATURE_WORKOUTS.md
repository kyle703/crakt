# Workouts Feature — Implementation Complete

## Overview

The Workouts feature has been successfully implemented as structured protocols within climbing sessions. The feature extends the existing hierarchy (`Session → Route → RouteAttempt`) with a new abstraction: `Session → Workout → WorkoutSet → WorkoutRep → WorkoutMetrics`.

## Key Architecture Decisions

1. **Workout Structure**: Workouts are session-level entities that coordinate multiple route attempts
2. **State Management**: `WorkoutOrchestrator` manages workout lifecycle and integrates with existing attempt logging
3. **UI Integration**: Minimal overhead design with workout status chips and progress indicators
4. **Data Persistence**: Full SwiftData integration with proper relationships and cascade deletes

---

## ✅ Deliverable 1: Data Model + Core Logic

- [x] **Workout Model** (`Workout.swift`):

  - Fields: `id`, `session`, `type`, `status`, `startedAt`, `endedAt`, `currentSetIndex`, `currentRepIndex`
  - Computed properties: `completionPercentage`, `totalReps`, `completedReps`, `metrics`
  - State management: `advanceToNextRep()`, `completeWorkout()`, `pauseWorkout()`, `resumeWorkout()`

- [x] **WorkoutSet Model**:

  - Fields: `setNumber`, `targetReps`, `startedAt`, `completedAt`
  - Computed: `actualReps`, `completionRate`

- [x] **WorkoutRep Model**:

  - Links to `RouteAttempt` with timing data
  - Methods: `start()`, `complete(with:)`

- [x] **WorkoutMetrics Struct**:

  - Core metrics: `totalDuration`, `sendRate`, `averageRestTime`, `hardestGradeAttempted`

- [x] **Workout Types**: 4x4s, Pyramid, Max Effort, Custom Interval with auto-configuration

---

## ✅ Deliverable 2: Workout Orchestrator

- [x] **`WorkoutOrchestrator`** (`WorkoutOrchestrator.swift`):
  - `ObservableObject` for reactive UI updates
  - State transitions: start, pause, resume, complete, cancel
  - `processAttempt()` integrates route attempts into workout progression
  - Automatic workout completion detection
  - Full SwiftData persistence

---

## ✅ Deliverable 3: UI Integration

- [x] **SessionActionBar** (`SessionActionBar.swift`):

  - Workout chip button with dynamic state
  - Progress bar showing completion percentage
  - Workout selector sheet integration
  - Modified `performAction()` to route attempts through workout orchestrator

- [x] **SessionHeader** (`SessionHeader.swift`):

  - Workout status chip in collapsed view
  - Progress bar visualization
  - Minimal overhead design

- [x] **WorkoutSelectorView** (`WorkoutSelectorView.swift`):
  - Workout type selection with descriptions
  - Active workout management (pause/resume/complete/cancel)
  - Real-time progress display

---

## ✅ Deliverable 4: Summary + Metrics

- [x] **SessionDetailView** (`SessionDetailView.swift`):

  - Completed workouts section
  - Integration with existing session metrics

- [x] **WorkoutSummaryCard** (`WorkoutSummaryCard.swift`):
  - Visual workout completion cards
  - Key metrics: completion %, send rate, duration, hardest grade
  - Average rest time display
  - Progress visualization

---

## Files Created/Modified

### New Files:

- `crakt/Models/Workout.swift` - Core workout data models
- `crakt/Models/WorkoutOrchestrator.swift` - Workout state management
- `crakt/Views/Session/WorkoutSelectorView.swift` - Workout selection and management UI
- `crakt/Views/Session/WorkoutSummaryCard.swift` - Workout summary display

### Modified Files:

- `crakt/Models/Session.swift` - Added workout relationships
- `crakt/Views/Session/SessionActionBar.swift` - Added workout integration
- `crakt/Views/Session/SessionHeader.swift` - Added workout status display
- `crakt/Views/Session/SessionDetailView.swift` - Added workout summaries
- `crakt/Views/Session/SessionView.swift` - Wired up workout orchestrator

---

## Usage Flow

1. **Start Workout**: Tap workout button in SessionActionBar → Select workout type
2. **Execute Workout**: Normal climb logging advances workout reps automatically
3. **Monitor Progress**: Progress bars in header and action bar show completion
4. **Complete Workout**: Automatic completion or manual completion via workout selector
5. **View Results**: Workout summaries appear in SessionDetailView with metrics

---

## Future Enhancements (Not Implemented)

- Autoscaling heuristics (trending grade, style weaknesses)
- Advanced workout types with custom timing
- Workout history analytics
- Rest timer integration
- Advanced metrics dashboard
