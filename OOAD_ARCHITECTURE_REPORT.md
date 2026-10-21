# FitTrack — Object-Oriented Analysis and Design (OOAD) Architecture Report

**Project Title**: Smart Fitness Tracker — FitTrack  
**Domain**: Mobile Health & Fitness Informatics  
**Technology Stack**: Flutter (Dart), SQLite (sqflite), Clean Architecture, BLoC Pattern  

---

## 1. Executive Summary

The **FitTrack** application was conceived, modeled, and implemented using formal **Object-Oriented Analysis and Design (OOAD)** methodologies. The objective is to produce a scalable, offline-first mobile application capable of recording real-time outdoor GPS activities and indoor structured strength workouts while persisting all historical data in a local relational database for analytics.

This document details the object-oriented analysis, domain modeling, design patterns, architectural layers, and SOLID compliance implemented across the codebase.

---

## 2. Object-Oriented Analysis (OOA)

### 2.1 Actors
1. **Athlete (Primary Actor)**: Authenticates, defines biometric metrics (height, weight, target goal), initiates live GPS sessions, records strength exercises/sets, views analytics trends, and receives rule-based fitness insights.
2. **GPS / Location Sensor (Secondary Hardware Actor)**: Emits periodic geographical coordinates (`latitude`, `longitude`, `speed`, `altitude`) consumed by the tracking pipeline.
3. **Local SQLite Database (Secondary Storage Actor)**: Persists entities, maintains relational constraints, and executes aggregation queries.

### 2.2 Key Use Cases
- **UC-01: Authenticate Athlete Profile**: Demonstrates local session persistence and profile validation.
- **UC-02: Track Live Outdoor GPS Activity**: Coordinates GPS streams, calculates distance using Haversine/Euclidean geometry, determines real-time velocity, estimates calorie expenditure via activity-specific MET strategies, and plots route polylines.
- **UC-03: Log Structured Gym Workout**: Manages dynamic sets (weight in kg, reps count, completion state) for barbell/dumbbell exercises with an integrated rest timer.
- **UC-04: Log Manual Timed Activity**: Logs HIIT, Yoga, Swimming, or Martial Arts sessions with duration, intensity level, rounds, or swimming laps.
- **UC-05: Query Historical Analytics & Insights**: Aggregates total workouts, active duration, calories burned, and volume progressions with goal-based recommendations.

---

## 3. Object-Oriented Design (OOD) & Architecture

### 3.1 Layered Clean Architecture
The codebase strictly adheres to three distinct architectural tiers:

```
+-------------------------------------------------------------------+
|                       PRESENTATION LAYER                          |
|  - UI Screens (Login, Register, Dashboard, Tracking, Gym, History)|
|  - Modular Widgets (MetricCard, ActivityTile, ChartWidgets)       |
|  - State Management Cubits (AuthCubit, TrackingCubit, etc.)       |
+---------------------------------+---------------------------------+
                                  | depends on
                                  v
+-------------------------------------------------------------------+
|                          DOMAIN LAYER                             |
|  - Entities: User, ActivitySession, ExerciseRecord, GpsPoint      |
|  - Abstract Repositories: UserRepository, ActivityRepository      |
|  - Strategies: CalorieCalculatorStrategy, CalorieCalculatorFactory|
+---------------------------------+---------------------------------+
                                  ^ implemented by
                                  |
+-------------------------------------------------------------------+
|                           DATA LAYER                              |
|  - SQLite Database Helper (sqflite singleton, schema, migration)  |
|  - Concrete Repositories: SqliteUserRepository, etc.              |
+-------------------------------------------------------------------+
```

---

## 4. Design Patterns Implemented

### 4.1 Strategy Pattern (Behavioral)
- **Problem**: Different physical activities burn energy at vastly differing rates depending on moving speed, resistance, and Metabolic Equivalent of Task (MET). Hardcoding `switch` statements inside UI widgets violates the Open-Closed Principle.
- **Solution**: The `CalorieCalculatorStrategy` interface encapsulates calorie calculation logic. Concrete strategies include:
  - `RunningCalorieCalculatorStrategy` (MET dynamically scaled by running speed)
  - `CyclingCalorieCalculatorStrategy` (MET scaled by cycling pace)
  - `GymCalorieCalculatorStrategy` (MET 6.0)
  - `HiitCalorieCalculatorStrategy` (MET 8.5)
  - `YogaCalorieCalculatorStrategy` (MET 3.0)
  - `SwimmingCalorieCalculatorStrategy` (MET 7.0)
- **Code Reference**: `lib/domain/strategies/calorie_calculator_strategy.dart`

