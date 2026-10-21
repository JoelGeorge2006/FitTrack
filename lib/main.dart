import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'data/database/database_helper.dart';
import 'data/repositories/sqlite_activity_repository.dart';
import 'data/repositories/sqlite_user_repository.dart';
import 'data/repositories/sqlite_workout_repository.dart';
import 'presentation/cubits/auth/auth_cubit.dart';
import 'presentation/cubits/auth/auth_state.dart';
import 'presentation/cubits/dashboard/dashboard_cubit.dart';
import 'presentation/cubits/tracking/tracking_cubit.dart';
import 'presentation/cubits/workout/workout_cubit.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize SQLite database helper singleton
  final dbHelper = DatabaseHelper();
  await dbHelper.database;

  // Initialize concrete repositories
  final userRepo = SqliteUserRepository(dbHelper: dbHelper);
  final workoutRepo = SqliteWorkoutRepository(dbHelper: dbHelper);
  final activityRepo = SqliteActivityRepository(
    dbHelper: dbHelper,
    workoutRepository: workoutRepo,
  );

  runApp(FitTrackApp(
    userRepository: userRepo,
    activityRepository: activityRepo,
  ));
}

class FitTrackApp extends StatelessWidget {
  final SqliteUserRepository userRepository;
  final SqliteActivityRepository activityRepository;

  const FitTrackApp({
    super.key,
    required this.userRepository,
    required this.activityRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(userRepository: userRepository)..checkAuthStatus(),
        ),
        BlocProvider<TrackingCubit>(
          create: (_) => TrackingCubit(activityRepository: activityRepository),
        ),
        BlocProvider<WorkoutCubit>(
          create: (_) => WorkoutCubit(activityRepository: activityRepository),
        ),
        BlocProvider<DashboardCubit>(
          create: (_) => DashboardCubit(activityRepository: activityRepository),
        ),
      ],
      child: MaterialApp(
        title: 'FitTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthGate(),
      ),
    );
  }
}

/// Authentication state router
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Provide athlete context to tracking, workout, and dashboard cubits
          context.read<TrackingCubit>().setAthleteContext(
                userId: state.user.id,
                weightKg: state.user.weightKg,
              );
          context.read<WorkoutCubit>().setAthleteContext(
                userId: state.user.id,
                weightKg: state.user.weightKg,
              );
          context.read<DashboardCubit>().loadDashboardData(user: state.user);
        }
      },
      builder: (context, state) {
        if (state is Authenticated) {
          return const MainScreen();
        } else if (state is Unauthenticated || state is AuthError) {
          return const LoginScreen();
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
