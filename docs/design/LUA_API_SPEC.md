# Lua Scripting API Specification

## Overview

This document specifies the Lua API available to player scripts. The API is designed to be:
- **Intuitive**: Easy to learn for beginners
- **Powerful**: Expressive enough for complex behaviors
- **Safe**: Sandboxed and resource-limited
- **Deterministic**: Same inputs produce same outputs

## API Design Principles

1. **Read-Query-Command Pattern**: Scripts query state, then issue commands
2. **No Direct Mutation**: Scripts can't directly modify game state, only request actions
3. **Functional Style**: Prefer pure functions where possible
4. **Lua-Friendly**: Follow Lua conventions (1-indexed arrays, etc.)
5. **Error Tolerant**: Invalid calls return nil/false, don't crash

## Script Execution Model

Each entity with a script has the script executed **once per game tick**.

```lua
-- Script lifecycle:
-- 1. Script executes from top to bottom
-- 2. Script can call API functions
-- 3. Script can store data in 'memory' table
-- 4. Script execution completes (or times out)
-- 5. Actions are queued and executed by engine
```

## Sandbox Environment

### Available Lua Standard Library

**Allowed**:
- Base functions: `assert`, `error`, `ipairs`, `next`, `pairs`, `pcall`, `select`, `tonumber`, `tostring`, `type`, `xpcall`
- `string` library (all functions)
- `table` library (all functions)
- `math` library (all functions)
- Limited `os`: `os.clock`, `os.time`, `os.date`

**Prohibited** (security):
- `dofile`, `loadfile`, `load` (no arbitrary code execution)
- `require` (no module loading)
- File I/O functions
- `os.execute`, `os.exit`, `os.remove`, etc.
- `debug` library (no introspection)

### CPU and Memory Limits

- **CPU Limit**: 10,000 Lua instructions per tick (configurable)
- **Memory Limit**: 1 MB per entity script state
- Exceeding limits terminates script gracefully with error

---

## Global Context

### `self` Table

The `self` table represents the entity executing the script.

```lua
-- Entity properties (read-only)
self.id            -- EntityId (number): Unique entity identifier
self.position      -- HexCoord: Current position {q, r}
self.role          -- string: Entity role ("worker", "combat", "scout", etc.)
self.energy        -- number: Current energy level (0-100)
self.max_energy    -- number: Maximum energy capacity
self.health        -- number: Current health (combat units)
self.max_health    -- number: Maximum health

-- Inventory (read-only)
self.inventory     -- table: {resource_type -> quantity}
self.carry_capacity -- number: Max inventory weight

-- Example:
if self.energy < 20 then
    log("Low energy! Need to recharge")
end
```

### `memory` Table

Persistent storage for the entity. Data persists across ticks and game saves.

```lua
-- Initialize memory on first run
memory.state = memory.state or "idle"
memory.home_position = memory.home_position or self.position
memory.ticks_alive = (memory.ticks_alive or 0) + 1

-- Use memory for state machines
if memory.state == "gathering" then
    if self.inventory["minerals"] > 10 then
        memory.state = "returning"
    end
end
```

**Rules**:
- Only simple types allowed: numbers, strings, booleans, tables
- No circular references
- No functions or userdata
- Size limit: 10 KB serialized (configurable)

### `game` Table

Global game state (read-only).

```lua
game.tick          -- number: Current game tick
game.time          -- number: Game time in seconds (tick * tick_duration)
game.world_size    -- {width, height}: World dimensions in hexes
```

---

## API Functions

### Entity State Queries

#### `getEnergy()`
Returns current energy level.

```lua
local energy = getEnergy()  -- Returns number (0-100)
```

#### `getPosition()`
Returns current position as hex coordinates.

```lua
local pos = getPosition()  -- Returns {q, r}
log("I'm at " .. pos.q .. ", " .. pos.r)
```

#### `getInventory()`
Returns inventory contents.

