# Technical Architecture

## System Overview

The game is built in Zig, emphasizing performance, memory safety, and clear separation of concerns. The architecture supports a tick-based simulation with Lua scripting integration and 2D hex-based rendering.

## Core Architectural Principles

1. **Data-Oriented Design**: Optimize for cache locality and batch processing
2. **Modular Systems**: Clear boundaries between simulation, scripting, and rendering
3. **Deterministic Simulation**: Game logic is reproducible given same inputs
4. **Hot-Reload Support**: Scripts can be modified and reloaded without restart
5. **Cross-Platform**: Abstract platform-specific code behind interfaces

## High-Level System Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Game Loop                            │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐             │
│  │  Input   │───▶│Simulation│───▶│ Renderer │             │
│  │ Handler  │    │  Tick    │    │  Frame   │             │
│  └──────────┘    └─────┬────┘    └──────────┘             │
│                        │                                    │
│                        ▼                                    │
│              ┌─────────────────┐                           │
│              │  Lua Scripting  │                           │
│              │     Engine      │                           │
│              └─────────────────┘                           │
└─────────────────────────────────────────────────────────────┘
```

## Project Structure

```
zig_game/
├── src/
│   ├── main.zig                 # Entry point, game loop
│   ├── core/
│   │   ├── game_state.zig       # Top-level game state
│   │   ├── tick_scheduler.zig   # Tick timing and scheduling
│   │   └── config.zig           # Game configuration
│   ├── world/
│   │   ├── hex_grid.zig         # Hex coordinate system and grid
│   │   ├── world.zig            # World generation and management
│   │   ├── tile.zig             # Tile data and properties
│   │   └── pathfinding.zig      # Hex-based pathfinding (A*)
│   ├── entities/
│   │   ├── entity.zig           # Entity data structures
│   │   ├── entity_manager.zig   # Entity lifecycle management
│   │   ├── components.zig       # Entity component definitions
│   │   └── systems.zig          # Entity behavior systems
│   ├── scripting/
│   │   ├── lua_runtime.zig      # Lua VM initialization and management
│   │   ├── api.zig              # Lua C API bindings
│   │   ├── script_manager.zig   # Script loading and execution
│   │   └── sandbox.zig          # Script sandboxing and limits
│   ├── resources/
│   │   ├── resource_types.zig   # Resource definitions
│   │   └── resource_manager.zig # Resource tracking and distribution
│   ├── structures/
│   │   ├── structure.zig        # Structure definitions
│   │   └── construction.zig     # Building mechanics
│   ├── rendering/
│   │   ├── renderer.zig         # Main rendering coordinator
│   │   ├── hex_renderer.zig     # Hex tile rendering
│   │   ├── entity_renderer.zig  # Entity sprite rendering
│   │   ├── ui_renderer.zig      # UI overlay rendering
│   │   └── camera.zig           # Camera and viewport
│   ├── input/
│   │   ├── input_manager.zig    # Input handling abstraction
│   │   └── camera_controller.zig# Camera controls
│   ├── ui/
│   │   ├── ui_manager.zig       # UI state management
│   │   ├── code_editor.zig      # In-game Lua editor
│   │   └── panels.zig           # UI panels (entity info, etc.)
│   └── utils/
│       ├── memory.zig           # Custom allocators
│       ├── math.zig             # Math utilities (hex math)
│       └── logging.zig          # Logging system
├── libs/                        # Third-party dependencies
├── assets/                      # Game assets (sprites, etc.)
├── scripts/                     # Default/example Lua scripts
└── tests/                       # Unit and integration tests
```

## Core Systems

### 1. Simulation System (Tick-Based)

**Responsibilities:**
- Execute game logic at fixed tick rate
- Update entity states
- Process Lua scripts
- Handle entity actions

**Implementation:**
```zig
// Tick structure
pub const TickScheduler = struct {
    tick_rate: f64,           // Ticks per second
    accumulator: f64,         // Time accumulator
    current_tick: u64,        // Global tick counter

    pub fn update(self: *TickScheduler, delta_time: f64) void {
        self.accumulator += delta_time;
        while (self.accumulator >= 1.0 / self.tick_rate) {
            self.processTick();
            self.accumulator -= 1.0 / self.tick_rate;
            self.current_tick += 1;
        }
    }

    fn processTick(self: *TickScheduler) void {
        // Execute all game logic for this tick
        // 1. Execute Lua scripts for all entities
        // 2. Process entity actions
        // 3. Update world state
        // 4. Handle resource distribution
        // 5. Update structures
    }
};
```

**Tick Rate**: Configurable, default 2-3 ticks/second (TBD based on testing)

### 2. Entity System (ECS-Inspired)

**Design**: Hybrid approach - not pure ECS, but component-based

**Entity Structure**:
```zig
pub const EntityId = u32;

