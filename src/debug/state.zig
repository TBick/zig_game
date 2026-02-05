const std = @import("std");
const WindowManager = @import("window_manager.zig").WindowManager;

/// Global debug state - controls visibility of all debug features
pub const DebugState = struct {
    /// Master toggle - when false, all debug features are hidden
    debug_active: bool = true,

    /// Individual toggle for coordinate labels overlay
    show_coord_labels: bool = true,

    /// Individual toggle for selection/hover highlights
    show_selection_highlights: bool = true,

    /// Reference to window manager (for toggling windows)
    window_manager: ?*WindowManager = null,

    /// Initialize with default state (all enabled)
    pub fn init() DebugState {
        return DebugState{};
    }

    /// Initialize with a window manager reference
    pub fn initWithWindowManager(wm: *WindowManager) DebugState {
        return DebugState{
            .window_manager = wm,
        };
    }

    /// Set the window manager reference
    pub fn setWindowManager(self: *DebugState, wm: *WindowManager) void {
        self.window_manager = wm;
    }

    /// Master toggle - toggles all debug features on/off
    /// When turning off, closes all windows
    /// When turning on, opens all windows
    pub fn toggle(self: *DebugState) void {
        self.debug_active = !self.debug_active;

        // Sync overlays with master toggle
        self.show_coord_labels = self.debug_active;
        self.show_selection_highlights = self.debug_active;

        // Sync windows with master toggle
        if (self.window_manager) |wm| {
            if (self.debug_active) {
                wm.openAll();
            } else {
                wm.closeAll();
            }
        }
    }

    /// Check if debug is currently enabled
    pub fn isEnabled(self: *const DebugState) bool {
        return self.debug_active;
    }

    /// Toggle coordinate labels overlay
    pub fn toggleCoordLabels(self: *DebugState) void {
        self.show_coord_labels = !self.show_coord_labels;
    }

    /// Toggle selection highlights overlay
    pub fn toggleSelectionHighlights(self: *DebugState) void {
        self.show_selection_highlights = !self.show_selection_highlights;
    }

    /// Check if coordinate labels should be shown
    pub fn shouldShowCoordLabels(self: *const DebugState) bool {
        return self.debug_active and self.show_coord_labels;
    }

    /// Check if selection highlights should be shown
    pub fn shouldShowSelectionHighlights(self: *const DebugState) bool {
        return self.debug_active and self.show_selection_highlights;
    }

    /// Enable all debug features
    pub fn enableAll(self: *DebugState) void {
        self.debug_active = true;
        self.show_coord_labels = true;
        self.show_selection_highlights = true;
        if (self.window_manager) |wm| {
            wm.openAll();
        }
    }

    /// Disable all debug features
    pub fn disableAll(self: *DebugState) void {
        self.debug_active = false;
        self.show_coord_labels = false;
        self.show_selection_highlights = false;
        if (self.window_manager) |wm| {
            wm.closeAll();
        }
    }
};

// ============================================================================
// Tests
// ============================================================================

test "DebugState.init creates enabled state" {
    const state = DebugState.init();
    try std.testing.expect(state.debug_active);
    try std.testing.expect(state.show_coord_labels);
    try std.testing.expect(state.show_selection_highlights);
}

test "DebugState.toggle changes master state" {
    var state = DebugState.init();
    try std.testing.expect(state.isEnabled());

    state.toggle();
    try std.testing.expect(!state.isEnabled());
    try std.testing.expect(!state.shouldShowCoordLabels());
    try std.testing.expect(!state.shouldShowSelectionHighlights());

    state.toggle();
    try std.testing.expect(state.isEnabled());
}

test "DebugState.shouldShow respects master toggle" {
    var state = DebugState.init();

    // With master on, individual toggles work
    try std.testing.expect(state.shouldShowCoordLabels());
    state.show_coord_labels = false;
    try std.testing.expect(!state.shouldShowCoordLabels());

    // With master off, always returns false
    state.show_coord_labels = true;
    state.debug_active = false;
    try std.testing.expect(!state.shouldShowCoordLabels());
}

test "DebugState individual toggles" {
    var state = DebugState.init();

    state.toggleCoordLabels();
    try std.testing.expect(!state.show_coord_labels);
    try std.testing.expect(state.show_selection_highlights);

    state.toggleSelectionHighlights();
    try std.testing.expect(!state.show_selection_highlights);
}

test "DebugState.enableAll and disableAll" {
    var state = DebugState.init();

    state.disableAll();
    try std.testing.expect(!state.debug_active);
    try std.testing.expect(!state.show_coord_labels);
    try std.testing.expect(!state.show_selection_highlights);

    state.enableAll();
    try std.testing.expect(state.debug_active);
    try std.testing.expect(state.show_coord_labels);
    try std.testing.expect(state.show_selection_highlights);
}
