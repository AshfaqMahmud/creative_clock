import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/app_settings.dart';

class HomeWidgetService {
  static const _appGroupId = 'group.com.example.charging_clock';
  static const _androidWidgetName = 'ClockWidgetProvider';
  static const _iOSWidgetName = 'ClockWidget';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> updateWidget({AppSettings? settings}) async {
    final now = DateTime.now();
    final use24h = settings?.widgetShow24h ?? true;
    final showSeconds = settings?.widgetShowSeconds ?? true;
    final showDate = settings?.widgetShowDate ?? true;
    final showDay = settings?.widgetShowDay ?? true;

    final timeStr = use24h
        ? DateFormat('HH:mm').format(now)
        : DateFormat('hh:mm').format(now);
    final amPm = use24h ? '' : DateFormat('a').format(now);
    final seconds = DateFormat('ss').format(now);
    final dateStr = DateFormat('EEE, d MMM').format(now).toUpperCase();
    final dayOfWeek = DateFormat('EEEE').format(now).toUpperCase();

    await HomeWidget.saveWidgetData('time_str', timeStr);
    await HomeWidget.saveWidgetData('am_pm', amPm);
    await HomeWidget.saveWidgetData('seconds', showSeconds ? seconds : '');
    await HomeWidget.saveWidgetData('date_str', showDate ? dateStr : '');
    await HomeWidget.saveWidgetData('day_of_week', showDay ? dayOfWeek : '');
    await HomeWidget.saveWidgetData('show_seconds', showSeconds);
    await HomeWidget.saveWidgetData('show_date', showDate);

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
