# iOS Widget Setup

The `ClockWidget` is a WidgetKit extension (requires iOS 15+).
Because Xcode project files (`.pbxproj`) are binary and can't be hand-authored
reliably, follow these steps once in Xcode after running `flutter create`.

---

## Step 1 — Add the Widget Extension target

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target** → choose **Widget Extension**.
3. Name it exactly **`ClockWidget`**.
4. Uncheck *"Include Configuration Intent"*.
5. When prompted to activate the scheme, click **Activate**.

## Step 2 — Replace generated Swift file

Delete the generated `ClockWidget.swift` Xcode created and replace it with
the file already provided at `ios/ClockWidget/ClockWidget.swift`.

## Step 3 — Set minimum deployment target

Select the **ClockWidget** target → **General** → set
*Minimum Deployments* to **iOS 15.0**.

## Step 4 — Add App Group capability (both targets)

For both **Runner** AND **ClockWidget**:

1. Select target → **Signing & Capabilities** → **+ Capability** → **App Groups**.
2. Add group ID: **`group.com.example.charging_clock`**

This shared container is how the Flutter app pushes time data to the widget.

## Step 5 — Replace AppDelegate.swift

Replace `ios/Runner/AppDelegate.swift` with the file already provided
at `ios/Runner/AppDelegate.swift`.

## Step 6 — Build & run

```bash
flutter run
```

The widget will appear in the iOS widget gallery under **"Charging Clock"**.
It supports Small, Medium, and Large sizes.

---

## How the widget updates

- The Flutter app calls `HomeWidgetService.updateWidget()` whenever the
  device status changes (charging, landscape tick).
- WidgetKit refreshes on its own schedule (roughly every minute via the
  `Timeline` policy set in `ClockProvider`).
- For live-updating seconds: iOS WidgetKit does **not** support sub-minute
  refresh. The seconds shown are a snapshot from the last Flutter update.
  For a live seconds hand, use a Lock Screen widget (iOS 16+) with
  `TimelineReloadPolicy.atEnd` and 1-second entries — see the
  `TimelineProvider` comments in `ClockWidget.swift`.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Widget shows `--:--` | App Group ID mismatch — double-check both targets |
| Build error `No such module 'WidgetKit'` | Deployment target must be iOS 15+ |
| Widget never updates | Open app at least once so Flutter can write to shared defaults |
