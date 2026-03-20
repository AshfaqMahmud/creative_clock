import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';

class DeviceMonitorService {
  final Battery _battery = Battery();
  final StreamController<DeviceStatus> _controller =
      StreamController<DeviceStatus>.broadcast();

  Stream<DeviceStatus> get statusStream => _controller.stream;

  bool _isCharging = false;
  bool _isLandscape = false;
  int _batteryLevel = 0;
  double landscapeThreshold;

  StreamSubscription<BatteryState>? _batterySub;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  DeviceMonitorService({this.landscapeThreshold = 1.3});

  void start() {
    _fetchBatteryLevel();

    _batterySub = _battery.onBatteryStateChanged.listen((BatteryState state) {
      _isCharging = state == BatteryState.charging || state == BatteryState.full;
      _fetchBatteryLevel();
      _emit();
    });

    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 500),
    ).listen((AccelerometerEvent event) {
      final absX = event.x.abs();
      final absY = event.y.abs();
      final wasLandscape = _isLandscape;
      _isLandscape = absX > absY * landscapeThreshold && absX > 4.0;
      if (_isLandscape != wasLandscape) _emit();
    });

    _battery.batteryState.then((state) {
      _isCharging = state == BatteryState.charging || state == BatteryState.full;
      _emit();
    });
  }

  Future<void> _fetchBatteryLevel() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      _emit();
    } catch (_) {}
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(DeviceStatus(
        isCharging: _isCharging,
        isLandscape: _isLandscape,
        batteryLevel: _batteryLevel,
      ));
    }
  }

  DeviceStatus get currentStatus => DeviceStatus(
        isCharging: _isCharging,
        isLandscape: _isLandscape,
        batteryLevel: _batteryLevel,
      );

  void dispose() {
    _batterySub?.cancel();
    _accelSub?.cancel();
    _controller.close();
  }
}

class DeviceStatus {
  final bool isCharging;
  final bool isLandscape;
  final int batteryLevel;

  const DeviceStatus({
    required this.isCharging,
    required this.isLandscape,
    required this.batteryLevel,
  });

  bool get shouldShowClock => isCharging && isLandscape;
}
