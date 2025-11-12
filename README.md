# Zig Game - Lua-Scripted Automation Game

A programming-driven automation game where players write Lua scripts to control a collective of entities. Inspired by games like Screeps, this project focuses on the meta-game of iterative script development, optimization, and orchestration.

## Vision

Players control a collective of autonomous entities through Lua scripts. The core gameplay loop revolves around:
- **Observe** your scripted entities perform their tasks
- **Analyze** inefficiencies and failures
- **Script** improved behaviors in Lua
- **Deploy** and iterate on your automation

The satisfaction comes from building increasingly sophisticated systems, watching your collective grow, and optimizing your code to overcome challenges.

## Current Status

**Phase**: Phase 1 Complete (100%), Phase 2 (Lua Integration) - 30% Complete

The project has moved well beyond planning and is now a functional game engine prototype with:
- Complete hex grid system with cube coordinate math
- Camera controls (pan, zoom) with smooth interpolation
- Entity system with 4 roles (worker, combat, scout, engineer)
- Tick-based simulation running at 2.5 ticks/second
- Entity rendering with energy bars and selection system
- Debug overlay with performance metrics
- **109 tests passing** with >90% code coverage
- **Zero memory leaks** (verified with test allocator)
- Windows cross-compilation support

**Next Up**: Phase 2 (Lua Scripting Integration)

### Design Documents
- [docs/design/GAME_DESIGN.md](docs/design/GAME_DESIGN.md) - Core gameplay mechanics, entity systems, and design philosophy
- [docs/design/ARCHITECTURE.md](docs/design/ARCHITECTURE.md) - Technical architecture and system design
- [docs/design/DEVELOPMENT_PLAN.md](docs/design/DEVELOPMENT_PLAN.md) - Development phases, milestones, and testing strategy
- [docs/design/LUA_API_SPEC.md](docs/design/LUA_API_SPEC.md) - Complete specification of the Lua scripting API

## Key Features

### Currently Implemented
- **Hex-Based World**: Fully functional hexagonal grid with axial coordinates
- **Camera System**: Pan (WASD/arrows/right-click drag) and zoom (wheel/+/-) with smooth interpolation
- **Entity System**: Four entity roles (Worker, Combat, Scout, Engineer) with energy management
- **Entity Selection**: Left-click entities to inspect their state (ID, role, position, energy)
- **Tick Scheduler**: Deterministic simulation at 2.5 ticks/second, separate from 60 FPS rendering
- **Debug Tools**: F3 overlay showing FPS, entity count, and performance metrics
- **Cross-Platform**: Builds natively for Linux and Windows (x86_64)

### Planned (Next Phases)
- **Lua Scripting**: Write code to control entity behavior (Phase 2)
- **Resource Economy**: Gather, process, and manage multiple resource types (Phase 3)
- **Pathfinding**: A* pathfinding for entity movement (Phase 3)
- **Construction**: Build structures and modify the world (Phase 3)
- **In-Game Code Editor**: Write and debug scripts without leaving the game (Phase 4)
- **Meta-Progression**: Technology tree unlocks new capabilities (Phase 5)
- **Scenario System**: Challenges and objectives to test your automation skills (Phase 5)

## Technology Stack

- **Language**: Zig 0.15.1 (performance, safety, cross-platform)
- **Scripting**: Lua 5.4 via ziglua (embedded, sandboxed - Phase 2)
- **Rendering**: Raylib 5.6.0 via raylib-zig (2D graphics, cross-platform)
- **Platform**: Currently supports Linux and Windows x86_64 (macOS planned)

## Project Structure

**Status**: Phase 1 implementation complete with ~3,370 lines of code and 109 passing tests.

```
zig_game/
├── docs/                         # Design documents and framework
│   ├── design/                   # Game design specifications
│   │   ├── GAME_DESIGN.md        # Gameplay mechanics and vision
│   │   ├── ARCHITECTURE.md       # Technical architecture
│   │   ├── DEVELOPMENT_PLAN.md   # Phased development roadmap
│   │   └── LUA_API_SPEC.md       # Lua API specification
│   └── agent-framework/          # Development agent templates
│       └── templates/            # Reusable agent prompts
├── src/                          # Zig source code (~3,500 lines)
│   ├── main.zig                  # Game loop and entry point
│   ├── core/                     # Core systems
│   │   └── tick_scheduler.zig    # Tick timing system
│   ├── world/                    # World and hex grid
│   │   └── hex_grid.zig          # Hex coordinate system
│   ├── entities/                 # Entity system
│   │   ├── entity.zig            # Entity data structure
│   │   └── entity_manager.zig    # Entity lifecycle management
│   ├── rendering/                # Rendering systems
│   │   ├── hex_renderer.zig      # Camera and hex rendering
│   │   └── entity_renderer.zig   # Entity visualization
│   ├── input/                    # Input handling
│   │   └── entity_selector.zig   # Mouse-based selection
│   ├── ui/                       # User interface
│   │   ├── debug_overlay.zig     # F3 debug info
│   │   └── entity_info_panel.zig # Entity inspection panel
│   └── utils/                    # Utility functions
├── scripts/                      # Example Lua scripts (Phase 2+)
├── assets/                       # Game assets (Phase 4+)
├── build.zig                     # Build configuration
├── build.zig.zon                 # Package dependencies (raylib, ziglua)
├── .github/workflows/ci.yml      # CI/CD pipeline
└── [PROJECT_DOCS]                # SESSION_STATE.md, CLAUDE.md, etc.
```

## Getting Started

### Prerequisites

