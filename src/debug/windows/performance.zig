const std = @import("std");
const rl = @import("raylib");
const window = @import("../window.zig");
const DebugWindow = window.DebugWindow;
const WindowId = window.WindowId;

/// Performance metrics debug window
/// Displays FPS, frame time, entity count, and tick rate
pub const PerformanceWindow = struct {
    /// The window container
    win: DebugWindow,

    /// Rolling buffer for frame times (last 60 frames)
    frame_times: [60]f32,
    frame_index: usize,
    frame_count: u64,

    /// Cached metrics for display
    entity_count: usize,
    tick_rate: ?f32,

    /// Initialize the performance window
    pub fn init() PerformanceWindow {
        return PerformanceWindow{
            .win = DebugWindow.init(
                .performance,
                "Performance",
                10, // x
                10, // y
                200, // width
                140, // height
            ),
            .frame_times = [_]f32{0.0} ** 60,
            .frame_index = 0,
            .frame_count = 0,
            .entity_count = 0,
            .tick_rate = null,
        };
    }

    /// Update metrics (call once per frame)
    pub fn update(self: *PerformanceWindow) void {
        const frame_time = rl.getFrameTime();
        self.frame_times[self.frame_index] = frame_time * 1000.0; // Convert to ms
        self.frame_index = (self.frame_index + 1) % self.frame_times.len;
        self.frame_count += 1;
    }

    /// Set the entity count for display
    pub fn setEntityCount(self: *PerformanceWindow, count: usize) void {
        self.entity_count = count;
    }

    /// Set the tick rate for display
    pub fn setTickRate(self: *PerformanceWindow, rate: ?f32) void {
        self.tick_rate = rate;
    }

    /// Render the window and its contents
    pub fn render(self: *PerformanceWindow) void {
        const area = self.win.renderFrame() orelse return;

        var y: i32 = 0;
        const line_height: i32 = 18;
        const font_size: i32 = 14;

        // FPS
        const fps = rl.getFPS();
        var buf: [64:0]u8 = undefined;
        const fps_text = std.fmt.bufPrintZ(&buf, "FPS: {d}", .{fps}) catch "FPS: ???";
        const fps_color = if (fps >= 60) rl.Color.green else if (fps >= 30) rl.Color.yellow else rl.Color.red;
        area.drawText(fps_text, 0, y, font_size, fps_color);
        y += line_height;

        // Frame time
        const avg_frame_time = self.getAverageFrameTime();
        const ft_text = std.fmt.bufPrintZ(&buf, "Frame: {d:.2} ms", .{avg_frame_time}) catch "Frame: ???";
        const ft_color = if (avg_frame_time <= 16.67) rl.Color.green else if (avg_frame_time <= 33.33) rl.Color.yellow else rl.Color.red;
        area.drawText(ft_text, 0, y, font_size, ft_color);
        y += line_height;

        // Entity count
        const entity_text = std.fmt.bufPrintZ(&buf, "Entities: {d}", .{self.entity_count}) catch "Entities: ???";
        area.drawText(entity_text, 0, y, font_size, rl.Color.white);
        y += line_height;

        // Tick rate
        if (self.tick_rate) |rate| {
            const tick_text = std.fmt.bufPrintZ(&buf, "Tick Rate: {d:.1} tps", .{rate}) catch "Tick: ???";
            area.drawText(tick_text, 0, y, font_size, rl.Color.white);
        } else {
            area.drawText("Tick Rate: N/A", 0, y, font_size, rl.Color.gray);
        }
    }

    /// Handle input for this window
    pub fn handleInput(self: *PerformanceWindow) bool {
        return self.win.handleInput();
    }

    /// Get the window reference (for WindowManager registration)
    pub fn getWindow(self: *PerformanceWindow) *DebugWindow {
        return &self.win;
    }

    /// Get average frame time from rolling buffer
    fn getAverageFrameTime(self: *const PerformanceWindow) f32 {
        var sum: f32 = 0.0;
        for (self.frame_times) |ft| {
            sum += ft;
        }
        return sum / @as(f32, @floatFromInt(self.frame_times.len));
    }
};

// ============================================================================
// Tests
// ============================================================================

test "PerformanceWindow.init creates window at correct position" {
    const pw = PerformanceWindow.init();
    try std.testing.expectEqual(WindowId.performance, pw.win.id);
    try std.testing.expectEqual(@as(i32, 10), pw.win.x);
    try std.testing.expectEqual(@as(i32, 10), pw.win.y);
    try std.testing.expect(pw.win.is_open);
}

test "PerformanceWindow.setEntityCount and setTickRate" {
    var pw = PerformanceWindow.init();
    pw.setEntityCount(42);
    pw.setTickRate(2.5);

    try std.testing.expectEqual(@as(usize, 42), pw.entity_count);
    try std.testing.expectEqual(@as(?f32, 2.5), pw.tick_rate);
}

test "PerformanceWindow.getAverageFrameTime" {
    var pw = PerformanceWindow.init();

    // Fill with known values
    for (0..pw.frame_times.len) |i| {
        pw.frame_times[i] = 16.67;
    }

    const avg = pw.getAverageFrameTime();
    try std.testing.expect(@abs(avg - 16.67) < 0.01);
}
