import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onPreview;

  const SettingsScreen({super.key, required this.onPreview});

  static const _accent = Color(0xFF00FFA8);
  static const _surface = Color(0xFF111418);
  static const _border = Color(0xFF1E2535);
  static const _dim = Color(0xFF3A4A50);

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

                _buildSectionLabel('DOCK BEHAVIOUR'),
                const SizedBox(height: 10),
                _buildToggleCard(
                  icon: Icons.dock_rounded,
                  title: 'Auto-launch in dock mode',
                  subtitle: 'Opens clock when charging + landscape detected',
                  value: settings.autoDockEnabled,
                  onChanged: settings.setAutoDock,
                ),
                const SizedBox(height: 28),

                _buildSectionLabel('CLOCK DISPLAY'),
                const SizedBox(height: 10),
                _buildToggleCard(
                  icon: Icons.access_time_rounded,
                  title: '24-hour format',
                  subtitle: 'Show time in 24h instead of 12h AM/PM',
                  value: settings.show24h,
                  onChanged: settings.setShow24h,
                ),
                const SizedBox(height: 8),
                _buildToggleCard(
                  icon: Icons.timer_outlined,
                  title: 'Show seconds',
                  subtitle: 'Display the seconds counter below the time',
                  value: settings.showSeconds,
                  onChanged: settings.setShowSeconds,
                ),
                const SizedBox(height: 8),
                _buildToggleCard(
                  icon: Icons.calendar_today_rounded,
                  title: 'Show date',
                  subtitle: 'Display day and date below the clock',
                  value: settings.showDate,
                  onChanged: settings.setShowDate,
                ),
                const SizedBox(height: 28),

                _buildSectionLabel('SCREEN'),
                const SizedBox(height: 10),
                _buildSliderCard(
                  icon: Icons.brightness_medium_rounded,
                  title: 'Clock screen brightness',
                  value: settings.screenBrightness,
                  min: 0.1,
                  max: 1.0,
                  displayValue:
                      '${(settings.screenBrightness * 100).round()}%',
                  onChanged: settings.setScreenBrightness,
                ),
                const SizedBox(height: 28),

                _buildSectionLabel('SENSOR SENSITIVITY'),
                const SizedBox(height: 10),
                _buildSliderCard(
                  icon: Icons.screen_rotation_rounded,
                  title: 'Landscape detection threshold',
                  subtitle: _thresholdLabel(settings.landscapeThreshold),
                  value: settings.landscapeThreshold,
                  min: 1.0,
                  max: 2.0,
                  displayValue: settings.landscapeThreshold.toStringAsFixed(1),
                  onChanged: settings.setLandscapeThreshold,
                ),
                const SizedBox(height: 36),

                _buildPreviewButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

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

  Widget _buildSectionLabel(String text) {
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

  Widget _buildToggleCard({
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
                    fontWeight: FontWeight.w400,
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
                      color: Colors.white.withOpacity(0.25),
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

  Widget _buildSliderCard({
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                displayValue,
                style: TextStyle(
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
                  color: Colors.white.withOpacity(0.25),
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
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
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

  Widget _buildPreviewButton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('PREVIEW'),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: onPreview,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _accent.withOpacity(0.3),
                  width: 0.5,
                ),
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
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Tap to see the clock as it appears in dock mode',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Custom glow toggle switch ──────────────────────────────────────────────

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
