import Foundation
import CoreGraphics

var assertions = 0
func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    assertions += 1
    guard condition() else { fatalError(message) }
}

for (host, command) in [("toggle", URLCommand.toggle), ("on", .on), ("off", .off)] {
    expect(URLCommand(url: URL(string: "mxjiggler://\(host)")!) == command, "Command \(host)")
}
for input in ["https://toggle", "mxjiggler://unknown", "mxjiggler://on/path",
              "mxjiggler://on?off", "mxjiggler://user@on", "mxjiggler://on:12", "mxjiggler://on#off"] {
    expect(URLCommand(url: URL(string: input)!) == nil, "Reject malformed command: \(input)")
}
expect(!JigglePolicy.isDue(idle: 239, threshold: 240, elapsed: 1000, interval: 60), "Active user stays quiet")
expect(JigglePolicy.isDue(idle: 240, threshold: 240, elapsed: 60, interval: 60), "Idle threshold boundary")
expect(!JigglePolicy.isDue(idle: 500, threshold: 240, elapsed: 59, interval: 60), "Enforce interval")
expect(JigglePolicy.isDue(idle: 0, threshold: 0, elapsed: 60, interval: 60), "Periodic mode")
expect(!JigglePolicy.isDue(idle: .infinity, threshold: 240, elapsed: 60, interval: 60), "Reject invalid idle reading")

// Secondary displays may have negative coordinates or sit above the primary.
for bounds in [CGRect(x: 0, y: 0, width: 1920, height: 1080),
               CGRect(x: -1920, y: 0, width: 1920, height: 1080),
               CGRect(x: 0, y: -1080, width: 1920, height: 1080)] {
    for point in [CGPoint(x: bounds.minX, y: bounds.minY),
                  CGPoint(x: bounds.maxX - 1, y: bounds.maxY - 1)] {
        guard let moved = JigglePolicy.destination(from: point, in: bounds) else { fatalError("Missing destination") }
        expect(bounds.contains(moved), "Stay on original display")
        expect(hypot(moved.x - point.x, moved.y - point.y) == 2, "Move exactly two coordinate units")
    }
}
expect(JigglePolicy.destination(from: CGPoint(x: -1, y: 0), in: CGRect(x: 0, y: 0, width: 10, height: 10)) == nil,
       "Reject position outside display")
print("Passed \(assertions) assertions")