pub const Entity = struct {
    id: EntityId,
    position: HexCoord,
    role: EntityRole,
    components: EntityComponents,
};

pub const EntityComponents = struct {
    energy: ?*EnergyComponent,
    inventory: ?*InventoryComponent,
    combat: ?*CombatComponent,
    script: ?*ScriptComponent,
    // ... more components
};

pub const ScriptComponent = struct {
    script_id: u32,           // Reference to loaded script
    memory: LuaTable,         // Persistent entity memory
    cpu_used: u32,            // CPU budget tracking
};
```

**Entity Manager**:
- Maintains entity pool (packed arrays for cache efficiency)
- Handles entity creation/destruction
- Provides query interface for systems

### 3. Hex Grid System

**Coordinate System**: Axial coordinates (q, r)

```zig
pub const HexCoord = struct {
    q: i32,  // Column (diagonal)
    r: i32,  // Row

    pub fn neighbors(self: HexCoord) [6]HexCoord {
        // Returns 6 adjacent hex coordinates
    }

    pub fn distance(self: HexCoord, other: HexCoord) u32 {
        // Manhattan distance on hex grid
    }

    pub fn toPixel(self: HexCoord, hex_size: f32) Vec2 {
        // Convert hex coord to screen pixel position
    }
};

pub const HexGrid = struct {
    width: u32,
    height: u32,
    tiles: []Tile,

    pub fn getTile(self: *HexGrid, coord: HexCoord) ?*Tile {
        // Bounds-checked tile access
    }
};
```

### 4. Lua Scripting Integration

**Lua Runtime**: Embed Lua 5.4 (or LuaJIT for performance)

**Script Execution Flow**:
1. Each entity with a ScriptComponent gets CPU budget per tick
2. Lua script executes in sandboxed environment
3. Script can call game API functions
4. Script returns action(s) to perform
5. Actions queued and executed by simulation

**CPU Limiting**:
```zig
pub const ScriptSandbox = struct {
    vm: *lua.State,
    cpu_limit: u32,        // Instructions per tick
    cpu_used: u32,

    pub fn execute(self: *ScriptSandbox, script: []const u8) !void {
        // Set instruction hook for CPU limiting
        lua.sethook(self.vm, instructionHook, lua.MASKCOUNT, 1000);
        // Execute script
        // Abort if CPU limit exceeded
    }
};
```

**Memory Sandboxing**:
- Restrict available Lua standard library functions
- Disable file I/O, os functions, debug library
- Provide custom game API only

### 5. Rendering System

**Two-Phase Rendering**:

**Phase 1: Simulation to Render State**
- Extract visual data from simulation state
- Calculate interpolation for smooth movement
- Prepare render batches

**Phase 2: Render Execution**
- Draw world (tiles)
- Draw entities (interpolated positions)
- Draw UI overlay

**Rendering Stack** (TBD based on research):

**Option A: SDL2 + Custom 2D Renderer**
- SDL2 for window/input/basic rendering
- Custom sprite batching
- Shader support via OpenGL

**Option B: Raylib**
- High-level 2D rendering
- Built-in sprite support
- Cross-platform

**Option C: Sokol + Custom**
- Sokol for graphics abstraction
- More control over rendering

**Recommendation**: Start with Raylib for prototype, evaluate performance

**Window Configuration**:
- Fullscreen borderless by default (uses full monitor resolution)
- ESC key exits fullscreen and closes window
- Future: Configurable window mode in settings (Phase 4)
  - Windowed mode with custom resolution
  - Fullscreen exclusive vs borderless
  - Multi-monitor support

**Debug Overlay** (Phase 1 development tool):
- Toggle with F3 key
- Displays real-time performance metrics:
  - FPS (frames per second)
  - Frame time (milliseconds)
  - Entity count
  - Tick rate (when tick system implemented)
  - Memory usage
- Non-intrusive corner display
- Always available in debug builds
- Extends to detailed Performance Panel in Phase 4

### 6. Input System

**Architecture**:
```zig
pub const InputManager = struct {
    keyboard: KeyboardState,
    mouse: MouseState,

    pub fn update(self: *InputManager) void {
        // Poll input events
        // Update state
    }

    pub fn isKeyPressed(self: *InputManager, key: Key) bool {}
    pub fn getMouseWorldPos(self: *InputManager, camera: Camera) Vec2 {}
};
```

**Camera Controls**:
- Pan: WASD or arrow keys
- Zoom: Mouse wheel
- Click to select entities/tiles

### 7. Save/Load System

**Save Format**: Binary serialization or JSON (for human readability during development)

**Saved Data**:
- World state (tiles, resources)
- All entities (position, components, memory)
- Lua scripts (as text)
- Player progress (tech tree, resources)
- Global game state (tick count, etc.)

**Determinism Requirements**:
- Save/load must produce identical simulation
- Important for debugging and replays

## Dependencies

### Zig Standard Library
- Core data structures
- Memory management
- Cross-platform abstractions

### Required Third-Party Libraries

1. **Lua** (Lua 5.4 or LuaJIT)
   - Scripting engine
   - Zig bindings: ziglua or custom C API bindings

2. **Rendering** (Choose one):
   - raylib-zig (Raylib bindings)
   - SDL2-zig (SDL2 bindings)
   - sokol-zig (Sokol bindings)

3. **Math**:
   - Custom or zalgebra (vector math)

4. **Serialization** (for save/load):
   - zig-serialization
   - Custom binary format

### Build System

**build.zig**:
- Compile Zig source
- Link Lua library (Lua 5.4 via ziglua)
- Link rendering library (Raylib via raylib-zig)
- Bundle assets
- Run tests
- Cross-compilation support (Windows, macOS, Linux)
- Custom install directory option (`-Dinstall-dir`)

**Cross-Compilation**:
The project supports seamless cross-compilation to Windows from WSL2/Linux:
```bash
# Build Windows executable
zig build -Dtarget=x86_64-windows

