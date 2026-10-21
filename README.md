# FitTrack — Smart Fitness Tracker Application

> **College Object-Oriented Analysis and Design (OOAD) Project**  
> Built with **Flutter & Dart** • 100% Offline-Capable • SQLite Persistence • Clean Architecture

---

## 1. Project Overview

**FitTrack** is a cross-platform mobile fitness tracker engineered from the ground up to demonstrate modern **Object-Oriented Analysis and Design (OOAD)** principles alongside an athletic, high-contrast user experience inspired by professional design specifications.

The application operates **entirely offline** using local SQL persistence, supporting both **real-time outdoor GPS tracking** (Running, Jogging, Cycling, Trekking) with interactive map route plotting and **manual indoor workout logging** (Gym Strength Training with dynamic set management, HIIT, Yoga, Martial Arts, and Swimming).

---

## 2. Key Features

- **Local Authentication & Biometric Profile**:
  - Offline session persistence across restarts.
  - Personal biometric profile tracking: Height, Weight, and Target Goal (*Weight Loss*, *Muscle Gain*, *General Fitness*).
  - Dynamic **Body Mass Index (BMI)** calculation and health status classification.
  - Pre-filled **Quick Demo Login** for evaluation viva (`athlete@fittrack.demo` / `fittrack123`).

- **Live Outdoor GPS Tracking**:
  - Live route plotting on an interactive map powered by **OpenStreetMap** raster tiles via `flutter_map` (zero paid API keys required).
  - Real-time duration timer, distance accumulation via GPS coordinates, current & average speed, and pace calculation.
  - Dynamic calorie burn estimation utilizing the **Strategy Pattern** with Metabolic Equivalent of Task (**MET**) values scaled by user body weight and moving velocity.
  - Safety controls: Start, Pause, Resume, Stop/Finish, and `PopScope` protection against accidental navigation.

- **Manual Workout Logging (Indoor & Strength)**:
  - **Gym & Strength**: Dynamic exercise addition, interactive set logging (reps, weight in kg, completion toggle), and cumulative volume calculation.
  - **Rest Timer**: Integrated countdown timer (e.g. 60s, 90s, +30s increment) between intense sets.
  - **HIIT, Yoga & Martial Arts**: Duration, intensity level, rounds, notes, and MET calorie calculation.
  - **Swimming**: Pool length (25m/50m), stroke style (Freestyle, Breaststroke, Backstroke, Butterfly), laps, and total swim distance.

- **Analytics Dashboard & Fitness Insights**:
  - Aggregated metrics derived strictly from local SQLite database records (zero hardcoded numbers).
  - Interactive **Weekly Caloric Burn** bar charts and **Monthly Volume Trends** line graphs powered by `fl_chart`.
  - Transparent, goal-aligned **rule-based fitness recommendations** based on WHO cardiovascular activity milestones and progressive overload guidelines.

---

## 3. OOAD Architecture & Design Patterns

FitTrack follows **Clean Architecture** with strict layer separation:

```
lib/
├── core/                  # Shared utilities, constants, theme, and centralized routes
│   ├── constants/         # AppColors, AppConstants, Enums
│   ├── routes/            # AppRoutes centralized routing
│   └── theme/             # Dark athletic theme with Google Fonts Inter
├── domain/                # Pure business logic & interfaces (zero external dependencies)
│   ├── entities/          # User, ActivitySession, GpsPoint, ExerciseRecord, ExerciseSet
│   ├── repositories/      # UserRepository, ActivityRepository, WorkoutRepository
│   └── strategies/        # CalorieCalculatorStrategy & CalorieCalculatorFactory
├── data/                  # Concrete persistence & hardware implementations
│   ├── database/          # DatabaseHelper (SQLite open helper, relational schema, indexes)
│   └── repositories/      # SqliteUserRepository, SqliteActivityRepository, SqliteWorkoutRepository
└── presentation/          # State management & reactive UI layer
    ├── cubits/            # AuthCubit, TrackingCubit, WorkoutCubit, DashboardCubit
    ├── screens/           # Auth, Dashboard, Tracking, Workout, Analytics, Profile
    └── widgets/           # MetricCard, ChartWidgets, ActivityTile, TrackingButton, RestTimer
```

