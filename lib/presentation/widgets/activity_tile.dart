import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/activity_session.dart';

class ActivityTile extends StatelessWidget {
  final ActivitySession session;
  final VoidCallback? onTap;

  const ActivityTile({
    super.key,
    required this.session,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final actType = session.activityType;
    final dateStr = DateFormat('MMM d, h:mm a').format(session.startTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _getActivityColor(actType).withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(_getActivityIcon(actType), color: _getActivityColor(actType), size: 22),
        ),
        title: Text(
          actType.displayName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              session.performanceSummary,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              session.caloriesBurned.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const Text(
              'kcal',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _getActivityIcon(dynamic type) {
    switch (type.toString()) {
      case 'ActivityType.running':
      case 'ActivityType.jogging':
        return Icons.directions_run_rounded;
      case 'ActivityType.cycling':
        return Icons.directions_bike_rounded;
      case 'ActivityType.trekking':
        return Icons.hiking_rounded;
      case 'ActivityType.gymWorkout':
      case 'ActivityType.strengthTraining':
        return Icons.fitness_center_rounded;
      case 'ActivityType.hiit':
        return Icons.bolt_rounded;
      case 'ActivityType.yoga':
        return Icons.self_improvement_rounded;
      case 'ActivityType.martialArts':
        return Icons.sports_mma_rounded;
      case 'ActivityType.swimming':
        return Icons.pool_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  Color _getActivityColor(dynamic type) {
    switch (type.toString()) {
      case 'ActivityType.running':
      case 'ActivityType.jogging':
        return AppColors.primary;
      case 'ActivityType.cycling':
        return AppColors.cyan;
      case 'ActivityType.trekking':
        return AppColors.accent;
      case 'ActivityType.gymWorkout':
      case 'ActivityType.strengthTraining':
        return AppColors.purple;
      case 'ActivityType.hiit':
        return AppColors.pink;
      case 'ActivityType.yoga':
        return AppColors.primaryLight;
      case 'ActivityType.martialArts':
        return AppColors.error;
      case 'ActivityType.swimming':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }
}