```lua
local inv = getInventory()  -- Returns table {resource_type -> quantity}
if inv["minerals"] >= 10 then
    log("Enough minerals to build")
end
```

#### `getRole()`
Returns entity's role.

```lua
local role = getRole()  -- Returns string: "worker", "combat", etc.
```

---

### World Queries

#### `getTile(position)`
Returns information about a tile.

```lua
local tile = getTile({q = 0, r = 5})
-- Returns table or nil if out of bounds
-- {
--   position = {q, r},
--   terrain = "grass" | "rock" | "water" | etc.,
--   resource = {type = "minerals", amount = 50} or nil,
--   structure = {type = "spawner", owner = entity_id} or nil,
--   entities = {entity_id, entity_id, ...} (entities on this tile)
-- }

if tile and tile.resource then
    log("Found " .. tile.resource.amount .. " " .. tile.resource.type)
end
```

#### `findNearbyResources(resource_type, range)`
Finds resources within range.

```lua
local resources = findNearbyResources("minerals", 10)
-- Returns array of {position = {q, r}, amount = number}
-- Sorted by distance (closest first)

if #resources > 0 then
    local closest = resources[1]
    moveTo(closest.position)
end
```

#### `findNearbyEntities(range, filter)`
Finds entities within range.

```lua
-- Find all entities within 5 hexes
local entities = findNearbyEntities(5)

-- Find only workers within 5 hexes
local workers = findNearbyEntities(5, {role = "worker"})

-- Find specific entity by ID
local entity = findEntityById(some_id)

-- Returns array of entity info tables:
-- {
--   id = entity_id,
--   position = {q, r},
--   role = "worker",
--   energy = 50,
--   owner = "self" | "ally" | "enemy" (for multiplayer)
-- }
```

#### `findNearbyStructures(range, structure_type)`
Finds structures within range.

```lua
local spawners = findNearbyStructures(20, "spawner")
-- Returns array of {position = {q, r}, type = string}

-- Find any structure type
local all_structures = findNearbyStructures(10)
```

#### `getPath(from, to)`
Calculates path between two positions.

```lua
local path = getPath(self.position, {q = 10, r = 5})
-- Returns array of positions [{q, r}, {q, r}, ...] or nil if no path

if path then
    log("Distance: " .. #path .. " hexes")
    moveTo(path[2])  -- Move to next step
end
```

---

### Actions

Actions are queued and executed by the engine. Only one action per tick is allowed.

#### `moveTo(position)`
Move toward target position.

```lua
-- Returns boolean: true if action queued, false if invalid
local success = moveTo({q = 5, r = 10})

-- Movement speed depends on entity type and terrain
-- May take multiple ticks to reach destination
```

#### `harvest(position)`
Harvest resource at position.

```lua
-- Must be adjacent to resource
local tile = getTile({q = self.position.q + 1, r = self.position.r})
if tile and tile.resource then
    harvest(tile.position)
end

-- Harvesting takes multiple ticks
-- Adds resources to inventory
```

#### `build(structure_type, position)`
Construct a structure.

```lua
-- Must be adjacent to build position
-- Must have required resources in inventory
local success = build("spawner", {q = 5, r = 5})

-- Building takes multiple ticks
-- Consumes resources from inventory
```

#### `transfer(target_entity_id, resource_type, amount)`
Transfer resources to another entity.

```lua
-- Must be adjacent to target entity
transfer(123, "minerals", 10)

-- Or transfer to structure
transferToStructure(structure_position, "minerals", 10)
```

#### `attack(target_entity_id)`
Attack another entity (combat units only).

```lua
local enemies = findNearbyEntities(2, {owner = "enemy"})
if #enemies > 0 then
    attack(enemies[1].id)
end
```

#### `repair(target_entity_id)`
Repair entity or structure (requires resources).

```lua
repair(damaged_entity_id)
```

#### `consume(resource_type, amount)`
Consume resource from inventory (e.g., convert minerals to energy).

```lua
if self.energy < 20 and self.inventory["energy_cell"] > 0 then
    consume("energy_cell", 1)  -- Restores energy
end
```

