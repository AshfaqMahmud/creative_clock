import WidgetKit
import SwiftUI

// MARK: - Data model

struct ClockEntry: TimelineEntry {
    let date: Date
    let time24h: String
    let seconds: String
    let dateStr: String
    let dayOfWeek: String
}

// MARK: - Provider

struct ClockProvider: TimelineProvider {

    private let appGroupId = "group.com.example.charging_clock"

    func placeholder(in context: Context) -> ClockEntry {
        ClockEntry(
            date: Date(),
            time24h: "12:00",
            seconds: "00",
            dateStr: "MON, 1 JAN",
            dayOfWeek: "MONDAY"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ClockEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClockEntry>) -> Void) {
        let entry = makeEntry()
        // Refresh every minute so the widget stays in sync
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func makeEntry() -> ClockEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let now = Date()
        let formatter = DateFormatter()

        formatter.dateFormat = "HH:mm"
        let time24h = defaults?.string(forKey: "time_24h") ?? formatter.string(from: now)

        formatter.dateFormat = "ss"
        let seconds = defaults?.string(forKey: "seconds") ?? formatter.string(from: now)

        formatter.dateFormat = "EEE, d MMM"
        let dateStr = (defaults?.string(forKey: "date_str")
            ?? formatter.string(from: now)).uppercased()

        formatter.dateFormat = "EEEE"
        let dayOfWeek = (defaults?.string(forKey: "day_of_week")
            ?? formatter.string(from: now)).uppercased()

        return ClockEntry(
            date: now,
            time24h: time24h,
            seconds: seconds,
            dateStr: dateStr,
            dayOfWeek: dayOfWeek
        )
    }
}

// MARK: - Colors

private extension Color {
    static let accent      = Color(red: 0.00, green: 1.00, blue: 0.66)   // #00FFA8
    static let bgDark      = Color(red: 0.04, green: 0.047, blue: 0.063) // #0A0C10
    static let clockFace   = Color(red: 0.91, green: 0.973, blue: 0.941) // #E8F8F0
    static let dimGreen    = Color(red: 0.227, green: 0.431, blue: 0.345) // #3A6E58
    static let dimmerGreen = Color(red: 0.118, green: 0.188, blue: 0.157) // #1E3028
}

// MARK: - Corner bracket shape

struct CornerBrackets: Shape {
    let size: CGFloat = 12

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let s = size
        // top-left
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + s))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + s, y: rect.minY))
        // top-right
        p.move(to: CGPoint(x: rect.maxX - s, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + s))
        // bottom-left
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY - s))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + s, y: rect.maxY))
        // bottom-right
        p.move(to: CGPoint(x: rect.maxX - s, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - s))
        return p
    }
}

// MARK: - Widget view

struct ClockWidgetView: View {
    let entry: ClockEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            // Background
            Color.bgDark

            // Scanline texture using stripes
            Canvas { ctx, size in
                var y: CGFloat = 0
                while y < size.height {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 0.5)
                    ctx.fill(Path(rect), with: .color(Color.accent.opacity(0.018)))
                    y += 4
                }
            }

            // Ambient glow
            RadialGradient(
                colors: [Color.accent.opacity(0.06), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 100
            )

            // Corner brackets
            CornerBrackets()
                .stroke(Color.accent.opacity(0.2), lineWidth: 1)
                .padding(8)

            // Clock content
            VStack(spacing: 0) {
                // Day label
                Text(entry.dayOfWeek)
                    .font(.system(size: dayFontSize, weight: .regular, design: .monospaced))
                    .foregroundColor(.dimGreen)
                    .tracking(3)
                    .padding(.bottom, 2)

                // HH:MM
                Text(entry.time24h)
                    .font(.system(size: timeFontSize, weight: .thin, design: .monospaced))
                    .foregroundColor(.clockFace)
                    .tracking(4)
                    .shadow(color: Color.accent.opacity(0.2), radius: 8)

                // Seconds
                Text(entry.seconds)
                    .font(.system(size: secondsFontSize, weight: .regular, design: .monospaced))
                    .foregroundColor(.accent)
                    .tracking(6)
                    .padding(.top, 2)

                // Date
                Text(entry.dateStr)
                    .font(.system(size: dateFontSize, weight: .light, design: .monospaced))
                    .foregroundColor(.dimmerGreen)
                    .tracking(2)
                    .padding(.top, 6)
            }

            // Bottom accent line
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color.accent.opacity(0.3), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
                .frame(width: 80)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // Responsive font sizes per widget family
    var timeFontSize: CGFloat {
        switch family {
        case .systemSmall:  return 36
        case .systemMedium: return 52
        case .systemLarge:  return 72
        default:            return 52
        }
    }
    var dayFontSize: CGFloat    { family == .systemSmall ? 7  : 9  }
    var secondsFontSize: CGFloat { family == .systemSmall ? 11 : 14 }
    var dateFontSize: CGFloat   { family == .systemSmall ? 7  : 9  }
}

// MARK: - Widget configuration

@main
struct ClockWidget: Widget {
    let kind: String = "ClockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClockProvider()) { entry in
            ClockWidgetView(entry: entry)
        }
        .configurationDisplayName("Charging Clock")
        .description("Slick digital clock for your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

struct ClockWidget_Previews: PreviewProvider {
    static var previews: some View {
        let entry = ClockEntry(
            date: Date(),
            time24h: "22:47",
            seconds: "33",
            dateStr: "FRI, 20 MAR",
            dayOfWeek: "FRIDAY"
        )
        ClockWidgetView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        ClockWidgetView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        ClockWidgetView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
