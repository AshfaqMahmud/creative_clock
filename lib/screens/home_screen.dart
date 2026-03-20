import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../services/device_monitor_service.dart';
import '../services/home_widget_service.dart';
import 'clock_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DeviceMonitorService _monitor;
  int _tab = 0;
  bool _clockVisible = false;
  DeviceStatus? _status;

  static const _accent = Color(0xFF00FFA8);
  static const _bg = Color(0xFF0A0C10);

  @override
  void initState() {
    super.initState();
    HomeWidgetService.init();

    final settings = context.read<AppSettings>();
    _monitor =
        DeviceMonitorService(landscapeThreshold: settings.landscapeThreshold);
    _monitor.start();

    _monitor.statusStream.listen((status) {
      if (!mounted) return;
      setState(() => _status = status);

      if (status.shouldShowClock &&
          !_clockVisible &&
          settings.autoDockEnabled) {
        _launchClock(isAuto: true);
      }

      // Keep home widget updated whenever status changes
      HomeWidgetService.updateWidget(settings: settings);
    });
  }

  @override
  void dispose() {
    _monitor.dispose();
    super.dispose();
  }

  Future<void> _launchClock({bool isAuto = false}) async {
    _clockVisible = true;

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (!mounted) return;

    final settings = context.read<AppSettings>();

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ClockScreen(
          monitor: _monitor,
          settings: settings,
          isAutoLaunch: isAuto,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );

    _clockVisible = false;
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: IndexedStack(
        index: _tab,
        children: [
          _MonitorTab(
            status: _status,
            onLaunch: () => _launchClock(isAuto: false),
          ),
          SettingsScreen(
            onPreview: () => _launchClock(isAuto: false),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ── Monitor Tab ────────────────────────────────────────────────────────────

class _MonitorTab extends StatelessWidget {
  final DeviceStatus? status;
  final VoidCallback onLaunch;

  const _MonitorTab({required this.status, required this.onLaunch});

  static const _accent = Color(0xFF00FFA8);
  static const _dim = Color(0xFF3A6E58);
  static const _surface = Color(0xFF111418);
  static const _border = Color(0xFF1E2535);

  @override
  Widget build(BuildContext context) {
    final s = status;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 40),
            _buildSensorCard(
              label: 'CHARGING',
              icon: Icons.bolt_rounded,
              active: s?.isCharging ?? false,
              value: s != null ? '${s.batteryLevel}%' : '--',
            ),
            const SizedBox(height: 12),
            _buildSensorCard(
              label: 'LANDSCAPE',
              icon: Icons.screen_rotation_rounded,
              active: s?.isLandscape ?? false,
              value: (s?.isLandscape ?? false) ? 'YES' : 'NO',
            ),
            const SizedBox(height: 12),
            _buildDockStatus(s),
            const Spacer(),
            _buildLaunchButton(context),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
          'Dock\nMonitor',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            height: 1.1,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _buildSensorCard({
    required String label,
    required IconData icon,
    required bool active,
    required String value,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: active ? _accent.withOpacity(0.07) : _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? _accent.withOpacity(0.28) : _border,
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon,
              size: 18, color: active ? _accent : const Color(0xFF3A4A50)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  letterSpacing: 3,
                  color: active
                      ? Colors.white.withOpacity(0.8)
                      : const Color(0xFF3A4A50),
                )),
          ),
          Text(value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                letterSpacing: 2,
                color: active ? _accent : const Color(0xFF3A4A50),
              )),
        ],
      ),
    );
  }

  Widget _buildDockStatus(DeviceStatus? s) {
    final both = s?.shouldShowClock ?? false;
    final autoDock = true; // visual only here; logic is in HomeScreen
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: both ? _accent.withOpacity(0.35) : _border,
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: both ? _accent : const Color(0xFF2A3540),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              both
                  ? 'DOCK MODE ACTIVE — LAUNCHING'
                  : 'WAITING FOR DOCK CONDITIONS',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                letterSpacing: 2.5,
                color: both ? _accent : const Color(0xFF3A4A50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaunchButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onLaunch,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _accent.withOpacity(0.35),
              width: 0.5,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, color: _accent, size: 18),
              SizedBox(width: 10),
              Text(
                'LAUNCH CLOCK NOW',
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

// ── Bottom Nav ─────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.current, required this.onTap});

  static const _accent = Color(0xFF00FFA8);
  static const _border = Color(0xFF1E2535);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1014),
        border: Border(top: BorderSide(color: _border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.sensors_rounded,
              label: 'MONITOR',
              active: current == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.tune_rounded,
              label: 'SETTINGS',
              active: current == 1,
              onTap: () => onTap(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  static const _accent = Color(0xFF00FFA8);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20, color: active ? _accent : const Color(0xFF3A4A50)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  letterSpacing: 2,
                  color: active ? _accent : const Color(0xFF3A4A50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