# Build with custom install location
zig build -Dtarget=x86_64-windows -Dinstall-dir="/mnt/d/Library/game-temp"
```

**Why Windows builds?**
- WSL2/WSLg has graphics limitations (no working VSync, screen tearing)
- Native Windows .exe runs with proper VSync and smooth 60 FPS
- Zig includes all target toolchains - no Windows SDK needed
- `zig build run` works for Windows .exe from WSL2 (uses Windows graphics)

## Performance Considerations

### Memory Management

**Allocator Strategy**:
- Arena allocators for per-tick temporary allocations
- Pool allocators for entities (fixed-size)
- General allocator for dynamic structures

**Memory Budget**:
- Target: <100MB for medium-sized world (10,000 tiles, 1,000 entities)

### CPU Performance

**Profiling Focus Areas**:
- Lua script execution (biggest bottleneck)
- Pathfinding (expensive for many entities)
- Rendering (batch sprite draws)

**Optimization Strategies**:
- Spatial partitioning for entity queries (grid chunks)
- Multi-threading for independent systems (future)
- Script caching/compilation

### Rendering Performance

**Target**: 60 FPS rendering, independent of tick rate

**Techniques**:
- Sprite batching
- Frustum culling (only render visible hexes)
- Level of detail (reduce detail when zoomed out)

## Testing Strategy

### Unit Tests
- Hex coordinate math
- Pathfinding algorithms
- Entity component operations
- Lua API functions

### Integration Tests
- Full tick simulation
- Script execution and API calls
- Save/load round-trip

### Performance Tests
- Benchmark tick processing with N entities
- Benchmark Lua script execution
- Benchmark rendering with full screen of sprites

## Development Phases

See DEVELOPMENT_PLAN.md for detailed phase breakdown.

**Phase 1**: Core engine (hex grid, entity system, basic rendering)
**Phase 2**: Lua integration (scripting API, sandbox, execution)
**Phase 3**: Gameplay systems (resources, construction, progression)
**Phase 4**: UI and polish (editor, UI panels, visuals)
**Phase 5**: Content and balancing (scenarios, tech tree, tuning)

## Technical Decisions Made

- [x] **Rendering library**: Raylib (via raylib-zig) - Selected in Phase 0
  - Rationale: High-level 2D rendering, cross-platform, WebAssembly support
- [x] **Lua version**: Lua 5.4 (via ziglua) - Selected in Phase 0
  - Rationale: Compiles from source, official 5.4 support, no JIT complexity
- [x] **Build system**: Native Zig build system with cross-compilation
  - Supports Windows, macOS, Linux targets without additional toolchains
- [x] **Development environment**: WSL2 with Windows cross-compilation
  - Windows .exe for graphics (VSync works), WSL2 for development workflow

## Open Technical Questions

- [ ] Multi-threading strategy for future scaling
- [ ] Network architecture for potential multiplayer
- [ ] Asset pipeline and format
- [ ] Shader language and integration
- [ ] Final decision: Lua 5.4 vs LuaJIT (benchmark in Phase 2)