### Applied Design Patterns
1. **Strategy Pattern (`CalorieCalculatorStrategy`)**:
   - Decouples caloric expenditure calculations into distinct strategies (`RunningCalorieCalculatorStrategy`, `CyclingCalorieCalculatorStrategy`, `GymCalorieCalculatorStrategy`, etc.).
   - Dynamically selects the calculation strategy at runtime based on the selected activity type and moving speed.
2. **Repository Pattern (`UserRepository`, `ActivityRepository`, `WorkoutRepository`)**:
   - Encapsulates database access behind abstract interfaces. Business logic interacts solely with domain repositories, isolating SQLite schema changes from UI widgets.
3. **Factory Pattern (`CalorieCalculatorFactory`)**:
   - Instantiates and provides the appropriate calculator strategy based on the `ActivityType` enum.
4. **Observer Pattern (`Bloc / Cubit`)**:
   - Provides reactive, predictable state management. Presentation widgets observe immutable state streams (`AuthState`, `TrackingState`, `WorkoutState`, `DashboardState`).
5. **Polymorphism & Abstraction (`ActivitySession`)**:
   - Base abstract class `ActivitySession` with specialized subclasses:
     - `OutdoorTrackedSession`: GPS route points, distance, pace, speed.
     - `GymWorkoutSession`: Exercises, sets, reps, weight volume.
     - `TimedWorkoutSession`: Rounds, laps, stroke type, intensity level.

---

## 4. Database Schema (SQLite via `sqflite`)

Relational tables with foreign key cascades:
- **`users`**: `id`, `name`, `email`, `height_cm`, `weight_kg`, `target_goal`, `created_at`
- **`activity_sessions`**: `id`, `user_id`, `activity_type`, `category`, `start_time`, `end_time`, `duration_seconds`, `calories_burned`, `distance_meters`, `average_speed_kmh`, `workout_name`, `intensity_level`, etc.
- **`gps_points`**: `id`, `session_id`, `latitude`, `longitude`, `altitude`, `speed_mps`, `timestamp`
- **`workout_exercises`**: `id`, `session_id`, `exercise_name`, `target_muscle_group`
- **`exercise_sets`**: `id`, `exercise_record_id`, `set_number`, `reps`, `weight_kg`, `is_completed`

---

## 5. Setup & Installation

### Prerequisites
- Flutter SDK (stable channel, 3.24+ / 3.47+)
- Dart SDK (3.3+)
- Android SDK 34 (Java 17)

### Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/JoelGeorge2006/FitTrack.git
   cd FitTrack
   ```

2. **Install project dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify code quality & static analysis**:
   ```bash
   flutter analyze
   ```

4. **Run on connected device / emulator**:
   ```bash
   flutter run
   ```

5. **Build Android Debug APK**:
   ```bash
   flutter build apk --debug
   ```
   The generated APK will be located at:
   `build/app/outputs/flutter-apk/app-debug.apk`

---

## 6. Android Permissions Configured

In `android/app/src/main/AndroidManifest.xml`:
- `ACCESS_FINE_LOCATION`: For accurate GPS route tracking.
- `ACCESS_COARSE_LOCATION`: For cell/wifi location fallback.
- `ACCESS_BACKGROUND_LOCATION`: To track runs when the screen is dimmed.
- `FOREGROUND_SERVICE` & `FOREGROUND_SERVICE_LOCATION`: For uninterrupted tracking service.
- `INTERNET`: For downloading OpenStreetMap raster tiles.

---

## 7. Demo / College Viva Evaluation Credentials

- **Email**: `athlete@fittrack.demo`
- **Password**: `fittrack123`
- *Or tap the "Quick Demo Evaluation Login" button on the login screen for instant one-tap entry.*
