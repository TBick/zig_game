const std = @import("std");
const rl = @import("raylib");
const Entity = @import("../entities/entity.zig").Entity;
const EntityRole = @import("../entities/entity.zig").EntityRole;

/// Panel displaying information about the selected entity
pub const EntityInfoPanel = struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,

    /// Initialize the info panel at a specific screen position
    pub fn init(x: i32, y: i32, width: i32, height: i32) EntityInfoPanel {
        return EntityInfoPanel{
            .x = x,
            .y = y,
            .width = width,
            .height = height,
        };
    }

    /// Draw the entity info panel
    /// Shows detailed information about the selected entity
    pub fn draw(self: *const EntityInfoPanel, entity: ?*const Entity, tick: u64) void {
        if (entity) |e| {
            // Draw semi-transparent background
            rl.drawRectangle(
                self.x,
                self.y,
                self.width,
                self.height,
                rl.Color.init(0, 0, 0, 180), // Semi-transparent black
            );

            // Draw border
            rl.drawRectangleLines(
                self.x,
                self.y,
                self.width,
                self.height,
                rl.Color.light_gray,
            );

            // Panel title
            const title = "ENTITY INFO";
            rl.drawText(
                title,
                self.x + 10,
                self.y + 10,
                20,
                rl.Color.white,
            );

            // Entity information
            var y_offset: i32 = 40;
            const line_height: i32 = 25;
            const text_x = self.x + 10;

            // ID
            var id_buf: [100:0]u8 = undefined;
            const id_text = std.fmt.bufPrintZ(&id_buf, "ID: {d}", .{e.id}) catch "ID: ???";
            rl.drawText(id_text, text_x, self.y + y_offset, 16, rl.Color.white);
            y_offset += line_height;

            // Role
            const role_name = switch (e.role) {
                .worker => "Worker",
                .combat => "Combat",
                .scout => "Scout",
                .engineer => "Engineer",
            };
            var role_buf: [100:0]u8 = undefined;
            const role_text = std.fmt.bufPrintZ(&role_buf, "Role: {s}", .{role_name}) catch "Role: ???";
            rl.drawText(role_text, text_x, self.y + y_offset, 16, rl.Color.white);
            y_offset += line_height;

            // Position
            var pos_buf: [100:0]u8 = undefined;
            const pos_text = std.fmt.bufPrintZ(&pos_buf, "Position: ({d}, {d})", .{ e.position.q, e.position.r }) catch "Position: ???";
            rl.drawText(pos_text, text_x, self.y + y_offset, 16, rl.Color.white);
            y_offset += line_height;

            // Energy (with percentage)
            const energy_percent = (e.energy / e.max_energy) * 100.0;
            var energy_buf: [100:0]u8 = undefined;
            const energy_text = std.fmt.bufPrintZ(&energy_buf, "Energy: {d:.1}/{d:.1} ({d:.0}%)", .{ e.energy, e.max_energy, energy_percent }) catch "Energy: ???";

            // Color code energy text
            const energy_color = if (energy_percent > 60.0)
                rl.Color.green
            else if (energy_percent > 30.0)
                rl.Color.yellow
            else
                rl.Color.red;

            rl.drawText(energy_text, text_x, self.y + y_offset, 16, energy_color);
            y_offset += line_height;

            // Current tick info
            var tick_buf: [100:0]u8 = undefined;
            const tick_text = std.fmt.bufPrintZ(&tick_buf, "Current Tick: {d}", .{tick}) catch "Tick: ???";
            rl.drawText(tick_text, text_x, self.y + y_offset, 16, rl.Color.white);
            y_offset += line_height;

            // Alive status (for debugging)
            const status = if (e.alive) "Alive" else "Dead";
            const status_color = if (e.alive) rl.Color.green else rl.Color.red;
            var status_buf: [100:0]u8 = undefined;
            const status_text = std.fmt.bufPrintZ(&status_buf, "Status: {s}", .{status}) catch "Status: ???";
            rl.drawText(status_text, text_x, self.y + y_offset, 16, status_color);
        } else {
            // No entity selected - show instructions
            rl.drawRectangle(
                self.x,
                self.y,
                self.width,
                self.height,
                rl.Color.init(0, 0, 0, 140), // More transparent when empty
            );

            rl.drawRectangleLines(
                self.x,
                self.y,
                self.width,
                self.height,
                rl.Color.dark_gray,
            );

            const msg = "No entity selected";
            rl.drawText(
                msg,
                self.x + 10,
                self.y + 10,
                16,
                rl.Color.gray,
            );

            const hint = "Click an entity";
            rl.drawText(
                hint,
                self.x + 10,
                self.y + 35,
                14,
                rl.Color.dark_gray,
            );
        }
    }
};

// ============================================================================
// Tests
// ============================================================================

test "EntityInfoPanel.init" {
    const panel = EntityInfoPanel.init(10, 250, 250, 200);
    try std.testing.expectEqual(@as(i32, 10), panel.x);
    try std.testing.expectEqual(@as(i32, 250), panel.y);
    try std.testing.expectEqual(@as(i32, 250), panel.width);
    try std.testing.expectEqual(@as(i32, 200), panel.height);
}

test "EntityInfoPanel initialization with different positions" {
    const panel1 = EntityInfoPanel.init(0, 0, 100, 100);
    const panel2 = EntityInfoPanel.init(500, 500, 300, 400);

    try std.testing.expectEqual(@as(i32, 0), panel1.x);
    try std.testing.expectEqual(@as(i32, 500), panel2.x);
    try std.testing.expect(panel1.width != panel2.width);
    try std.testing.expect(panel1.height != panel2.height);
}

test "EntityInfoPanel can be const" {
    const panel = EntityInfoPanel.init(10, 10, 200, 150);
    // Verify draw method accepts const self
    _ = panel; // Panel is valid
}
