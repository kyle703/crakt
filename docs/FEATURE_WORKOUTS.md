# Workouts Feature — Developer Deliverable Plan

> IMPORTANT!!!!! specific names may not be accurate, find the exisiting corresponding file or component based on the context

> IMPEMENTER: MARK CHECKBOX DONE ONCE FEATURE IS DELIVERED, REMEMBER THIS!!!

## Context
Workouts are structured protocols embedded inside a climbing session.  
They extend the existing hierarchy (`Session → Route → RouteAttempt`) with a new abstraction:  
`Workout → WorkoutSet → WorkoutRep → WorkoutMetrics`.  
Workouts are autoscaled using local heuristics (trending grade, style weaknesses, compliance).  
They must integrate seamlessly into `SessionActionBar`, `SessionHeader`, and `SessionDetailView` with minimal UI overhead.

---

## Deliverable 1: Data Model + Heuristics
- [ ] Define `Workout` model with fields: `id`, `sessionID`, `type`, `status`, `startedAt`, `endedAt`, `metrics`.  
- [ ] Define `WorkoutSet` model with target vs actual reps and rest durations.  
- [ ] Define `WorkoutRep` linking to `RouteAttempt`.  
- [ ] Define `WorkoutMetrics` for completion %, send %, work/rest totals.  
- [ ] Implement trending grade calculator (weighted send % with 30-day half-life).  
- [ ] Implement style outlier detection (send rate deficit ≥15%).  
- [ ] Implement effort proxy: failure rate + avg rest + time under tension.  
- [ ] Implement compliance adjustment for rest/work ratios.  
- [ ] Unit tests with synthetic sessions to validate scaling logic.

---

## Deliverable 2: Workout Orchestrator
- [ ] Implement `WorkoutOrchestrator` as `ObservableObject`.  
- [ ] Handle state transitions: start, log rep, rest, complete.  
- [ ] Map `RouteAttempt` events from `SessionActionBar` into active `WorkoutRep`.  
- [ ] Implement timer manager for timed work/rest blocks.  
- [ ] Ensure orchestrator persists progress into SwiftData.  
- [ ] Unit tests for orchestrator state machine.

---

## Deliverable 3: UI Integration
- [ ] Add **Workout** chip in `SessionActionBar`.  
- [ ] Implement bottom drawer for workout selection and active progress.  
- [ ] Render workout HUD: current set, rep, timers, completion %.  
- [ ] Overlay grade pill in `RouteLogRowItem` when workout is active.  
- [ ] Update `SessionHeader` to display workout completion percent.  
- [ ] Ensure seamless logging: existing attempt buttons advance workout progress.

---

## Deliverable 4: Summary + Metrics
- [ ] Save metrics at workout completion.  
- [ ] Display workout summary in `SessionDetailView`.  
- [ ] Include metrics: total reps, send %, hardest grade hit, total work/rest.  
- [ ] Add charts: completion %, grade distribution, work vs rest time.  
- [ ] Verify session detail view aggregates both route logs and workout logs.  
