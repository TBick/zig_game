const std = @import("std");

/// Manages game logic timing with fixed tick rate
pub const TickScheduler = struct {
    tick_rate: f64, // Ticks per second
    tick_duration: f64, // Duration of one tick in seconds
    accumulator: f64, // Time accumulator
    current_tick: u64, // Global tick counter
    ticks_this_frame: u32, // Number of ticks processed this frame

    /// Initialize the tick scheduler
    pub fn init(tick_rate: f64) TickScheduler {
        return TickScheduler{
            .tick_rate = tick_rate,
            .tick_duration = 1.0 / tick_rate,
            .accumulator = 0.0,
            .current_tick = 0,
            .ticks_this_frame = 0,
        };
    }

    /// Update the scheduler with delta time and return number of ticks to process
    pub fn update(self: *TickScheduler, delta_time: f64) u32 {
        self.accumulator += delta_time;
        self.ticks_this_frame = 0;

        // Process all accumulated ticks (with safety limit to prevent spiral of death)
        const max_ticks_per_frame: u32 = 5;
        while (self.accumulator >= self.tick_duration and self.ticks_this_frame < max_ticks_per_frame) {
            self.accumulator -= self.tick_duration;
            self.current_tick += 1;
            self.ticks_this_frame += 1;
        }

        // If we hit the max limit, dump excess time to prevent accumulator buildup
        if (self.ticks_this_frame >= max_ticks_per_frame and self.accumulator >= self.tick_duration) {
            self.accumulator = 0.0;
        }

        return self.ticks_this_frame;
    }

    /// Get current tick number
    pub fn getCurrentTick(self: *const TickScheduler) u64 {
        return self.current_tick;
    }

    /// Get tick rate (ticks per second)
    pub fn getTickRate(self: *const TickScheduler) f64 {
        return self.tick_rate;
    }

    /// Get alpha for interpolation (0.0 to 1.0, how far between current and next tick)
    pub fn getAlpha(self: *const TickScheduler) f32 {
        return @floatCast(self.accumulator / self.tick_duration);
    }

    /// Reset the tick counter and accumulator
    pub fn reset(self: *TickScheduler) void {
        self.accumulator = 0.0;
        self.current_tick = 0;
        self.ticks_this_frame = 0;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "TickScheduler.init sets correct values" {
    const scheduler = TickScheduler.init(2.0);

    try std.testing.expectEqual(@as(f64, 2.0), scheduler.tick_rate);
    try std.testing.expectEqual(@as(f64, 0.5), scheduler.tick_duration);
    try std.testing.expectEqual(@as(f64, 0.0), scheduler.accumulator);
    try std.testing.expectEqual(@as(u64, 0), scheduler.current_tick);
}

test "TickScheduler.update processes ticks correctly" {
    var scheduler = TickScheduler.init(2.0); // 2 ticks/sec = 0.5s per tick

    // First frame: 0.3s elapsed, no tick yet
    var ticks = scheduler.update(0.3);
    try std.testing.expectEqual(@as(u32, 0), ticks);
    try std.testing.expectEqual(@as(u64, 0), scheduler.current_tick);
    try std.testing.expectEqual(@as(f64, 0.3), scheduler.accumulator);

    // Second frame: 0.3s more = 0.6s total, should trigger 1 tick
    ticks = scheduler.update(0.3);
    try std.testing.expectEqual(@as(u32, 1), ticks);
    try std.testing.expectEqual(@as(u64, 1), scheduler.current_tick);
    try std.testing.expectApproxEqAbs(@as(f64, 0.1), scheduler.accumulator, 0.0001);
}

test "TickScheduler.update handles multiple ticks in one frame" {
    var scheduler = TickScheduler.init(2.0);

    // Simulate 1.2 seconds passing (should trigger 2 ticks)
    const ticks = scheduler.update(1.2);
    try std.testing.expectEqual(@as(u32, 2), ticks);
    try std.testing.expectEqual(@as(u64, 2), scheduler.current_tick);
    try std.testing.expectApproxEqAbs(@as(f64, 0.2), scheduler.accumulator, 0.0001);
}

test "TickScheduler.update limits ticks per frame" {
    var scheduler = TickScheduler.init(10.0); // 10 ticks/sec = 0.1s per tick

    // Simulate 1.0 second passing (would be 10 ticks, but limited to 5)
    const ticks = scheduler.update(1.0);
    try std.testing.expectEqual(@as(u32, 5), ticks);
    try std.testing.expectEqual(@as(u64, 5), scheduler.current_tick);
    try std.testing.expectEqual(@as(f64, 0.0), scheduler.accumulator); // Excess dumped
}

test "TickScheduler.getAlpha returns interpolation factor" {
    var scheduler = TickScheduler.init(2.0); // 0.5s per tick

    // No time passed
    try std.testing.expectEqual(@as(f32, 0.0), scheduler.getAlpha());

    // Half a tick passed
    _ = scheduler.update(0.25);
    try std.testing.expectApproxEqAbs(@as(f32, 0.5), scheduler.getAlpha(), 0.0001);

    // Just before a tick
    _ = scheduler.update(0.24);
    try std.testing.expectApproxEqAbs(@as(f32, 0.98), scheduler.getAlpha(), 0.01);
}

test "TickScheduler.reset clears state" {
    var scheduler = TickScheduler.init(2.0);

    _ = scheduler.update(1.0);
    try std.testing.expect(scheduler.current_tick > 0);

    scheduler.reset();
    try std.testing.expectEqual(@as(u64, 0), scheduler.current_tick);
    try std.testing.expectEqual(@as(f64, 0.0), scheduler.accumulator);
    try std.testing.expectEqual(@as(u32, 0), scheduler.ticks_this_frame);
}

test "TickScheduler with different tick rates" {
    // Test 3 ticks/sec
    var scheduler3 = TickScheduler.init(3.0);
    try std.testing.expectApproxEqAbs(@as(f64, 0.333333), scheduler3.tick_duration, 0.0001);

    const ticks3 = scheduler3.update(1.0);
    try std.testing.expectEqual(@as(u32, 3), ticks3);

    // Test 60 ticks/sec (frame-locked)
    var scheduler60 = TickScheduler.init(60.0);
    try std.testing.expectApproxEqAbs(@as(f64, 0.01666), scheduler60.tick_duration, 0.001);

    const ticks60 = scheduler60.update(0.0166);
    try std.testing.expectEqual(@as(u32, 0), ticks60); // Just shy of one tick
}