### 4.2 Factory Pattern (Creational)
- **Problem**: Decoupling caller classes from concrete strategy instantiations.
- **Solution**: `CalorieCalculatorFactory.getStrategy(ActivityType)` inspects the activity type and produces the appropriate concrete calculation strategy.
- **Code Reference**: `CalorieCalculatorFactory` in `lib/domain/strategies/calorie_calculator_strategy.dart`

### 4.3 Repository Pattern (Architectural / Structural)
- **Problem**: Direct database queries in UI widgets lead to tight coupling, making schema refactoring and testing difficult.
- **Solution**: Abstract repository contracts (`UserRepository`, `ActivityRepository`, `WorkoutRepository`) define domain operations. Concrete implementations (`SqliteUserRepository`, `SqliteActivityRepository`, `SqliteWorkoutRepository`) handle SQLite queries and transactions.
- **Code Reference**: `lib/domain/repositories/` and `lib/data/repositories/`

### 4.4 Observer Pattern (Behavioral)
- **Problem**: UI widgets must reactively update whenever background GPS points arrive, timers tick, or database records are committed.
- **Solution**: Utilized the **BLoC / Cubit** architecture. Presentation widgets observe immutable state streams (`TrackingState`, `WorkoutState`, `DashboardState`) and trigger repaints only when relevant sub-properties change.
- **Code Reference**: `lib/presentation/cubits/`

### 4.5 Singleton Pattern (Creational)
- **Problem**: Multiple uncoordinated database connections cause SQLite file locks and concurrency bugs.
- **Solution**: `DatabaseHelper` enforces a single, thread-safe instance managing SQLite lifecycle.
- **Code Reference**: `lib/data/database/database_helper.dart`

---

## 5. OOP Principles & SOLID Compliance

1. **Single Responsibility Principle (SRP)**:
   - `GpsPoint` is purely a value object representing coordinates.
   - `DatabaseHelper` only manages database connectivity and table schemas.
   - `TrackingCubit` solely orchestrates the live tracking session lifecycle.
2. **Open-Closed Principle (OCP)**:
   - New fitness activities (e.g. Rowing, Pilates) can be introduced by creating a new `CalorieCalculatorStrategy` implementation without altering existing calculators.
3. **Liskov Substitution Principle (LSP)**:
   - Any subclass of `ActivitySession` (`OutdoorTrackedSession`, `GymWorkoutSession`, `TimedWorkoutSession`) can be substituted wherever an `ActivitySession` is expected (e.g. in `ActivityTile` or database serializers).
4. **Interface Segregation Principle (ISP)**:
   - Separate, focused repository interfaces (`UserRepository`, `ActivityRepository`, `WorkoutRepository`) ensure classes only implement methods relevant to their domain.
5. **Dependency Inversion Principle (DIP)**:
   - High-level Presentation Cubits depend upon abstract interfaces (`ActivityRepository`), not concrete SQLite database drivers.

---

## 6. Viva Examination Q&A Cheat Sheet

**Q1: Why did you choose SQLite over NoSQL/SharedPreferences for FitTrack?**  
*Answer*: FitTrack models relational data (Workouts have multiple Exercises; Exercises have multiple Sets; Sessions have thousands of GPS coordinates). SQLite provides ACID compliance, foreign key cascade constraints (`ON DELETE CASCADE`), transactional integrity, and efficient relational aggregation queries (`SUM`, `COUNT`, `GROUP BY`) needed for analytics.

**Q2: How does your calorie calculation demonstrate the Strategy Pattern?**  
*Answer*: We defined a `CalorieCalculatorStrategy` interface with a `calculateCalories()` method. Specific activity classes implement this interface with distinct scientific MET values. The `TrackingCubit` relies on the interface, meaning algorithms can be swapped or modified dynamically at runtime without modifying the tracking pipeline.

**Q3: How are app lifecycle events handled during live GPS tracking?**  
*Answer*: The `LiveTrackingScreen` implements `WidgetsBindingObserver` to monitor `AppLifecycleState`. Furthermore, a `PopScope` widget intercepts back gestures to prevent accidental session termination while tracking is in progress.

**Q4: How does polymorphism manifest in your domain entities?**  
*Answer*: The base `ActivitySession` class defines common properties (`id`, `startTime`, `caloriesBurned`) and an abstract `performanceSummary` getter. Subclasses (`OutdoorTrackedSession`, `GymWorkoutSession`, `TimedWorkoutSession`) override this getter polymorphically to display distance & pace, sets & volume, or laps & stroke style respectively.
