const std = @import("std");
const rl = @import("raylib");
const window = @import("../window.zig");
const DebugWindow = window.DebugWindow;
const WindowId = window.WindowId;
const Entity = @import("../../entities/entity.zig").Entity;

/// Entity information debug window
/// Displays detailed information about the selected entity
pub const EntityInfoWindow = struct {
    /// The window container
    win: DebugWindow,

    /// Currently selected entity (may be null)
    selected_entity: ?*const Entity,

    /// Current game tick (for display)
    current_tick: u64,

    /// Initialize the entity info window
    pub fn init() EntityInfoWindow {
        return EntityInfoWindow{
            .win = DebugWindow.init(
                .entity_info,
                "Entity Info",
                10, // x
                160, // y (below performance window)
                200, // width
                180, // height
            ),
            .selected_entity = null,
            .current_tick = 0,
        };
    }

    /// Set the selected entity (auto-opens window if entity is selected)
    pub fn setEntity(self: *EntityInfoWindow, entity: ?*const Entity) void {
        self.selected_entity = entity;
        if (entity != null and !self.win.is_open) {
            self.win.open();
        }
    }

    /// Set the current tick for display
    pub fn setTick(self: *EntityInfoWindow, tick: u64) void {
        self.current_tick = tick;
    }

    /// Clear the selection
    pub fn clearSelection(self: *EntityInfoWindow) void {
        self.selected_entity = null;
    }

    /// Render the window and its contents
    pub fn render(self: *EntityInfoWindow) void {
        const area = self.win.renderFrame() orelse return;

        const line_height: i32 = 20;
        const font_size: i32 = 14;
        var y: i32 = 0;

        if (self.selected_entity) |e| {
            var buf: [64:0]u8 = undefined;

            // ID
            const id_text = std.fmt.bufPrintZ(&buf, "ID: {d}", .{e.id}) catch "ID: ???";
            area.drawText(id_text, 0, y, font_size, rl.Color.white);
            y += line_height;

            // Role
            const role_name = switch (e.role) {
                .worker => "Worker",
                .combat => "Combat",
                .scout => "Scout",
                .engineer => "Engineer",
            };
            const role_text = std.fmt.bufPrintZ(&buf, "Role: {s}", .{role_name}) catch "Role: ???";
            area.drawText(role_text, 0, y, font_size, rl.Color.white);
            y += line_height;

            // Position
            const pos_text = std.fmt.bufPrintZ(&buf, "Pos: ({d}, {d})", .{ e.position.q, e.position.r }) catch "Pos: ???";
            area.drawText(pos_text, 0, y, font_size, rl.Color.white);
            y += line_height;

            // Energy with color coding
            const energy_percent = (e.energy / e.max_energy) * 100.0;
            const energy_text = std.fmt.bufPrintZ(&buf, "Energy: {d:.0}%", .{energy_percent}) catch "Energy: ???";
            const energy_color = if (energy_percent > 60.0)
                rl.Color.green
            else if (energy_percent > 30.0)
                rl.Color.yellow
            else
                rl.Color.red;
            area.drawText(energy_text, 0, y, font_size, energy_color);
            y += line_height;

            // Tick
            const tick_text = std.fmt.bufPrintZ(&buf, "Tick: {d}", .{self.current_tick}) catch "Tick: ???";
            area.drawText(tick_text, 0, y, font_size, rl.Color.white);
            y += line_height;

            // Status
            const status = if (e.alive) "Alive" else "Dead";
            const status_color = if (e.alive) rl.Color.green else rl.Color.red;
            const status_text = std.fmt.bufPrintZ(&buf, "Status: {s}", .{status}) catch "Status: ???";
            area.drawText(status_text, 0, y, font_size, status_color);
        } else {
            area.drawText("No entity selected", 0, 0, font_size, rl.Color.gray);
            area.drawText("Click an entity", 0, line_height, 12, rl.Color.dark_gray);
        }
    }

    /// Handle input for this window
    pub fn handleInput(self: *EntityInfoWindow) bool {
        return self.win.handleInput();
    }

    /// Get the window reference (for WindowManager registration)
    pub fn getWindow(self: *EntityInfoWindow) *DebugWindow {
        return &self.win;
    }
};

// ============================================================================
// Tests
// ============================================================================

test "EntityInfoWindow.init creates window at correct position" {
    const eiw = EntityInfoWindow.init();
    try std.testing.expectEqual(WindowId.entity_info, eiw.win.id);
    try std.testing.expectEqual(@as(i32, 10), eiw.win.x);
    try std.testing.expectEqual(@as(i32, 160), eiw.win.y);
    try std.testing.expect(eiw.selected_entity == null);
}

test "EntityInfoWindow.setTick" {
    var eiw = EntityInfoWindow.init();
    eiw.setTick(42);
    try std.testing.expectEqual(@as(u64, 42), eiw.current_tick);
}

test "EntityInfoWindow.clearSelection" {
    var eiw = EntityInfoWindow.init();
    eiw.clearSelection();
    try std.testing.expect(eiw.selected_entity == null);
}
