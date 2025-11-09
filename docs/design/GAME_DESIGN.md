# Game Design Document

## High-Level Vision

A programming-driven automation game where players write Lua scripts to control a collective of entities. The core appeal is the meta-game of iterative script development, optimization, and orchestration as players grow their collective and overcome increasingly complex challenges.

## Core Gameplay Loop

1. **Observe** - Watch your scripted entities perform their tasks
2. **Analyze** - Identify inefficiencies, bottlenecks, or failures
3. **Script** - Write or modify Lua code to improve entity behavior
4. **Deploy** - Upload scripts to entities or entity groups
5. **Iterate** - Repeat the cycle, progressively improving your automation

## World Structure

### Hex-Based World
- Logic operates on a hexagonal grid system
- Each hex tile can contain:
  - Terrain types (affects movement, buildability)
  - Resources (harvestable materials)
  - Structures (built by entities)
  - Entities (player's scripted units)
  - Environmental hazards or features

### Visual Presentation
- **Prototype Phase**: Visual elements snap to hex grid
- **Polish Phase**: Smooth interpolation between hexes for fluid movement

### World Generation
- Procedurally generated maps (configurable seed)
- Resource distribution affects strategy
- Varying biomes/regions with different properties

## Entity System

Entities are the autonomous agents that players control through Lua scripts. All entities share core properties but can specialize into different roles.

### Entity Core Properties
- **Position**: Current hex location
- **Energy**: Required for actions, depletes over time
- **Inventory**: Can carry resources/items
- **Script**: Currently running Lua code
- **Memory**: Persistent data storage accessible to scripts
- **Role**: Specialization (Worker, Combat, Scout, etc.)

### Entity Types (Specializations)

#### Workers
- **Primary**: Resource gathering and construction
- **Capabilities**: Mine, harvest, build, repair, transport
- **Strengths**: High carry capacity, efficient at labor
- **Weaknesses**: Vulnerable to combat

#### Combat Units
- **Primary**: Defense and territorial control
- **Capabilities**: Attack, patrol, guard, defend structures
- **Strengths**: High damage/armor
- **Weaknesses**: Higher energy consumption, can't build

#### Scouts
- **Primary**: Exploration and information gathering
- **Capabilities**: Fast movement, reveal fog of war, detect threats
- **Strengths**: Speed, vision range
- **Weaknesses**: Fragile, low carry capacity

#### Specialized Roles
- **Engineers**: Advanced construction, technology research
- **Medics/Repairers**: Restore entity health/durability
- **Carriers**: Extreme carry capacity, act as mobile storage
- Players can define custom roles through script assignment

### Autonomous Behavior
- Entities have baseline survival behaviors (seek energy when low)
- Player scripts augment and override default behaviors
- Balance between automation and player control is key

## Lua Scripting System

### Player Code Interaction

Players write Lua scripts that:
1. Define entity decision-making logic
2. Coordinate multi-entity behaviors
3. Implement economic/resource management strategies
4. React to environmental changes and threats

### Script Execution Model
- Scripts execute once per game tick for each entity
- Tick rate: TBD (likely 1-5 ticks per second)
- Scripts have CPU/time limits to prevent infinite loops
- Scripts can access entity state, nearby environment, and global memory

### Script Organization
- **Individual Entity Scripts**: Assigned to specific entities
- **Role-Based Scripts**: All entities of a role share a script
- **Global Scripts**: Run once per tick, coordinate collective behavior
- **Event Handlers**: Trigger on specific conditions (resource found, combat initiated)

### Code Persistence
- Scripts stored as in-game items/data
- Can be shared between entities
- Versioning system for iterating on scripts
- In-game code editor/console (part of UI)

## Meta-Progression

### Technology Tree
- Research system unlocks:
  - New entity types
  - Advanced structures
  - Enhanced scripting APIs
  - Efficiency improvements

### Resource Economy
- Multiple resource types (energy, minerals, rare materials)
- Processing chains (raw → refined → advanced)
- Resource scarcity drives expansion and optimization

### Collective Growth
- Start with small number of entities
- Grow population through:
  - Construction of spawning structures
  - Accumulating necessary resources
  - Meeting energy/infrastructure requirements

### Challenges & Objectives
- **Sandbox Mode**: Free-form growth and experimentation
- **Scenario Mode**: Specific challenges with win conditions
  - "Gather 10,000 rare minerals"
  - "Survive 500 ticks against hostile environment"
  - "Build an automated factory producing X items per tick"
  - "Optimize script efficiency (lowest CPU usage)"

## Core Mechanics

### Energy System
- All entities require energy to function
- Energy sources:
  - Harvestable energy deposits
  - Energy-generating structures
  - Energy conversion from other resources
- Energy distribution challenges drive infrastructure design

### Construction System
- Entities can build structures on hex tiles
- Structures provide:
  - Resource processing
  - Entity spawning
  - Energy generation
  - Storage capacity
  - Defensive capabilities
- Construction requires resources and time

### Environmental Threats
- **Resource Depletion**: Depleting resources forces expansion
- **Hazards**: Damaging tiles, environmental events
- **Hostile Entities** (later): Scripted enemy collectives or wildlife

### Information & Visibility
- Fog of war obscures unexplored areas
- Entity vision reveals surrounding hexes
- Scouting critical for finding resources and planning expansion

## User Experience Flow

### New Player Experience
1. Tutorial introduces basic entity control via simple scripts
2. Pre-written scripts demonstrate common patterns
3. Gradual introduction of complexity
4. Example scenarios showcasing different strategies

### Advanced Play
- Complex multi-script architectures
- Performance optimization challenges
- Emergent strategies from script interaction
- Community sharing of clever solutions

## Differentiators from Screeps

While inspired by Screeps, this game will differentiate through:
- **Single-player focus** (initially) - more accessible, narrative possibilities
- **Hex-based world** - different spatial dynamics than square grid
- **Specialized entity roles** - more variety in unit types
- **Meta-progression structure** - clear advancement through tech tree
- **Scenario-based challenges** - defined objectives alongside sandbox

## Design Philosophy

- **Programming is the gameplay** - The joy is in writing, debugging, optimizing code
- **Mastery through iteration** - Satisfaction from improving your systems over time
- **Emergent complexity** - Simple rules create complex strategic possibilities
- **Player creativity** - Multiple valid solutions to challenges
- **Accessible but deep** - Easy to start, difficult to master

## Open Questions for Future Design

- Exact entity statistics (health, damage, costs, etc.)
- Specific resource types and their uses
- Complete technology tree structure
- Balancing CPU limits for scripts
- Save/load system design
- Victory conditions for scenario mode
- Replay/time-rewind features for debugging scripts
