const std = @import("std");
const window = @import("window.zig");
const DebugWindow = window.DebugWindow;
const WindowId = window.WindowId;

/// Manages all debug windows - handles registration, rendering, and input
pub const WindowManager = struct {
    /// Storage for registered windows (indexed by WindowId)
    windows: std.AutoHashMap(WindowId, *DebugWindow),

    /// Allocator for internal structures
    allocator: std.mem.Allocator,

    /// Initialize the window manager
    pub fn init(allocator: std.mem.Allocator) WindowManager {
        return WindowManager{
            .windows = std.AutoHashMap(WindowId, *DebugWindow).init(allocator),
            .allocator = allocator,
        };
    }

    /// Clean up resources
    pub fn deinit(self: *WindowManager) void {
        self.windows.deinit();
    }

    /// Register a window with the manager
    pub fn register(self: *WindowManager, win: *DebugWindow) void {
        self.windows.put(win.id, win) catch |err| {
            std.debug.print("Failed to register window: {}\n", .{err});
        };
    }

    /// Get a window by its ID
    pub fn get(self: *WindowManager, id: WindowId) ?*DebugWindow {
        return self.windows.get(id);
    }

    /// Render all registered windows
    /// Content rendering is handled by the window owners, not the manager
    pub fn renderAllFrames(self: *WindowManager) void {
        var it = self.windows.valueIterator();
        while (it.next()) |win_ptr| {
            _ = win_ptr.*.renderFrame();
        }
    }

    /// Handle input for all windows
    /// Returns true if any window handled the input
    pub fn handleInputAll(self: *WindowManager) bool {
        var handled = false;
        var it = self.windows.valueIterator();
        while (it.next()) |win_ptr| {
            if (win_ptr.*.handleInput()) {
                handled = true;
            }
        }
        return handled;
    }

    /// Toggle all windows (master toggle)
    /// If any window is open, close all. Otherwise, open all.
    pub fn toggleAll(self: *WindowManager) void {
        // Check if any window is open
        var any_open = false;
        var it = self.windows.valueIterator();
        while (it.next()) |win_ptr| {
            if (win_ptr.*.is_open) {
                any_open = true;
                break;
            }
        }

        // Toggle to opposite state
        const new_state = !any_open;
        var it2 = self.windows.valueIterator();
        while (it2.next()) |win_ptr| {
            win_ptr.*.is_open = new_state;
        }
    }

    /// Close all windows
    pub fn closeAll(self: *WindowManager) void {
        var it = self.windows.valueIterator();
        while (it.next()) |win_ptr| {
            win_ptr.*.is_open = false;
        }
    }

    /// Open all windows
    pub fn openAll(self: *WindowManager) void {
        var it = self.windows.valueIterator();
        while (it.next()) |win_ptr| {
            win_ptr.*.is_open = true;
        }
    }

    /// Open a specific window by ID
    pub fn openWindow(self: *WindowManager, id: WindowId) void {
        if (self.windows.get(id)) |win| {
            win.open();
        }
    }

    /// Close a specific window by ID
    pub fn closeWindow(self: *WindowManager, id: WindowId) void {
        if (self.windows.get(id)) |win| {
            win.close();
        }
    }

    /// Check if any window is open
    pub fn anyOpen(self: *WindowManager) bool {
        var it = self.windows.valueIterator();
        while (it.next()) |win_ptr| {
            if (win_ptr.*.is_open) return true;
        }
        return false;
    }

    /// Get the number of registered windows
    pub fn count(self: *WindowManager) usize {
        return self.windows.count();
    }
};

// ============================================================================
// Tests
// ============================================================================

test "WindowManager.init and deinit" {
    var manager = WindowManager.init(std.testing.allocator);
    defer manager.deinit();
    try std.testing.expectEqual(@as(usize, 0), manager.count());
}

test "WindowManager.register and get" {
    var manager = WindowManager.init(std.testing.allocator);
    defer manager.deinit();

    var win = DebugWindow.init(.performance, "Test", 0, 0, 100, 100);
    manager.register(&win);

    try std.testing.expectEqual(@as(usize, 1), manager.count());

    const retrieved = manager.get(.performance);
    try std.testing.expect(retrieved != null);
    try std.testing.expectEqualStrings("Test", retrieved.?.title);
}

test "WindowManager.toggleAll" {
    var manager = WindowManager.init(std.testing.allocator);
    defer manager.deinit();

    var win1 = DebugWindow.init(.performance, "Win1", 0, 0, 100, 100);
    var win2 = DebugWindow.init(.entity_info, "Win2", 0, 0, 100, 100);

    manager.register(&win1);
    manager.register(&win2);

    // Both start open
    try std.testing.expect(win1.is_open);
    try std.testing.expect(win2.is_open);

    // Toggle should close all
    manager.toggleAll();
    try std.testing.expect(!win1.is_open);
    try std.testing.expect(!win2.is_open);

    // Toggle again should open all
    manager.toggleAll();
    try std.testing.expect(win1.is_open);
    try std.testing.expect(win2.is_open);
}

test "WindowManager.closeAll and openAll" {
    var manager = WindowManager.init(std.testing.allocator);
    defer manager.deinit();

    var win1 = DebugWindow.init(.performance, "Win1", 0, 0, 100, 100);
    var win2 = DebugWindow.init(.entity_info, "Win2", 0, 0, 100, 100);

    manager.register(&win1);
    manager.register(&win2);

    manager.closeAll();
    try std.testing.expect(!win1.is_open);
    try std.testing.expect(!win2.is_open);
    try std.testing.expect(!manager.anyOpen());

    manager.openAll();
    try std.testing.expect(win1.is_open);
    try std.testing.expect(win2.is_open);
    try std.testing.expect(manager.anyOpen());
}

test "WindowManager.openWindow and closeWindow" {
    var manager = WindowManager.init(std.testing.allocator);
    defer manager.deinit();

    var win = DebugWindow.init(.performance, "Test", 0, 0, 100, 100);
    manager.register(&win);

    manager.closeWindow(.performance);
    try std.testing.expect(!win.is_open);

    manager.openWindow(.performance);
    try std.testing.expect(win.is_open);
}
