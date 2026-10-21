import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/activity_session.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/dashboard/dashboard_cubit.dart';
import '../../cubits/dashboard/dashboard_state.dart';
import '../../widgets/activity_tile.dart';
import '../../widgets/chart_widgets.dart';
import '../../widgets/insight_card.dart';
import '../../widgets/metric_card.dart';
import '../tracking/live_tracking_screen.dart';
import '../workout/manual_workout_screen.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<DashboardCubit>().loadDashboardData(user: authState.user);
    } else {
      context.read<DashboardCubit>().loadDashboardData();
    }
  }

  void _showSessionDetailModal(BuildContext context, ActivitySession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  session.activityType.displayName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              session.performanceSummary,
              style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDetailMetric('Duration', session.formattedDuration, Icons.timer_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailMetric('Calories', '${session.caloriesBurned.toStringAsFixed(0)} kcal', Icons.local_fire_department_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (session is OutdoorTrackedSession) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildDetailMetric('Distance', '${session.distanceKm.toStringAsFixed(2)} km', Icons.straighten_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailMetric('Avg Pace', session.formattedPace, Icons.speed_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Notes: ${session.notes}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async => _refreshData(),
          child: BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoading) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (state is DashboardError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(state.errorMessage, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _refreshData, child: const Text('Retry')),
                    ],
                  ),
                );
              }

              final data = state as DashboardLoaded;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Greeting Athlete & Goal
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, authState) {
                        final userName = authState is Authenticated ? authState.user.name : 'Athlete';
                        final goal = authState is Authenticated ? authState.user.targetGoal : FitnessGoal.generalFitness;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $userName 👋',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      goal.displayName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Quick Action: GPS Track Button
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LiveTrackingScreen(initialActivityType: ActivityType.running),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.directions_run_rounded, color: Colors.black, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'Start Run',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Primary Metric Grid (Workouts, Active Time, Calories, Distance)
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            title: 'Workouts',
                            value: '${data.totalWorkouts}',
                            unit: 'sessions',
                            icon: Icons.fitness_center_rounded,
                            accentColor: AppColors.purple,
                            trendText: data.totalWorkouts > 0 ? 'Consistent' : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: MetricCard(
                            title: 'Active Time',
                            value: data.formattedTotalTime,
                            unit: '',
                            icon: Icons.timer_outlined,
                            accentColor: AppColors.cyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            title: 'Calories Burned',
                            value: data.totalCalories.toStringAsFixed(0),
                            unit: 'kcal',
                            icon: Icons.local_fire_department_rounded,
                            accentColor: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: MetricCard(
                            title: 'Total Distance',
                            value: data.totalDistanceKm.toStringAsFixed(1),
                            unit: 'km',
                            icon: Icons.map_outlined,
                            accentColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Goal-aligned Rule-based Recommendation Card
                    InsightCard(insights: data.ruleBasedInsights),
                    const SizedBox(height: 24),

                    // Weekly Caloric Burn Bar Chart
                    WeeklyActivityChart(weeklyData: data.weeklyTrends),
                    const SizedBox(height: 24),

                    // Recent Activities Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Activities',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (widget.onNavigateTab != null)
                          TextButton(
                            onPressed: () => widget.onNavigateTab!(2), // Switch to Analytics/History tab
                            child: const Text('View All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (data.recentSessions.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.fitness_center_outlined, size: 40, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No activities logged yet',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Start your first GPS tracking session or log an indoor workout.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Log Workout Now'),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ManualWorkoutScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ...data.recentSessions.take(4).map(
                            (session) => ActivityTile(
                              session: session,
                              onTap: () => _showSessionDetailModal(context, session),
                            ),
                          ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