---

### Communication

#### `broadcast(message, range)`
Send message to nearby entities.

```lua
broadcast({
    type = "help",
    position = self.position,
    reason = "under_attack"
}, 20)  -- Range of 20 hexes
```

#### `getMessages()`
Retrieve messages broadcast this tick.

```lua
local messages = getMessages()
-- Returns array of {sender_id, message_data, distance}

for i, msg in ipairs(messages) do
    if msg.message_data.type == "help" then
        log("Help request from " .. msg.sender_id)
    end
end
```

---

### Utility Functions

#### `log(message)`
Log message to console/UI.

```lua
log("Entity " .. self.id .. " is gathering minerals")
-- Visible in game console, useful for debugging
```

#### `distance(pos1, pos2)`
Calculate hex distance between positions.

```lua
local dist = distance(self.position, {q = 10, r = 5})
log("Target is " .. dist .. " hexes away")
```

#### `random()` / `random(n)` / `random(m, n)`
Generate random numbers (seeded for determinism).

```lua
local r = random()        -- Random float [0, 1)
local r = random(10)      -- Random int [1, 10]
local r = random(5, 15)   -- Random int [5, 15]
```

#### `neighbors(position)`
Get 6 neighboring hex positions.

```lua
local adj = neighbors(self.position)
-- Returns array of 6 positions

for i, pos in ipairs(adj) do
    local tile = getTile(pos)
    -- Check adjacent tiles
end
```

---

## Complete Example Scripts

### Example 1: Simple Resource Gatherer

```lua
-- Initialize state
memory.state = memory.state or "searching"
memory.home = memory.home or self.position

-- State machine
if memory.state == "searching" then
    -- Look for resources
    local resources = findNearbyResources("minerals", 20)
    if #resources > 0 then
        memory.target = resources[1].position
        memory.state = "moving_to_resource"
    else
        -- Wander randomly
        local adj = neighbors(self.position)
        moveTo(adj[random(1, 6)])
    end

elseif memory.state == "moving_to_resource" then
    -- Move to resource
    if distance(self.position, memory.target) <= 1 then
        memory.state = "harvesting"
    else
        moveTo(memory.target)
    end

elseif memory.state == "harvesting" then
    -- Harvest until full or depleted
    local tile = getTile(memory.target)
    if tile and tile.resource and self.inventory["minerals"] < self.carry_capacity then
        harvest(memory.target)
    else
        memory.state = "returning"
    end

elseif memory.state == "returning" then
    -- Return to home
    if distance(self.position, memory.home) <= 1 then
        memory.state = "depositing"
    else
        moveTo(memory.home)
    end

elseif memory.state == "depositing" then
    -- Deposit resources at structure
    local structures = findNearbyStructures(1, "storage")
    if #structures > 0 then
        transferToStructure(structures[1].position, "minerals", self.inventory["minerals"])
    end
    memory.state = "searching"
end
```

### Example 2: Coordinated Builder

```lua
-- Check messages for construction requests
local messages = getMessages()
for i, msg in ipairs(messages) do
    if msg.message_data.type == "build_request" then
        memory.build_target = msg.message_data.position
        memory.build_type = msg.message_data.structure
        memory.state = "building"
    end
end

-- If idle and have resources, look for build spots
if not memory.state or memory.state == "idle" then
    if self.inventory["minerals"] >= 100 then
        -- Find good spot for spawner
        local adj = neighbors(memory.home)
        for i, pos in ipairs(adj) do
            local tile = getTile(pos)
            if tile and tile.terrain ~= "water" and not tile.structure then
                memory.build_target = pos
                memory.build_type = "spawner"
                memory.state = "moving_to_build"
                break
            end
        end
    end
end

-- Execute building
if memory.state == "moving_to_build" then
    if distance(self.position, memory.build_target) <= 1 then
        memory.state = "constructing"
    else
        moveTo(memory.build_target)
    end

elseif memory.state == "constructing" then
    local success = build(memory.build_type, memory.build_target)
    if not success then
        log("Build failed, returning to idle")
        memory.state = "idle"
    end
    -- Building takes multiple ticks, engine will handle
end
```

