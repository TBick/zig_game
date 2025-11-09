# Development Plan

## Overview

This document outlines the phased development approach, milestones, testing strategy, and metrics for building the Lua-scripted automation game. The plan is designed to enable parallel subagent development while maintaining clear dependencies and integration points.

## Development Philosophy

1. **Incremental Delivery**: Each phase produces a functional, testable increment
2. **Test-Driven**: Write tests before or alongside implementation
3. **Modular Integration**: Clear interfaces allow parallel development
4. **Early Validation**: Prototype risky components first
5. **Iterative Refinement**: Regular playtesting and adjustment

## Phase Overview

| Phase | Duration | Dependencies | Outcome |
|-------|----------|--------------|---------|
| Phase 0 | 1-2 days | None | Project setup and tooling |
| Phase 1 | 1-2 weeks | Phase 0 | Core engine foundations |
| Phase 2 | 2-3 weeks | Phase 1 | Lua scripting integration |
| Phase 3 | 2-3 weeks | Phase 2 | Gameplay systems |
| Phase 4 | 2-3 weeks | Phase 3 | UI and editor |
| Phase 5 | 3-4 weeks | Phase 4 | Content and polish |

**Total Estimated Timeline**: 10-15 weeks for playable prototype

---

## Phase 0: Project Setup and Infrastructure

### Objectives
- Initialize Zig project structure
- Configure build system
- Set up development tooling
- Establish testing framework

### Tasks

#### Build Configuration
- [ ] Create `build.zig` with compilation targets
- [ ] Configure debug and release builds
- [ ] Set up asset bundling pipeline
- [ ] Add test runner configuration

#### Development Tooling
- [ ] Set up LSP (zls) configuration
- [ ] Create dev scripts (build, run, test)
- [ ] Configure formatter settings
- [ ] Set up CI/CD (GitHub Actions) for automated testing

#### Testing Framework
- [ ] Configure Zig test framework
- [ ] Create test utilities module
- [ ] Set up performance benchmarking harness
- [ ] Create mock/stub generators for testing

### Deliverables
- `build.zig` with working compilation
- Empty src structure with placeholder files
- Passing test suite (even if minimal)
- CI pipeline running tests on push

### Success Metrics
- ✅ `zig build` completes without errors
- ✅ `zig build test` runs successfully
- ✅ `zig build run` launches empty window or stub executable
- ✅ CI pipeline shows green status

### Testing Requirements
- Build system smoke test
- Cross-platform build validation (Linux, Windows, macOS if possible)

---

## Phase 1: Core Engine Foundations

### Objectives
- Implement hex grid system
- Create basic entity management
- Build minimal rendering pipeline
- Establish game loop with tick system

### Tasks

#### Hex Grid System (`src/world/`)
- [ ] Implement `HexCoord` type with axial coordinates
- [ ] Implement hex math functions (distance, neighbors, range)
- [ ] Create `HexGrid` structure with tile storage
- [ ] Implement hex-to-pixel and pixel-to-hex conversion
- [ ] Write comprehensive hex math tests

#### Entity System (`src/entities/`)
- [ ] Define `Entity` structure
- [ ] Implement `EntityManager` with add/remove/query
- [ ] Create component structures (Position, Energy, etc.)
- [ ] Implement entity ID generation and recycling
- [ ] Write entity lifecycle tests

#### Game Loop (`src/core/`)
- [ ] Implement `TickScheduler` with fixed time step
- [ ] Create game state container
- [ ] Build update/render separation
- [ ] Add configurable tick rate
- [ ] Test tick timing accuracy

#### Rendering (`src/rendering/`)
- [ ] Choose and integrate rendering library (Raylib recommended)
- [ ] Implement window creation and basic event loop
- [ ] Create hex tile renderer (colored hexes)
- [ ] Implement camera with pan/zoom
- [ ] Render entity markers (circles/squares)
- [ ] Test rendering performance (10,000+ hexes)

