const std = @import("std");
const rl = @import("raylib");

/// Debug overlay for displaying performance metrics
pub const DebugOverlay = struct {
    enabled: bool,
    frame_times: [60]f32, // Rolling buffer for frame times
    frame_index: usize,
    last_update_time: f64,
    frame_count: u64, // Total frames processed

    pub fn init() DebugOverlay {
        return DebugOverlay{
            .enabled = true, // Start enabled for development
            .frame_times = [_]f32{0.0} ** 60,
            .frame_index = 0,
            .last_update_time = 0.0,
            .frame_count = 0,
        };
    }

    /// Toggle overlay visibility
    pub fn toggle(self: *DebugOverlay) void {
        self.enabled = !self.enabled;
    }

    /// Update overlay state (call once per frame)
    pub fn update(self: *DebugOverlay) void {
        if (!self.enabled) return;

        // Record frame time
        const frame_time = rl.getFrameTime();
        self.frame_times[self.frame_index] = frame_time * 1000.0; // Convert to ms
        self.frame_index = (self.frame_index + 1) % self.frame_times.len;
        self.frame_count += 1;

        self.last_update_time = rl.getTime();

        // Debug output every 60 frames
        if (self.frame_count % 60 == 0) {
            std.debug.print("Debug overlay frame {d}: FPS={d}, frame_time={d:.2}ms\n", .{
                self.frame_count,
                rl.getFPS(),
                frame_time * 1000.0,
            });
        }
    }

    /// Draw the overlay (call during rendering)
    pub fn draw(self: *DebugOverlay, entity_count: usize, tick_rate: ?f32) void {
        if (!self.enabled) return;

        const x: i32 = 10;
        var y: i32 = 10;
        const line_height: i32 = 20;
        const font_size: i32 = 16;

        // Background panel
        rl.drawRectangle(x - 5, y - 5, 280, 150, rl.Color.init(0, 0, 0, 180));

        // Title
        rl.drawText("DEBUG OVERLAY (F3 to toggle)", x, y, font_size, rl.Color.yellow);
        y += line_height + 5;

        // FPS
        const fps = rl.getFPS();
        var buf: [100:0]u8 = undefined;
        const fps_text = std.fmt.bufPrintZ(&buf, "FPS: {d}", .{fps}) catch "Error";
        const fps_color = if (fps >= 60) rl.Color.green else if (fps >= 30) rl.Color.yellow else rl.Color.red;
        rl.drawText(fps_text, x, y, font_size, fps_color);
        y += line_height;

        // Frame time (average of last 60 frames)
        const avg_frame_time = self.getAverageFrameTime();
        const ft_text = std.fmt.bufPrintZ(&buf, "Frame Time: {d:.2} ms", .{avg_frame_time}) catch "Error";
        const ft_color = if (avg_frame_time <= 16.67) rl.Color.green else if (avg_frame_time <= 33.33) rl.Color.yellow else rl.Color.red;
        rl.drawText(ft_text, x, y, font_size, ft_color);
        y += line_height;

        // Entity count
        const entity_text = std.fmt.bufPrintZ(&buf, "Entities: {d}", .{entity_count}) catch "Error";
        rl.drawText(entity_text, x, y, font_size, rl.Color.white);
        y += line_height;

        // Tick rate (if available)
        if (tick_rate) |rate| {
            const tick_text = std.fmt.bufPrintZ(&buf, "Tick Rate: {d:.1} tps", .{rate}) catch "Error";
            rl.drawText(tick_text, x, y, font_size, rl.Color.white);
            y += line_height;
        } else {
            rl.drawText("Tick Rate: N/A", x, y, font_size, rl.Color.gray);
            y += line_height;
        }

        // Memory usage (approximate)
        const memory_mb = self.getMemoryUsage();
        const mem_text = std.fmt.bufPrintZ(&buf, "Memory: {d:.1} MB", .{memory_mb}) catch "Error";
        rl.drawText(mem_text, x, y, font_size, rl.Color.white);
    }

    /// Get average frame time from rolling buffer
    fn getAverageFrameTime(self: *DebugOverlay) f32 {
        var sum: f32 = 0.0;
        for (self.frame_times) |ft| {
            sum += ft;
        }
        return sum / @as(f32, @floatFromInt(self.frame_times.len));
    }

    /// Get approximate memory usage in MB
    fn getMemoryUsage(self: *DebugOverlay) f32 {
        _ = self;
        // TODO: Implement proper memory tracking
        // For now, return a placeholder
        return 0.0;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "DebugOverlay initialization" {
    const overlay = DebugOverlay.init();
    try std.testing.expect(overlay.enabled);
    try std.testing.expectEqual(@as(usize, 0), overlay.frame_index);
}

test "DebugOverlay toggle" {
    var overlay = DebugOverlay.init();
    const initial = overlay.enabled;
    overlay.toggle();
    try std.testing.expect(overlay.enabled != initial);
    overlay.toggle();
    try std.testing.expect(overlay.enabled == initial);
}

test "DebugOverlay average frame time" {
    var overlay = DebugOverlay.init();

    // Fill with known values
    for (0..overlay.frame_times.len) |i| {
        overlay.frame_times[i] = 16.67; // 60 FPS
    }

    const avg = overlay.getAverageFrameTime();
    try std.testing.expect(@abs(avg - 16.67) < 0.01);
}
