const std = @import("std");
const build_options = @import("build_options");

/// Compile-time constant: if false, all debug code is eliminated from the binary
pub const enabled = build_options.enable_debug_features;

// ============================================================================
// Conditional Type Exports
// When debug features are disabled, these types compile to no-op stubs
// that get completely eliminated by the compiler
// ============================================================================

/// Debug window abstraction
pub const Window = if (enabled) @import("window.zig").DebugWindow else NoOpWindow;

/// Window identifier enum
pub const WindowId = if (enabled) @import("window.zig").WindowId else NoOpWindowId;

/// Content area for rendering inside windows
pub const ContentArea = if (enabled) @import("window.zig").ContentArea else NoOpContentArea;

/// Window manager for handling multiple windows
pub const WindowManager = if (enabled) @import("window_manager.zig").WindowManager else NoOpWindowManager;

/// Debug state (master toggle, overlay toggles)
pub const State = if (enabled) @import("state.zig").DebugState else NoOpState;

// ============================================================================
// No-Op Stub Types
// These are used when debug features are disabled. They have the same API
// but do nothing, allowing code to compile without #ifdef-style conditionals
// ============================================================================

/// No-op window that does nothing
const NoOpWindow = struct {
    id: NoOpWindowId = .none,
    title: []const u8 = "",
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 0,
    height: i32 = 0,
    is_open: bool = false,

    pub fn init(_: NoOpWindowId, _: []const u8, _: i32, _: i32, _: i32, _: i32) NoOpWindow {
        return NoOpWindow{};
    }
    pub fn renderFrame(_: *const NoOpWindow) ?NoOpContentArea {
        return null;
    }
    pub fn handleInput(_: *NoOpWindow) bool {
        return false;
    }
    pub fn open(_: *NoOpWindow) void {}
    pub fn close(_: *NoOpWindow) void {}
    pub fn toggle(_: *NoOpWindow) void {}
    pub fn isOpen(_: *const NoOpWindow) bool {
        return false;
    }
};

/// No-op window ID
const NoOpWindowId = enum { none };

/// No-op content area
const NoOpContentArea = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 0,
    height: i32 = 0,

    pub fn drawText(_: NoOpContentArea, _: [:0]const u8, _: i32, _: i32, _: i32, _: anytype) void {}
    pub fn drawTextLine(_: NoOpContentArea, _: [:0]const u8, _: i32, _: i32, _: anytype) void {}
};

/// No-op window manager
const NoOpWindowManager = struct {
    pub fn init(_: std.mem.Allocator) NoOpWindowManager {
        return NoOpWindowManager{};
    }
    pub fn deinit(_: *NoOpWindowManager) void {}
    pub fn register(_: *NoOpWindowManager, _: anytype) void {}
    pub fn get(_: *NoOpWindowManager, _: anytype) ?*NoOpWindow {
        return null;
    }
    pub fn renderAllFrames(_: *NoOpWindowManager) void {}
    pub fn handleInputAll(_: *NoOpWindowManager) bool {
        return false;
    }
    pub fn toggleAll(_: *NoOpWindowManager) void {}
    pub fn closeAll(_: *NoOpWindowManager) void {}
    pub fn openAll(_: *NoOpWindowManager) void {}
    pub fn openWindow(_: *NoOpWindowManager, _: anytype) void {}
    pub fn closeWindow(_: *NoOpWindowManager, _: anytype) void {}
    pub fn anyOpen(_: *NoOpWindowManager) bool {
        return false;
    }
    pub fn count(_: *NoOpWindowManager) usize {
        return 0;
    }
};

/// No-op debug state
const NoOpState = struct {
    debug_active: bool = false,
    show_coord_labels: bool = false,
    show_selection_highlights: bool = false,

    pub fn init() NoOpState {
        return NoOpState{};
    }
    pub fn initWithWindowManager(_: anytype) NoOpState {
        return NoOpState{};
    }
    pub fn setWindowManager(_: *NoOpState, _: anytype) void {}
    pub fn toggle(_: *NoOpState) void {}
    pub fn isEnabled(_: *const NoOpState) bool {
        return false;
    }
    pub fn toggleCoordLabels(_: *NoOpState) void {}
    pub fn toggleSelectionHighlights(_: *NoOpState) void {}
    pub fn shouldShowCoordLabels(_: *const NoOpState) bool {
        return false;
    }
    pub fn shouldShowSelectionHighlights(_: *const NoOpState) bool {
        return false;
    }
    pub fn enableAll(_: *NoOpState) void {}
    pub fn disableAll(_: *NoOpState) void {}
};

// ============================================================================
// Tests
// ============================================================================

test "debug.enabled reflects build option" {
    // This test verifies the constant exists and is a boolean
    // The actual value depends on build configuration
    const e: bool = enabled;
    _ = e;
}

test "NoOpWindow has same API as real Window" {
    var win = NoOpWindow.init(.none, "Test", 0, 0, 100, 100);
    _ = win.renderFrame();
    _ = win.handleInput();
    win.open();
    win.close();
    win.toggle();
    _ = win.isOpen();
}

test "NoOpWindowManager has same API as real WindowManager" {
    var manager = NoOpWindowManager.init(std.testing.allocator);
    defer manager.deinit();

    var win = NoOpWindow{};
    manager.register(&win);
    _ = manager.get(.none);
    manager.renderAllFrames();
    _ = manager.handleInputAll();
    manager.toggleAll();
    manager.closeAll();
    manager.openAll();
    manager.openWindow(.none);
    manager.closeWindow(.none);
    _ = manager.anyOpen();
    _ = manager.count();
}

test "NoOpState has same API as real State" {
    var state = NoOpState.init();
    state.toggle();
    _ = state.isEnabled();
    state.toggleCoordLabels();
    state.toggleSelectionHighlights();
    _ = state.shouldShowCoordLabels();
    _ = state.shouldShowSelectionHighlights();
    state.enableAll();
    state.disableAll();
}