### Deliverables
- Runnable application displaying hex grid
- Camera controls functional
- Can spawn entities and see them on grid
- Tick system running at target rate

### Success Metrics
- ✅ Render 10,000 hex tiles at 60 FPS
- ✅ Tick system maintains stable tick rate (±5% variance)
- ✅ Camera pan and zoom responsive
- ✅ Can create 1,000 entities without crash
- ✅ All unit tests passing (coverage >80%)

### Testing Requirements

#### Unit Tests
- Hex coordinate math (neighbors, distance, conversions)
- Entity manager operations (add, remove, query)
- Tick scheduler timing

#### Integration Tests
- Full game loop (update → tick → render) cycle
- Camera frustum culling correctness
- Entity rendering at various zoom levels

#### Performance Tests
- Benchmark: Tick processing with 1,000 entities (target: <5ms)
- Benchmark: Render frame with 5,000 visible hexes (target: <16ms @ 60 FPS)

---

## Phase 2: Lua Scripting Integration

### Objectives
- Embed Lua runtime
- Create sandbox environment
- Implement game API for Lua scripts
- Build script execution system with CPU limiting

### Tasks

#### Lua Runtime (`src/scripting/`)
- [ ] Integrate Lua 5.4 or LuaJIT library
- [ ] Create Lua VM initialization and cleanup
- [ ] Implement script loading from files
- [ ] Create Lua error handling and reporting
- [ ] Test basic Lua execution

#### Sandbox Environment (`src/scripting/sandbox.zig`)
- [ ] Disable dangerous Lua standard library functions
- [ ] Implement CPU instruction counting hook
- [ ] Create per-entity CPU budget system
- [ ] Implement memory limit enforcement
- [ ] Test sandbox escape attempts (security)

#### Lua Game API (`src/scripting/api.zig`)
- [ ] Implement entity state query functions
- [ ] Create action functions (move, harvest, build, etc.)
- [ ] Add world query functions (get tile, find resources)
- [ ] Implement entity memory access (persistent tables)
- [ ] Create logging/debugging functions for scripts
- [ ] Write API documentation (see LUA_API_SPEC.md)

