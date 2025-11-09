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

**Phase**: Planning and Design

This project is in the planning stage. Comprehensive design documents have been created to guide development:

- [GAME_DESIGN.md](GAME_DESIGN.md) - Core gameplay mechanics, entity systems, and design philosophy
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical architecture and system design
- [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) - Development phases, milestones, and testing strategy
- [LUA_API_SPEC.md](LUA_API_SPEC.md) - Complete specification of the Lua scripting API

## Key Features (Planned)

- **Lua Scripting**: Write code to control entity behavior
- **Hex-Based World**: Navigate and build on a hexagonal grid
- **Entity Specialization**: Workers, combat units, scouts, and custom roles
- **Resource Economy**: Gather, process, and manage multiple resource types
- **Meta-Progression**: Technology tree unlocks new capabilities
- **Scenario System**: Challenges and objectives to test your automation skills
- **In-Game Code Editor**: Write and debug scripts without leaving the game

## Technology Stack

- **Language**: Zig (performance, safety, cross-platform)
- **Scripting**: Lua 5.4 (player-facing scripting language)
- **Rendering**: TBD - likely Raylib (2D graphics, cross-platform)
- **Platform**: Native builds for Linux, Windows, macOS

## Project Structure

```
zig_game/
├── docs/              # Planning documents (GAME_DESIGN.md, etc.)
├── src/               # Zig source code (to be created)
├── scripts/           # Example Lua scripts (to be created)
├── assets/            # Game assets (to be created)
└── tests/             # Test suite (to be created)
```

## Getting Started

### Prerequisites

- Zig 0.13.0 or later
- (Additional dependencies TBD during Phase 0)

### Building (Not Yet Implemented)

```bash
# Clone the repository
git clone https://github.com/TBick/zig_game.git
cd zig_game

# Build and run (once implemented)
zig build run

# Run tests
zig build test
```

## Documentation

- **[Game Design](GAME_DESIGN.md)**: Understand the gameplay vision and mechanics
- **[Technical Architecture](ARCHITECTURE.md)**: Learn about the system design
- **[Development Plan](DEVELOPMENT_PLAN.md)**: See the roadmap and milestones
- **[Lua API Specification](LUA_API_SPEC.md)**: Reference for writing entity scripts

## Development Roadmap

### Phase 0: Setup (Current)
- Project initialization
- Build system configuration
- Development tooling

### Phase 1: Core Engine
- Hex grid system
- Entity management
- Basic rendering
- Game loop and tick system

### Phase 2: Lua Integration
- Embed Lua runtime
- Implement scripting API
- Script sandbox and CPU limiting

### Phase 3: Gameplay Systems
- Resource gathering and management
- Construction mechanics
- Pathfinding
- Energy system

### Phase 4: UI and Editor
- In-game Lua code editor
- UI panels and information displays
- Script management

### Phase 5: Content and Polish
- Technology tree
- Scenarios and challenges
- Tutorial system
- Visual polish and optimization

**Estimated Timeline**: 10-15 weeks to playable prototype

## Design Philosophy

- **Programming is the gameplay** - The joy comes from writing, debugging, and optimizing code
- **Mastery through iteration** - Satisfaction from progressively improving your systems
- **Emergent complexity** - Simple rules create complex strategic possibilities
- **Accessible but deep** - Easy to start, difficult to master

## Contributing

This is currently a personal project in the planning phase. Once development begins, contribution guidelines will be established.

## License

TBD

## Contact

- GitHub: [@TBick](https://github.com/TBick)
- Project Repository: [github.com/TBick/zig_game](https://github.com/TBick/zig_game)

---

**Status**: Planning Phase - No playable build yet. Watch this space for updates as development progresses!
