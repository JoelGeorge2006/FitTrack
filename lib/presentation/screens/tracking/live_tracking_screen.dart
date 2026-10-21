import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../cubits/tracking/tracking_cubit.dart';
import '../../cubits/tracking/tracking_state.dart';
import '../../widgets/tracking_button.dart';

class LiveTrackingScreen extends StatefulWidget {
  final ActivityType initialActivityType;

  const LiveTrackingScreen({
    super.key,
    this.initialActivityType = ActivityType.running,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> with WidgetsBindingObserver {
  late final MapController _mapController;
  late ActivityType _selectedActivity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mapController = MapController();
    _selectedActivity = widget.initialActivityType;
    context.read<TrackingCubit>().setActivityType(_selectedActivity);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Graceful handling of app pausing / backgrounding
    if (state == AppLifecycleState.paused) {
      // App in background
    } else if (state == AppLifecycleState.resumed) {
      // App brought to foreground
    }
  }

  void _onFinishPressed() {
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Complete Outdoor Session',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add optional notes before saving to your offline database.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g. Great pace, morning sunny weather, hill climbs...',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final session = await context.read<TrackingCubit>().finishTracking(
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    );
                if (session != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Session saved! ${session.distanceKm.toStringAsFixed(2)} km logged.'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.of(context).pop(); // Exit screen back to Home
                }
              },
              child: const Text('Save & Finish'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final trackingState = context.read<TrackingCubit>().state;
    if (trackingState.status == TrackingStatus.tracking ||
        trackingState.status == TrackingStatus.paused) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Discard Session?', style: TextStyle(color: AppColors.textPrimary)),
          content: const Text(
            'You have an active tracking session. Exiting will cancel this workout.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep Tracking'),
            ),
            TextButton(
              onPressed: () {
                context.read<TrackingCubit>().reset();
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Discard', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final allow = await _onWillPop();
        if (allow && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<TrackingCubit, TrackingState>(
          listener: (context, state) {
            if (state.currentLocation != null) {
              try {
                _mapController.move(state.currentLocation!, 16.0);
              } catch (_) {}
            }
          },
          builder: (context, state) {
            final isTracking = state.status == TrackingStatus.tracking;
            final isPaused = state.status == TrackingStatus.paused;
            final isIdle = state.status == TrackingStatus.idle;

            final defaultMapCenter = state.currentLocation ?? const LatLng(12.9716, 77.5946);

            return Stack(
              children: [
                // 1. Interactive OpenStreetMap Tile Layer
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: defaultMapCenter,
                    initialZoom: 16.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: AppConstants.osmTileUrl,
                      userAgentPackageName: AppConstants.osmUserAgent,
                    ),
                    // Route Polyline
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: state.routeCoordinates,
                          color: AppColors.primary,
                          strokeWidth: 5.0,
                        ),
                      ],
                    ),
                    // Current Athlete Marker
                    if (state.currentLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: state.currentLocation!,
                            width: 32,
                            height: 32,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.navigation_rounded,
                                color: Colors.black,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // 2. Top Header Bar with Activity Selector & Back Button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                            onPressed: () async {
                              final allow = await _onWillPop();
                              if (allow && mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Activity Picker Dropdown (when idle)
                        if (isIdle) ...[
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.surfaceBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<ActivityType>(
                                  value: _selectedActivity,
                                  dropdownColor: AppColors.surface,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                                  items: [
                                    ActivityType.running,
                                    ActivityType.jogging,
                                    ActivityType.cycling,
                                    ActivityType.trekking,
                                  ].map((type) {
                                    return DropdownMenuItem<ActivityType>(
                                      value: type,
                                      child: Text(
                                        type.displayName,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newVal) {
                                    if (newVal != null) {
                                      setState(() => _selectedActivity = newVal);
                                      context.read<TrackingCubit>().setActivityType(newVal);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isTracking ? AppColors.success : AppColors.warning,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  state.activityType.displayName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 3. Bottom Floating Metrics Dashboard & Tracking Controls
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Primary Duration Display
                        Text(
                          state.formattedDuration,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'ELAPSED TIME',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Metric Grid
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLiveMetricTile(
                              title: 'DISTANCE',
                              value: state.distanceKm.toStringAsFixed(2),
                              unit: 'km',
                              color: AppColors.primary,
                            ),
                            _buildLiveMetricTile(
                              title: 'PACE',
                              value: state.formattedPace.split(' ').first,
                              unit: '/km',
                              color: AppColors.cyan,
                            ),
                            _buildLiveMetricTile(
                              title: 'SPEED',
                              value: state.averageSpeedKmh.toStringAsFixed(1),
                              unit: 'km/h',
                              color: AppColors.accent,
                            ),
                            _buildLiveMetricTile(
                              title: 'CALORIES',
                              value: state.caloriesBurned.toStringAsFixed(0),
                              unit: 'kcal',
                              color: AppColors.pink,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Controls Bar
                        if (isIdle) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow_rounded, size: 28),
                              label: Text('Start ${_selectedActivity.displayName}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 58),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () {
                                context.read<TrackingCubit>().startTracking(_selectedActivity);
                              },
                            ),
                          ),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (isTracking) ...[
                                TrackingButton(
                                  icon: Icons.pause_rounded,
                                  label: 'Pause',
                                  backgroundColor: AppColors.warning,
                                  iconColor: Colors.black,
                                  onPressed: () {
                                    context.read<TrackingCubit>().pauseTracking();
                                  },
                                ),
                              ] else if (isPaused) ...[
                                TrackingButton(
                                  icon: Icons.play_arrow_rounded,
                                  label: 'Resume',
                                  backgroundColor: AppColors.primary,
                                  iconColor: Colors.black,
                                  onPressed: () {
                                    context.read<TrackingCubit>().resumeTracking();
                                  },
                                ),
                              ],
                              TrackingButton(
                                icon: Icons.stop_rounded,
                                label: 'Finish',
                                backgroundColor: AppColors.error,
                                onPressed: _onFinishPressed,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLiveMetricTile({
    required String title,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
