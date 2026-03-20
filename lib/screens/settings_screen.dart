import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/app_settings.dart';
import '../services/home_widget_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onPreview;
  const SettingsScreen({super.key, required this.onPreview});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _widgetRefreshing = false;
  bool _widgetRefreshed = false;

  static const _accent = Color(0xFF00FFA8);
  static const _surface = Color(0xFF111418);
  static const _border = Color(0xFF1E2535);
  static const _dim = Color(0xFF3A4A50);

  Future<void> _refreshWidget(AppSettings settings) async {
    setState(() {
      _widgetRefreshing = true;
      _widgetRefreshed = false;
    });
    await HomeWidgetService.updateWidget(settings: settings);
    if (mounted) {
      setState(() {
        _widgetRefreshing = false;
        _widgetRefreshed = true;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _widgetRefreshed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, settings, _) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 36),

                // ── Dock Behaviour ─────────────────────────────────────────
                _sectionLabel('DOCK BEHAVIOUR'),
                const SizedBox(height: 10),
                _toggleCard(
                  icon: Icons.dock_rounded,
                  title: 'Auto-launch in dock mode',
                  subtitle: 'Opens clock when charging + landscape detected',
                  value: settings.autoDockEnabled,
                  onChanged: settings.setAutoDock,
                ),
                const SizedBox(height: 28),

                // ── Clock Display ──────────────────────────────────────────
                _sectionLabel('CLOCK DISPLAY'),
                const SizedBox(height: 10),
                _toggleCard(
                  icon: Icons.access_time_rounded,
                  title: '24-hour format',
                  subtitle: 'Show time in 24h instead of 12h AM/PM',
                  value: settings.show24h,
                  onChanged: settings.setShow24h,
                ),
                const SizedBox(height: 8),
                _toggleCard(
                  icon: Icons.timer_outlined,
                  title: 'Show seconds',
                  subtitle: 'Seconds counter below the time',
                  value: settings.showSeconds,
                  onChanged: settings.setShowSeconds,
                ),
                const SizedBox(height: 8),
                _toggleCard(
                  icon: Icons.calendar_today_rounded,
                  title: 'Show date',
                  subtitle: 'Day and date line below the clock',
                  value: settings.showDate,
                  onChanged: settings.setShowDate,
                ),
                const SizedBox(height: 28),

                // ── Screen ────────────────────────────────────────────────
                _sectionLabel('SCREEN'),
                const SizedBox(height: 10),
                _sliderCard(
                  icon: Icons.brightness_medium_rounded,
                  title: 'Clock screen brightness',
                  value: settings.screenBrightness,
                  min: 0.1,
                  max: 1.0,
                  displayValue: '${(settings.screenBrightness * 100).round()}%',
                  onChanged: settings.setScreenBrightness,
                ),
                const SizedBox(height: 28),

                // ── Sensor Sensitivity ────────────────────────────────────
                _sectionLabel('SENSOR SENSITIVITY'),
                const SizedBox(height: 10),
                _sliderCard(
                  icon: Icons.screen_rotation_rounded,
                  title: 'Landscape detection threshold',
                  subtitle: _thresholdLabel(settings.landscapeThreshold),
                  value: settings.landscapeThreshold,
                  min: 1.0,
                  max: 2.0,
                  displayValue: settings.landscapeThreshold.toStringAsFixed(1),
                  onChanged: settings.setLandscapeThreshold,
                ),
                const SizedBox(height: 28),

                // ── Home Widget ───────────────────────────────────────────
                _sectionLabel('HOME WIDGET'),
                const SizedBox(height: 10),
                _buildWidgetPreviewCard(settings),
                const SizedBox(height: 12),
                _toggleCard(
                  icon: Icons.schedule_rounded,
                  title: 'Widget: 24-hour format',
                  subtitle: 'Independent from the clock screen setting',
                  value: settings.widgetShow24h,
                  onChanged: (v) async {
                    await settings.setWidgetShow24h(v);
                    await HomeWidgetService.updateWidget(settings: settings);
                  },
                ),
                const SizedBox(height: 8),
                _toggleCard(
                  icon: Icons.timer_outlined,
                  title: 'Widget: show seconds',
                  subtitle: 'Seconds snapshot on the home screen widget',
                  value: settings.widgetShowSeconds,
                  onChanged: (v) async {
                    await settings.setWidgetShowSeconds(v);
                    await HomeWidgetService.updateWidget(settings: settings);
                  },
                ),
                const SizedBox(height: 8),
                _toggleCard(
                  icon: Icons.today_rounded,
                  title: 'Widget: show day',
                  subtitle: 'Day name at top of widget (e.g. FRIDAY)',
                  value: settings.widgetShowDay,
                  onChanged: (v) async {
                    await settings.setWidgetShowDay(v);
                    await HomeWidgetService.updateWidget(settings: settings);
                  },
                ),
                const SizedBox(height: 8),
                _toggleCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Widget: show date',
                  subtitle: 'Date line at bottom of widget (e.g. FRI, 20 MAR)',
                  value: settings.widgetShowDate,
                  onChanged: (v) async {
                    await settings.setWidgetShowDate(v);
                    await HomeWidgetService.updateWidget(settings: settings);
                  },
                ),
                const SizedBox(height: 12),
                _buildRefreshButton(settings),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Widget updates automatically when the app is open.\nTap refresh to force an immediate update.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.2),
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Preview ───────────────────────────────────────────────
                _sectionLabel('PREVIEW'),
                const SizedBox(height: 10),
                _buildPreviewButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Widget preview card ──────────────────────────────────────────────────

  Widget _buildWidgetPreviewCard(AppSettings settings) {
    final now = DateTime.now();
    final timeStr = settings.widgetShow24h
        ? DateFormat('HH:mm').format(now)
        : DateFormat('hh:mm').format(now);
    final amPm = settings.widgetShow24h ? '' : DateFormat('a').format(now);
    final seconds = DateFormat('ss').format(now);
    final dateStr = DateFormat('EEE, d MMM').format(now).toUpperCase();
    final dayStr = DateFormat('EEEE').format(now).toUpperCase();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0C10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2535), width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.widgets_rounded,
                  size: 11, color: Color(0xFF3A6E58)),
              const SizedBox(width: 6),
              Text(
                'WIDGET PREVIEW',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  letterSpacing: 2.5,
                  color: _accent.withOpacity(0.35),
                ),
              ),
              const Spacer(),
              Text(
                'LIVE',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  letterSpacing: 2,
                  color: _accent.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Widget mock
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1014),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E2535), width: 0.5),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              children: [
                if (settings.widgetShowDay)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      dayStr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8,
                        letterSpacing: 3,
                        color: Color(0xFF3A6E58),
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFFE8F8F0),
                        letterSpacing: 2,
                      ),
                    ),
                    if (amPm.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        amPm,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Color(0xFF3A6E58),
                        ),
                      ),
                    ],
                  ],
                ),
                if (settings.widgetShowSeconds)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      seconds,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        letterSpacing: 5,
                        color: Color(0xFF00FFA8),
                      ),
                    ),
                  ),
                if (settings.widgetShowDate)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dateStr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 7,
                        letterSpacing: 2,
                        color: Color(0xFF1E3028),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Toggle options below to see changes reflected here',
            style:
                TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.18)),
          ),
        ],
      ),
    );
  }

  // ── Refresh button ───────────────────────────────────────────────────────

  Widget _buildRefreshButton(AppSettings settings) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _widgetRefreshing ? null : () => _refreshWidget(settings),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _widgetRefreshed ? _accent.withOpacity(0.12) : _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _widgetRefreshed ? _accent.withOpacity(0.4) : _border,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_widgetRefreshing)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: _accent.withOpacity(0.6),
                  ),
                )
              else
                Icon(
                  _widgetRefreshed
                      ? Icons.check_rounded
                      : Icons.refresh_rounded,
                  color: _widgetRefreshed ? _accent : _dim,
                  size: 16,
                ),
              const SizedBox(width: 10),
              Text(
                _widgetRefreshing
                    ? 'UPDATING WIDGET...'
                    : _widgetRefreshed
                        ? 'WIDGET UPDATED'
                        : 'REFRESH WIDGET NOW',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  letterSpacing: 2.5,
                  color: _widgetRefreshed ? _accent : _dim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────

  String _thresholdLabel(double v) {
    if (v < 1.2) return 'Very sensitive — triggers easily';
    if (v < 1.5) return 'Balanced — recommended';
    if (v < 1.8) return 'Strict — requires firm landscape tilt';
    return 'Very strict — nearly flat landscape only';
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHARGING CLOCK',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            letterSpacing: 4,
            color: _accent.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 9,
        letterSpacing: 3,
        color: _accent.withOpacity(0.45),
      ),
    );
  }

  Widget _toggleCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required Future<void> Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? _accent.withOpacity(0.22) : _border,
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: value ? _accent : _dim),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: value
                        ? Colors.white.withOpacity(0.9)
                        : Colors.white.withOpacity(0.4),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.22),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _GlowSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _sliderCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required Future<void> Function(double) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 0.5),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _accent),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
              Text(
                displayValue,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  letterSpacing: 1,
                  color: _accent,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.22),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 1.5,
              activeTrackColor: _accent.withOpacity(0.7),
              inactiveTrackColor: _border,
              thumbColor: _accent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: (v) => onChanged(v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewButton() {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: widget.onPreview,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accent.withOpacity(0.3), width: 0.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.preview_rounded, color: _accent, size: 18),
              SizedBox(width: 10),
              Text(
                'PREVIEW CLOCK SCREEN',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  letterSpacing: 3,
                  color: _accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Custom glow toggle switch ────────────────────────────────────────────────

class _GlowSwitch extends StatelessWidget {
  final bool value;
  final Future<void> Function(bool) onChanged;
  const _GlowSwitch({required this.value, required this.onChanged});

  static const _accent = Color(0xFF00FFA8);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value ? _accent.withOpacity(0.18) : const Color(0xFF1A2020),
          border: Border.all(
            color: value ? _accent.withOpacity(0.5) : const Color(0xFF2A3540),
            width: 0.5,
          ),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              left: value ? 22 : 2,
              top: 2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? _accent : const Color(0xFF3A4A50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/*
// class SettingsScreen extends StatelessWidget {
//   final VoidCallback onPreview;

//   const SettingsScreen({super.key, required this.onPreview});

//   static const _accent = Color(0xFF00FFA8);
//   static const _surface = Color(0xFF111418);
//   static const _border = Color(0xFF1E2535);
//   static const _dim = Color(0xFF3A4A50);

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<AppSettings>(
//       builder: (context, settings, _) {
//         return SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildHeader(),
//                 const SizedBox(height: 36),

//                 _buildSectionLabel('DOCK BEHAVIOUR'),
//                 const SizedBox(height: 10),
//                 _buildToggleCard(
//                   icon: Icons.dock_rounded,
//                   title: 'Auto-launch in dock mode',
//                   subtitle: 'Opens clock when charging + landscape detected',
//                   value: settings.autoDockEnabled,
//                   onChanged: settings.setAutoDock,
//                 ),
//                 const SizedBox(height: 28),

//                 _buildSectionLabel('CLOCK DISPLAY'),
//                 const SizedBox(height: 10),
//                 _buildToggleCard(
//                   icon: Icons.access_time_rounded,
//                   title: '24-hour format',
//                   subtitle: 'Show time in 24h instead of 12h AM/PM',
//                   value: settings.show24h,
//                   onChanged: settings.setShow24h,
//                 ),
//                 const SizedBox(height: 8),
//                 _buildToggleCard(
//                   icon: Icons.timer_outlined,
//                   title: 'Show seconds',
//                   subtitle: 'Display the seconds counter below the time',
//                   value: settings.showSeconds,
//                   onChanged: settings.setShowSeconds,
//                 ),
//                 const SizedBox(height: 8),
//                 _buildToggleCard(
//                   icon: Icons.calendar_today_rounded,
//                   title: 'Show date',
//                   subtitle: 'Display day and date below the clock',
//                   value: settings.showDate,
//                   onChanged: settings.setShowDate,
//                 ),
//                 const SizedBox(height: 28),

//                 _buildSectionLabel('SCREEN'),
//                 const SizedBox(height: 10),
//                 _buildSliderCard(
//                   icon: Icons.brightness_medium_rounded,
//                   title: 'Clock screen brightness',
//                   value: settings.screenBrightness,
//                   min: 0.1,
//                   max: 1.0,
//                   displayValue:
//                       '${(settings.screenBrightness * 100).round()}%',
//                   onChanged: settings.setScreenBrightness,
//                 ),
//                 const SizedBox(height: 28),

//                 _buildSectionLabel('SENSOR SENSITIVITY'),
//                 const SizedBox(height: 10),
//                 _buildSliderCard(
//                   icon: Icons.screen_rotation_rounded,
//                   title: 'Landscape detection threshold',
//                   subtitle: _thresholdLabel(settings.landscapeThreshold),
//                   value: settings.landscapeThreshold,
//                   min: 1.0,
//                   max: 2.0,
//                   displayValue: settings.landscapeThreshold.toStringAsFixed(1),
//                   onChanged: settings.setLandscapeThreshold,
//                 ),
//                 const SizedBox(height: 36),

//                 _buildPreviewButton(context),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   String _thresholdLabel(double v) {
//     if (v < 1.2) return 'Very sensitive — triggers easily';
//     if (v < 1.5) return 'Balanced — recommended';
//     if (v < 1.8) return 'Strict — requires firm landscape tilt';
//     return 'Very strict — nearly flat landscape only';
//   }

//   Widget _buildHeader() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'CHARGING CLOCK',
//           style: TextStyle(
//             fontFamily: 'monospace',
//             fontSize: 10,
//             letterSpacing: 4,
//             color: _accent.withOpacity(0.55),
//           ),
//         ),
//         const SizedBox(height: 8),
//         const Text(
//           'Settings',
//           style: TextStyle(
//             fontSize: 40,
//             fontWeight: FontWeight.w300,
//             color: Colors.white,
//             letterSpacing: -1,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSectionLabel(String text) {
//     return Text(
//       text,
//       style: TextStyle(
//         fontFamily: 'monospace',
//         fontSize: 9,
//         letterSpacing: 3,
//         color: _accent.withOpacity(0.45),
//       ),
//     );
//   }

//   Widget _buildToggleCard({
//     required IconData icon,
//     required String title,
//     String? subtitle,
//     required bool value,
//     required Future<void> Function(bool) onChanged,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: _surface,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: value ? _accent.withOpacity(0.22) : _border,
//           width: 0.5,
//         ),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
//       child: Row(
//         children: [
//           Icon(icon, size: 18, color: value ? _accent : _dim),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w400,
//                     color: value
//                         ? Colors.white.withOpacity(0.9)
//                         : Colors.white.withOpacity(0.4),
//                   ),
//                 ),
//                 if (subtitle != null) ...[
//                   const SizedBox(height: 2),
//                   Text(
//                     subtitle,
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: Colors.white.withOpacity(0.25),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           const SizedBox(width: 12),
//           _GlowSwitch(value: value, onChanged: onChanged),
//         ],
//       ),
//     );
//   }

//   Widget _buildSliderCard({
//     required IconData icon,
//     required String title,
//     String? subtitle,
//     required double value,
//     required double min,
//     required double max,
//     required String displayValue,
//     required Future<void> Function(double) onChanged,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: _surface,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: _border, width: 0.5),
//       ),
//       padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, size: 18, color: _accent),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 13,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//               Text(
//                 displayValue,
//                 style: TextStyle(
//                   fontFamily: 'monospace',
//                   fontSize: 12,
//                   letterSpacing: 1,
//                   color: _accent,
//                 ),
//               ),
//             ],
//           ),
//           if (subtitle != null) ...[
//             const SizedBox(height: 2),
//             Padding(
//               padding: const EdgeInsets.only(left: 32),
//               child: Text(
//                 subtitle,
//                 style: TextStyle(
//                   fontSize: 11,
//                   color: Colors.white.withOpacity(0.25),
//                 ),
//               ),
//             ),
//           ],
//           const SizedBox(height: 6),
//           SliderTheme(
//             data: SliderThemeData(
//               trackHeight: 1.5,
//               activeTrackColor: _accent.withOpacity(0.7),
//               inactiveTrackColor: _border,
//               thumbColor: _accent,
//               thumbShape:
//                   const RoundSliderThumbShape(enabledThumbRadius: 6),
//               overlayShape: SliderComponentShape.noOverlay,
//             ),
//             child: Slider(
//               value: value,
//               min: min,
//               max: max,
//               onChanged: (v) => onChanged(v),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPreviewButton(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildSectionLabel('PREVIEW'),
//         const SizedBox(height: 10),
//         SizedBox(
//           width: double.infinity,
//           child: GestureDetector(
//             onTap: onPreview,
//             child: Container(
//               padding: const EdgeInsets.symmetric(vertical: 18),
//               decoration: BoxDecoration(
//                 color: _accent.withOpacity(0.08),
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(
//                   color: _accent.withOpacity(0.3),
//                   width: 0.5,
//                 ),
//               ),
//               child: const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.preview_rounded, color: _accent, size: 18),
//                   SizedBox(width: 10),
//                   Text(
//                     'PREVIEW CLOCK SCREEN',
//                     style: TextStyle(
//                       fontFamily: 'monospace',
//                       fontSize: 11,
//                       letterSpacing: 3,
//                       color: _accent,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Center(
//           child: Text(
//             'Tap to see the clock as it appears in dock mode',
//             style: TextStyle(
//               fontSize: 11,
//               color: Colors.white.withOpacity(0.2),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ── Custom glow toggle switch ──────────────────────────────────────────────

// class _GlowSwitch extends StatelessWidget {
//   final bool value;
//   final Future<void> Function(bool) onChanged;

//   const _GlowSwitch({required this.value, required this.onChanged});

//   static const _accent = Color(0xFF00FFA8);

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () => onChanged(!value),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 250),
//         width: 44,
//         height: 24,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           color: value ? _accent.withOpacity(0.18) : const Color(0xFF1A2020),
//           border: Border.all(
//             color: value ? _accent.withOpacity(0.5) : const Color(0xFF2A3540),
//             width: 0.5,
//           ),
//         ),
//         child: Stack(
//           children: [
//             AnimatedPositioned(
//               duration: const Duration(milliseconds: 250),
//               curve: Curves.easeOut,
//               left: value ? 22 : 2,
//               top: 2,
//               child: Container(
//                 width: 18,
//                 height: 18,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: value ? _accent : const Color(0xFF3A4A50),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
 */