#### Script Manager (`src/scripting/script_manager.zig`)
- [ ] Create script registry (load, cache, hot-reload)
- [ ] Implement per-entity script assignment
- [ ] Build script execution pipeline (once per tick per entity)
- [ ] Add script error recovery (don't crash game on bad script)
- [ ] Implement script profiling (CPU usage tracking)

### Deliverables
- Entities can be assigned Lua scripts
- Scripts execute each tick with API access
- Example scripts demonstrating API usage
- Script hot-reload working
- CPU limiting prevents runaway scripts

### Success Metrics
- ✅ Execute 1,000 entity scripts per tick within tick budget
- ✅ Sandbox prevents access to file system and OS
- ✅ CPU limiting terminates infinite loops gracefully
- ✅ Script errors logged without crashing game
- ✅ Hot-reload updates script without restart
- ✅ All API functions documented and tested

### Testing Requirements

#### Unit Tests
- Each API function (mock game state)
- CPU limiting accuracy
- Sandbox security (attempt forbidden operations)
- Script loading and caching

#### Integration Tests
- Script execution in full game loop
- Multi-entity script coordination
- Script error recovery
- Hot-reload during gameplay

#### Performance Tests
- Benchmark: 1,000 simple scripts per tick (target: <10ms total)
- Benchmark: Script with heavy API usage (target: <1ms)
- Memory leak test: Run scripts for 10,000 ticks

---

## Phase 3: Gameplay Systems

### Objectives
- Implement resource system
- Build construction mechanics
- Create entity actions (move, gather, build)
- Implement basic pathfinding
- Add energy system

### Tasks

#### Resource System (`src/resources/`)
- [ ] Define resource types (energy, minerals, etc.)
- [ ] Implement resource deposits on tiles
- [ ] Create entity inventory system
- [ ] Build resource harvesting mechanics
- [ ] Implement resource transfer between entities/structures

#### Construction System (`src/structures/`)
- [ ] Define structure types (spawner, storage, etc.)
- [ ] Implement construction mechanics (cost, time)
- [ ] Create structure functionality (process resources, etc.)
- [ ] Add structure-entity interactions
- [ ] Test construction workflow

#### Entity Actions (`src/entities/systems.zig`)
- [ ] Implement movement system (hex pathfinding)
- [ ] Create harvesting action
- [ ] Build construction action
- [ ] Implement attack action (basic combat)
- [ ] Add transfer/trade action
- [ ] Validate action preconditions

#### Pathfinding (`src/world/pathfinding.zig`)
- [ ] Implement A* algorithm for hex grid
- [ ] Add terrain cost modifiers
- [ ] Optimize for multiple simultaneous paths
- [ ] Create movement queue system
- [ ] Test pathfinding correctness and performance

#### Energy System
- [ ] Implement entity energy depletion over time
- [ ] Create energy consumption for actions
- [ ] Build energy harvesting mechanics
- [ ] Add energy distribution from structures
- [ ] Test entity survival mechanics

### Deliverables
- Scripted entities can move, harvest, and build
- Resources spawn on map and can be collected
- Structures can be built and provide functionality
- Energy system drives entity behavior
- Pathfinding works for complex maps

### Success Metrics
- ✅ Entity successfully navigates to resource and harvests it
- ✅ Entity can build structure from gathered resources
- ✅ Energy system forces entities to return to energy source
- ✅ Pathfinding finds optimal path in <5ms for 100-tile distance
- ✅ 100 entities can simultaneously path and move

### Testing Requirements

#### Unit Tests
- Resource calculations (deposit depletion, inventory management)
- Action validation (can entity perform action?)
- Pathfinding algorithm correctness (known maps)

#### Integration Tests
- Complete gather-build-spawn workflow
- Multi-entity resource competition
- Energy scarcity scenarios

#### Gameplay Tests
- Playtesting: Can player script entity to gather and build?
- Scenario: Survive 100 ticks with limited energy

---

## Phase 4: UI and In-Game Editor

### Objectives
- Create in-game Lua code editor
- Build UI panels (entity inspector, resource view)
- Implement selection and interaction
- Add script management UI

### Tasks

#### Code Editor (`src/ui/code_editor.zig`)
- [ ] Integrate or build text editor widget
- [ ] Implement syntax highlighting for Lua
- [ ] Add save/load script functionality
- [ ] Create script assignment to entities
- [ ] Build error display in editor

#### UI Panels (`src/ui/`)
- [ ] Entity inspector (show entity state, script, memory)
- [ ] Resource panel (global resource counts)
- [ ] Tech tree panel (unlocks, progress)
- [ ] Console/log panel (script output, errors)
- [ ] Performance panel (FPS, tick time, script CPU)

#### Interaction System (`src/input/`)
- [ ] Implement entity selection (click, drag-select)
- [ ] Add tile inspection (hover tooltips)
- [ ] Create context menus (right-click actions)
- [ ] Build script assignment workflow
- [ ] Add pause/speed controls

#### Script Management
- [ ] Script library (save/load scripts from disk)
- [ ] Script versioning (track changes)
- [ ] Script templates (provide examples)
- [ ] Script sharing (export/import)

### Deliverables
- Functional in-game code editor
- Can select entities and view/edit their scripts
- UI panels provide game state visibility
- User-friendly script management

### Success Metrics
- ✅ Can write and assign script in <30 seconds
- ✅ Editor provides useful error messages
- ✅ UI provides visibility into entity decisions
- ✅ Script hot-reload works from editor
- ✅ UX tested by non-developer (usability feedback)

### Testing Requirements

#### Unit Tests
- Text editor operations (insert, delete, undo)
- UI panel data binding correctness

#### Integration Tests
- End-to-end: Write script → assign → observe behavior
- Script error → see error in editor/console

#### User Testing
- Task: Write simple gather script from scratch
- Task: Debug failing script using UI tools
- Collect feedback on UX friction points

---

## Phase 5: Content, Progression, and Polish

### Objectives
- Implement technology tree
- Create scenario system
- Build tutorial and examples
- Add visual polish (animations, effects)
- Optimize performance
- Create content (scenarios, challenges)

### Tasks

#### Technology Tree (`src/progression/`)
- [ ] Define tech tree structure (unlocks, costs)
- [ ] Implement research mechanics
- [ ] Create tech unlock effects (new entities, structures, APIs)
- [ ] Build tech tree UI
- [ ] Balance progression pacing

#### Scenario System (`src/scenarios/`)
- [ ] Create scenario definition format
- [ ] Implement win/lose conditions
- [ ] Build scenario loader
- [ ] Create scenario selector UI
- [ ] Design 5-10 tutorial/challenge scenarios

#### Tutorial System
- [ ] Create interactive tutorial (guided scripting)
- [ ] Build tooltips and help system
- [ ] Write documentation (how to play, API reference)
- [ ] Create example scripts for common patterns

#### Visual Polish (`src/rendering/`)
- [ ] Add sprite-based graphics (replace colored shapes)
- [ ] Implement entity movement animation (interpolation)
- [ ] Create particle effects (harvesting, construction)
- [ ] Add UI animations and transitions
- [ ] Implement camera shake, screenshake for events
- [ ] **(Later)** Add shaders for lighting/effects

#### Audio (Optional for Prototype)
- [ ] Integrate audio library
- [ ] Add background music
- [ ] Create sound effects (entity actions, UI)

#### Performance Optimization
- [ ] Profile and optimize hot paths
- [ ] Improve script execution performance
- [ ] Optimize rendering (batching, culling)
- [ ] Reduce memory allocations
- [ ] Test with large worlds (100,000+ tiles)

### Deliverables
- Playable game with progression
- Tutorial teaches new players
- Multiple scenarios with varied challenges
- Polished visuals and animations
- Optimized performance
- Comprehensive documentation

### Success Metrics
- ✅ New player completes tutorial in <15 minutes
- ✅ At least 5 scenarios with distinct challenges
- ✅ Game maintains 60 FPS with 5,000 entities
- ✅ Tech tree provides 20+ unlocks
- ✅ Positive playtest feedback (fun, engaging)
- ✅ No critical bugs or crashes in testing

### Testing Requirements

#### Functional Tests
- All scenarios completable
- Tutorial progression works
- Tech tree unlocks apply correctly

#### Performance Tests
- Stress test: 10,000 entities, 100,000 tile world
- Long-run stability: 100,000 ticks without leak

#### User Testing
- Playtest with 5-10 users
- Collect feedback on difficulty, clarity, fun
- Iterate based on feedback

---

## Subagent Coordination Strategy

### Parallel Development Opportunities

The architecture allows for significant parallel development:

**Group A: Core Engine (Phase 1)**
- Subagent 1: Hex grid and world systems
- Subagent 2: Entity system and managers
- Subagent 3: Rendering pipeline
- Subagent 4: Game loop and timing

**Group B: Scripting (Phase 2)**
- Subagent 1: Lua integration and VM
- Subagent 2: Sandbox and security
- Subagent 3: Game API implementation
- Subagent 4: Script manager and hot-reload

**Group C: Gameplay (Phase 3)**
- Subagent 1: Resource and construction systems
- Subagent 2: Entity actions and behaviors
- Subagent 3: Pathfinding
- Subagent 4: Energy and survival mechanics

**Group D: UI and Content (Phases 4-5)**
- Subagent 1: Code editor
- Subagent 2: UI panels
- Subagent 3: Scenario system
- Subagent 4: Visual polish

### Integration Points

**Weekly Integration**:
- All subagents merge to main branch
- Integration tests run on combined codebase
- Conflicts resolved collaboratively

**Interface Contracts**:
- Each module defines clear public API
- API documented before implementation
- Mock implementations for testing dependencies

### Communication Protocol

**Documentation Requirements**:
- Each subagent documents their module's API
- Changes to interfaces require notification
- Integration blockers escalated immediately

**Code Review**:
- Peer review before merge
- Automated tests must pass
- Performance benchmarks must meet targets

---

## Testing Strategy Summary

### Test Categories

1. **Unit Tests**: Test individual functions/modules in isolation
2. **Integration Tests**: Test interactions between systems
3. **Performance Tests**: Benchmark and validate performance targets
4. **Gameplay Tests**: Validate game mechanics and balance
5. **User Tests**: Real users play and provide feedback

### Coverage Targets

- **Unit Test Coverage**: >80% of non-UI code
- **Integration Test Coverage**: All major workflows (gather, build, script)
- **Performance Tests**: All critical paths benchmarked
- **User Testing**: At least 3 rounds of playtesting

### Continuous Testing

**On Every Commit**:
- All unit tests
- Code formatting check
- Build verification

**Nightly**:
- Full integration test suite
- Performance benchmarks
- Memory leak detection

**Per-Phase**:
- User playtesting
- Performance profiling
- Stress testing

---

## Risk Mitigation

### Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Lua performance insufficient | Medium | High | Prototype early, benchmark, consider LuaJIT |
| Rendering performance poor | Low | Medium | Choose proven library (Raylib), profile early |
| Pathfinding too slow | Medium | Medium | Optimize algorithm, limit calls, use spatial partitioning |
| Memory leaks in Lua integration | Medium | High | Comprehensive testing, profiling, careful C API usage |
| Complex entity behaviors hard to script | High | High | Iterate on API design, gather user feedback early |

### Schedule Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Phase overruns | Medium | Medium | Build buffer into estimates, prioritize ruthlessly |
| Scope creep | High | High | Strict feature freeze per phase, defer nice-to-haves |
| Integration issues | Medium | High | Regular integration, clear interfaces, good communication |
| Subagent coordination difficulties | Medium | Medium | Clear task boundaries, regular sync meetings |

### Design Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Gameplay not fun | Medium | Critical | Early playtesting, iterate on core loop |
| Scripting too complex for players | High | High | Tutorial system, examples, iterative API refinement |
| Balance issues | High | Medium | Extensive playtesting, metrics collection |

---

## Success Criteria (Overall)

### Prototype Success (End of Phase 5)

- ✅ Player can script entities to gather resources and build structures
- ✅ Technology tree provides meaningful progression
- ✅ Tutorial successfully teaches basic scripting
- ✅ At least 5 completable scenarios
- ✅ Game runs at 60 FPS with 1,000+ entities
- ✅ Positive feedback from 80%+ of playtesters
- ✅ Codebase is maintainable and documented
- ✅ All critical bugs resolved

### Readiness for Next Stage

After successful prototype, the game will be ready for:
- Visual polish (advanced shaders, 3D effects)
- Audio integration
- Additional content (more scenarios, entities, structures)
- Advanced features (multiplayer, mod support)
- Marketing and distribution preparation

---

## Appendix: Development Commands

### Build and Run
```bash
# Build debug version
zig build

# Build and run
zig build run

# Build release version
zig build -Doptimize=ReleaseFast

# Run tests
zig build test

# Run specific test
zig build test --summary all -- --filter "hex_math"

# Run benchmarks
zig build bench
```

### Development Workflow
```bash
# Watch mode (rebuild on changes) - requires external tool
# e.g., using 'entr' or similar

# Format code
zig fmt src/

# Check without building
zig build-exe src/main.zig --check

# Run with profiling
zig build run -Dprofile=true
```

### Testing
```bash
# Unit tests
zig build test:unit

# Integration tests
zig build test:integration

# Performance tests
zig build test:perf

# All tests
zig build test:all
```

---

## Next Steps

1. **Review this plan** with stakeholders
2. **Set up Phase 0** infrastructure
3. **Assign subagents** to Phase 1 tasks
4. **Begin development** with clear milestones
5. **Iterate and refine** based on early results

Let's build something amazing! 🚀
