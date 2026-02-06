const std = @import("std");
const rl = @import("raylib");

/// Identifier for debug windows - used for registration and lookup
pub const WindowId = enum {
    performance,
    entity_info,
    tile_info,
    // Future windows can be added here:
    // console,
    // pathfinding,
    // script_debugger,
    // resource_inspector,
};

/// A debug window that can display arbitrary content.
/// Windows can be opened/closed, and their state persists.
pub const DebugWindow = struct {
    /// Window identifier for lookup
    id: WindowId,

    /// Window title displayed in title bar (must be null-terminated for raylib)
    title: [:0]const u8,

    /// Position (top-left corner)
    x: i32,
    y: i32,

    /// Size
    width: i32,
    height: i32,

    /// Visibility state (persists when toggled)
    is_open: bool = true,

    /// Style constants
    pub const title_bar_height: i32 = 22;
    pub const padding: i32 = 8;
    pub const close_button_size: i32 = 16;

    /// Colors
    pub const bg_color = rl.Color.init(30, 30, 35, 240);
    pub const title_bg_color = rl.Color.init(45, 45, 55, 255);
    pub const title_text_color = rl.Color.white;
    pub const border_color = rl.Color.init(70, 70, 90, 255);
    pub const close_button_color = rl.Color.init(180, 60, 60, 255);
    pub const close_button_hover_color = rl.Color.init(220, 80, 80, 255);

    /// Initialize a debug window with the given parameters
    pub fn init(id: WindowId, title: [:0]const u8, x: i32, y: i32, width: i32, height: i32) DebugWindow {
        return DebugWindow{
            .id = id,
            .title = title,
            .x = x,
            .y = y,
            .width = width,
            .height = height,
            .is_open = true,
        };
    }

    /// Render the window frame (title bar, background, border)
    /// Returns the content area rectangle for the caller to render content into
    pub fn renderFrame(self: *const DebugWindow) ?ContentArea {
        if (!self.is_open) return null;

        // Draw window background
        rl.drawRectangle(self.x, self.y, self.width, self.height, bg_color);

        // Draw border
        rl.drawRectangleLines(self.x, self.y, self.width, self.height, border_color);

        // Draw title bar
        rl.drawRectangle(self.x, self.y, self.width, title_bar_height, title_bg_color);

        // Draw title text
        rl.drawText(
            self.title,
            self.x + 6,
            self.y + 4,
            14,
            title_text_color,
        );

        // Draw close button [X]
        const close_x = self.x + self.width - close_button_size - 3;
        const close_y = self.y + 3;

        // Check if mouse is over close button for hover effect
        const mx = rl.getMouseX();
        const my = rl.getMouseY();
        const hover = mx >= close_x and mx < close_x + close_button_size and
            my >= close_y and my < close_y + close_button_size;

        const btn_color = if (hover) close_button_hover_color else close_button_color;
        rl.drawRectangle(close_x, close_y, close_button_size, close_button_size, btn_color);
        rl.drawText("X", close_x + 4, close_y + 2, 12, rl.Color.white);

        // Return content area
        return ContentArea{
            .x = self.x + padding,
            .y = self.y + title_bar_height + padding,
            .width = self.width - (padding * 2),
            .height = self.height - title_bar_height - (padding * 2),
        };
    }

    /// Handle input for this window (close button click)
    /// Returns true if the window handled the input
    pub fn handleInput(self: *DebugWindow) bool {
        if (!self.is_open) return false;

        if (rl.isMouseButtonPressed(.mouse_button_left)) {
            const mx = rl.getMouseX();
            const my = rl.getMouseY();

            // Check close button
            const close_x = self.x + self.width - close_button_size - 3;
            const close_y = self.y + 3;

            if (mx >= close_x and mx < close_x + close_button_size and
                my >= close_y and my < close_y + close_button_size)
            {
                self.is_open = false;
                return true;
            }
        }

        return false;
    }

    /// Open this window
    pub fn open(self: *DebugWindow) void {
        self.is_open = true;
    }

    /// Close this window
    pub fn close(self: *DebugWindow) void {
        self.is_open = false;
    }

    /// Toggle this window's visibility
    pub fn toggle(self: *DebugWindow) void {
        self.is_open = !self.is_open;
    }

    /// Check if this window is currently open
    pub fn isOpen(self: *const DebugWindow) bool {
        return self.is_open;
    }
};

/// Rectangle describing the content area inside a window
pub const ContentArea = struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,

    /// Draw text at a position relative to content area
    pub fn drawText(self: ContentArea, text: [:0]const u8, rel_x: i32, rel_y: i32, font_size: i32, color: rl.Color) void {
        rl.drawText(text, self.x + rel_x, self.y + rel_y, font_size, color);
    }

    /// Draw text at a line number (for vertical list of items)
    pub fn drawTextLine(self: ContentArea, text: [:0]const u8, line: i32, font_size: i32, color: rl.Color) void {
        const line_height = font_size + 2;
        rl.drawText(text, self.x, self.y + (line * line_height), font_size, color);
    }
};

// ============================================================================
// Tests
// ============================================================================

test "DebugWindow.init creates window with correct properties" {
    const window = DebugWindow.init(.performance, "Test Window", 100, 200, 300, 400);
    try std.testing.expectEqual(WindowId.performance, window.id);
    try std.testing.expectEqualStrings("Test Window", window.title);
    try std.testing.expectEqual(@as(i32, 100), window.x);
    try std.testing.expectEqual(@as(i32, 200), window.y);
    try std.testing.expectEqual(@as(i32, 300), window.width);
    try std.testing.expectEqual(@as(i32, 400), window.height);
    try std.testing.expect(window.is_open);
}

test "DebugWindow.toggle changes visibility" {
    var window = DebugWindow.init(.entity_info, "Test", 0, 0, 100, 100);
    try std.testing.expect(window.is_open);

    window.toggle();
    try std.testing.expect(!window.is_open);

    window.toggle();
    try std.testing.expect(window.is_open);
}

test "DebugWindow.open and close" {
    var window = DebugWindow.init(.tile_info, "Test", 0, 0, 100, 100);

    window.close();
    try std.testing.expect(!window.is_open);

    window.open();
    try std.testing.expect(window.is_open);
}
