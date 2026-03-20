import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class HomeWidgetService {
  static const _appGroupId = 'group.com.example.charging_clock';
  static const _androidWidgetName = 'ClockWidgetProvider';
  static const _iOSWidgetName = 'ClockWidget';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> updateWidget() async {
    final now = DateTime.now();
    final h24 = DateFormat('HH:mm').format(now);
    final h12 = DateFormat('hh:mm a').format(now);
    final seconds = DateFormat('ss').format(now);
    final date = DateFormat('EEE, d MMM').format(now).toUpperCase();
    final dayOfWeek = DateFormat('EEEE').format(now).toUpperCase();

    await HomeWidget.saveWidgetData('time_24h', h24);
    await HomeWidget.saveWidgetData('time_12h', h12);
    await HomeWidget.saveWidgetData('seconds', seconds);
    await HomeWidget.saveWidgetData('date_str', date);
    await HomeWidget.saveWidgetData('day_of_week', dayOfWeek);
    await HomeWidget.saveWidgetData('timestamp', now.millisecondsSinceEpoch);

    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
      iOSName: _iOSWidgetName,
    );
  }

  static Future<void> registerBackgroundUpdate() async {
    // Register a periodic background callback so the widget updates
    // even when the app is closed.
    await HomeWidget.registerBackgroundCallback(backgroundCallback);
  }
}

/// Top-level function required by home_widget for background updates.
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  await HomeWidgetService.updateWidget();
}