- Zig 0.15.1 (earlier versions may work but not tested)
- No other dependencies needed - Zig package manager handles Raylib and Lua

### Building and Running

```bash
# Clone the repository
git clone https://github.com/TBick/zig_game.git
cd zig_game

# Build the project (Linux binary)
zig build

# Build and run (opens game window)
zig build run

# Run all 109 tests
zig build test

# Build for Windows (cross-compilation from Linux/WSL2)
zig build -Dtarget=x86_64-windows

# Build and run Windows build from WSL2 (better graphics performance)
zig build run -Dtarget=x86_64-windows

# Build Windows .exe to custom directory
zig build -Dtarget=x86_64-windows -Dinstall-dir="/mnt/d/Library/game-temp"

# Clean build artifacts
rm -rf zig-cache zig-out
```

### Controls

- **Camera Pan**: WASD / Arrow Keys / Right-Click Drag
- **Camera Zoom**: Mouse Wheel / +/- Keys
- **Reset Camera**: R key
- **Entity Selection**: Left-Click on entity to inspect
- **Debug Overlay**: F3 to toggle (shows FPS, entity count)
- **Quit**: ESC or close window

### What You'll See

The game currently displays:
- A hex grid rendered in the center of the screen
- 20 randomly placed entities (5 of each role: worker, combat, scout, engineer)
- Each entity has a colored circle and energy bar
- Entities tick at 2.5 ticks/second and slowly consume energy
- Click any entity to see its info panel (ID, role, position, energy)

## Documentation

### Project Status
- **[SESSION_STATE.md](SESSION_STATE.md)**: Current development status, completed tasks, and progress tracking
- **[CONTEXT_HANDOFF_PROTOCOL.md](CONTEXT_HANDOFF_PROTOCOL.md)**: Session-by-session development log
- **[TEST_COVERAGE_REPORT.md](TEST_COVERAGE_REPORT.md)**: Comprehensive test coverage analysis

### Design Documents
- **[Game Design](docs/design/GAME_DESIGN.md)**: Gameplay vision and mechanics (forward-looking)
- **[Technical Architecture](docs/design/ARCHITECTURE.md)**: System design specifications
- **[Development Plan](docs/design/DEVELOPMENT_PLAN.md)**: Phased roadmap and milestones
- **[Lua API Specification](docs/design/LUA_API_SPEC.md)**: Planned scripting API for Phase 2

### Development
- **[CLAUDE.md](CLAUDE.md)**: Instructions for AI assistants working on the project
- **[Agent Framework](docs/agent-framework/)**: Templates for task-specific development agents

## Development Roadmap

### Phase 0: Setup ✅ (Complete)
- ✅ Project initialization and Git setup
- ✅ Build system with cross-compilation support
- ✅ CI/CD pipeline (GitHub Actions)
- ✅ Development tooling and documentation framework

### Phase 1: Core Engine ✅ (Complete)
- ✅ Hex grid system with cube coordinate math
- ✅ Entity management with 4 roles
- ✅ Rendering pipeline with Raylib
- ✅ Camera controls (pan, zoom)
- ✅ Tick scheduler (2.5 ticks/sec)
- ✅ Entity selection system
- ✅ Comprehensive test coverage (109 tests passing)

### Phase 2: Lua Integration ⏳ (Next)
- Embed Lua 5.4 runtime via ziglua
- Implement scripting API for entity control
- Script sandbox with CPU and memory limits
- Hot-reload support for scripts

### Phase 3: Gameplay Systems
- Resource gathering and management
- Construction mechanics
- A* pathfinding on hex grid
- Energy production/consumption economy

### Phase 4: UI and Editor
- In-game Lua code editor
- UI panels for script management
- Entity scripting assignment interface
- Performance profiling tools

### Phase 5: Content and Polish
- Technology tree system
- Scenario challenges
- Tutorial scenarios
- Visual effects and optimization

**Progress**: ~25% complete overall (Phase 0 and 1 complete, Phase 2 at 30%)

## Design Philosophy

- **Programming is the gameplay** - The joy comes from writing, debugging, and optimizing code
- **Mastery through iteration** - Satisfaction from progressively improving your systems
- **Emergent complexity** - Simple rules create complex strategic possibilities
- **Accessible but deep** - Easy to start, difficult to master

## Contributing

This is currently a personal project in active development (Phase 1 near complete). Contributions are welcome once Phase 2 (Lua integration) is complete and the core gameplay loop is functional. Contribution guidelines will be established at that time.

For now, feel free to:
- Open issues for bugs or suggestions
- Star the repository to follow progress
- Check SESSION_STATE.md for current development status

## License

MIT (intended) - Will be formalized after Phase 2 completion

## Contact

- GitHub: [@TBick](https://github.com/TBick)
- Project Repository: [github.com/TBick/zig_game](https://github.com/TBick/zig_game)

---

## Testing and Quality

- **109 tests** covering all Phase 1 modules (100% pass rate)
- **>90% code coverage** on implemented systems
- **Zero memory leaks** verified with Zig test allocator
- **CI/CD pipeline** runs tests automatically on every commit
- Comprehensive edge case and integration testing

---

## Development Status

**Playable Build**: Yes! Run `zig build run` to see the current prototype.

**What Works**:
- Interactive hex grid world with camera controls
- Entity spawning and management
- Visual entity representation with energy bars
- Entity inspection via mouse click
- Debug tools for development
- Stable 60 FPS rendering with 2.5 tick/sec simulation

**What's Next**:
- Lua scripting integration (Phase 2)
- Entity AI and automation
- Resource system and economy

**Last Updated**: 2025-11-12 (Session 6)