### Example 3: Combat Patrol

```lua
-- Initialize patrol route
if not memory.patrol_points then
    memory.patrol_points = {
        {q = 0, r = 0},
        {q = 10, r = 0},
        {q = 10, r = 10},
        {q = 0, r = 10}
    }
    memory.patrol_index = 1
end

-- Check for enemies
local enemies = findNearbyEntities(5, {owner = "enemy"})
if #enemies > 0 then
    -- Engage nearest enemy
    attack(enemies[1].id)
    log("Engaging enemy " .. enemies[1].id)
else
    -- Continue patrol
    local target = memory.patrol_points[memory.patrol_index]
    if distance(self.position, target) <= 1 then
        -- Reached waypoint, move to next
        memory.patrol_index = (memory.patrol_index % #memory.patrol_points) + 1
    else
        moveTo(target)
    end
end

-- Call for help if low health
if self.health < self.max_health * 0.3 then
    broadcast({type = "help", position = self.position}, 20)
end
```

---

## Advanced Patterns

### Multi-Entity Coordination

Use `broadcast` and `getMessages` for coordination:

```lua
-- Leader entity
if self.role == "leader" then
    local resources = findNearbyResources("minerals", 30)
    if #resources > 0 then
        broadcast({
            type = "harvest_order",
            target = resources[1].position
        }, 50)
    end
end

-- Worker entities
local messages = getMessages()
for i, msg in ipairs(messages) do
    if msg.message_data.type == "harvest_order" then
        memory.task = msg.message_data.target
    end
end
```

### Energy Management

```lua
-- Always monitor energy
local energy_threshold = 20

if self.energy < energy_threshold then
    -- Emergency: find energy
    local energy_sources = findNearbyStructures(20, "energy_generator")
    if #energy_sources > 0 then
        if distance(self.position, energy_sources[1].position) <= 1 then
            -- Recharge (automatic when adjacent)
            log("Recharging...")
        else
            moveTo(energy_sources[1].position)
        end
        return  -- Don't do other actions
    end
end

-- Normal operations only if energy sufficient
-- ... rest of script
```

### Optimization: Caching Expensive Queries

```lua
-- Don't recalculate every tick
memory.resource_cache_tick = memory.resource_cache_tick or 0

if game.tick - memory.resource_cache_tick > 10 then
    -- Update cache every 10 ticks
    memory.cached_resources = findNearbyResources("minerals", 20)
    memory.resource_cache_tick = game.tick
end

-- Use cached data
if #memory.cached_resources > 0 then
    moveTo(memory.cached_resources[1].position)
end
```

---

## Error Handling

Scripts should handle potential errors:

```lua
-- Check return values
local tile = getTile(some_position)
if not tile then
    log("Invalid position")
    return
end

-- Check preconditions
if distance(self.position, target) > 1 then
    log("Too far to harvest")
    return
end

-- Use pcall for risky operations
local success, result = pcall(function()
    -- Some complex logic
    return calculate_something()
end)

if not success then
    log("Error: " .. tostring(result))
end
```

---

## Performance Guidelines

1. **Avoid nested loops** over large datasets
2. **Cache expensive queries** (pathfinding, resource searches)
3. **Limit message broadcasts** to necessary range
4. **Use early returns** to skip unnecessary computation
5. **Profile your scripts** using in-game performance panel

---

## API Evolution

This API will evolve during development. Changes will be:
- **Documented**: Changelog maintained
- **Versioned**: Scripts can declare API version
- **Backward compatible** when possible

---

## Next Steps for API Implementation

1. Implement Lua C API bindings for each function
2. Create comprehensive unit tests for each API function
3. Build example scripts covering common use cases
4. Playtest API with real scenarios
5. Iterate based on user feedback
