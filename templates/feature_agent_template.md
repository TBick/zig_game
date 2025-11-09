# Feature Agent Template

## Agent Name
`{FEATURE_NAME}-feature-agent`

## Purpose
Implement a cross-cutting feature that spans multiple modules/systems.

## When to Use
- Feature touches 3+ modules
- Requires coordinated changes across systems
- Has end-to-end user workflow
- Feature is well-defined in design documents

## Inputs Required

### Required Inputs
- **Feature Name**: `{FEATURE_NAME}` (e.g., "resource_harvesting", "construction_system")
- **Feature Specification**: Detailed description from design docs
- **Modules Affected**: List of modules this feature touches
- **User Workflow**: Step-by-step user/player interaction
- **Success Criteria**: How to verify feature works end-to-end

### Optional Inputs
- **Dependencies**: Other features this depends on
- **Performance Requirements**: Specific benchmarks
- **UI Requirements**: If feature has user interface

## Instructions

### Step 1: Understand Feature Scope
1. Read feature specification from `GAME_DESIGN.md` or `DEVELOPMENT_PLAN.md`
2. Identify all modules that need changes
3. Understand data flow through the system
4. Identify integration points between modules

### Step 2: Design Feature Architecture
1. Plan how modules will interact for this feature
2. Identify new functions needed in each module
3. Identify data structures needed (shared state, events, etc.)
4. Consider error handling across module boundaries

### Step 3: Implement Changes Per Module
For each affected module:
1. Add new functions or modify existing ones
2. Maintain module's API contracts
3. Add module-level tests for new functionality
4. Document changes in module

### Step 4: Implement Integration Layer
1. Create coordination code (if needed)
2. Wire modules together for feature workflow
3. Handle data flow between modules
4. Add error propagation

### Step 5: Write Integration Tests
1. Create end-to-end test for feature workflow
2. Test happy path (feature works as intended)
3. Test error cases (what if module fails?)
4. Test edge cases (boundary conditions)

### Step 6: Validation
1. Verify feature works end-to-end
2. Verify no regressions in affected modules (existing tests pass)
3. Verify performance acceptable (if requirements specified)
4. Document feature usage

## Success Criteria

### Required
- [ ] Feature workflow functional end-to-end
- [ ] All affected modules still pass their existing tests
- [ ] Integration tests written and passing
- [ ] Feature performs within requirements (if specified)
- [ ] User can complete workflow as designed
- [ ] No regressions introduced

### Optional
- [ ] Feature documented in user-facing docs (if applicable)
- [ ] Performance benchmarks created
- [ ] Example usage code provided

## Output Artifacts

### Primary Outputs
1. **Modified Modules**: Updated code in affected modules
2. **Integration Code**: Coordination layer (if needed)
3. **Integration Tests**: End-to-end feature tests

### Secondary Outputs
4. **Feature Documentation**: How to use the feature
5. **Performance Report**: Benchmarks (if applicable)
6. **Migration Guide**: If feature changes existing behavior

## Example Invocation

```
Task(
  subagent_type="general-purpose",
  description="Implement resource harvesting feature",
  prompt="""
You are implementing the resource harvesting feature for the game.

**Feature Name**: resource_harvesting

**Feature Specification** (from GAME_DESIGN.md):
Players can command entities to harvest resources from tiles. Harvesting:
- Requires entity adjacent to resource tile
- Takes multiple ticks (3-5 ticks per resource unit)
- Adds resources to entity inventory
- Depletes resource deposit on tile
- Fails if inventory full or resource depleted

**Modules Affected**:
1. src/entities/systems.zig - Add harvest action system
2. src/world/tile.zig - Add resource deposit data
3. src/resources/resource_manager.zig - Track resource flow
4. src/scripting/api.zig - Expose harvest() to Lua

**User Workflow**:
1. Player script calls harvest(position) from entity
2. Game validates: entity adjacent? resource present? inventory space?
3. If valid: Start harvest action (multi-tick)
4. Each tick: Decrement resource deposit, increment entity inventory
5. When complete: Entity can move or perform new action

**Success Criteria**:
- Entity can harvest resource and add to inventory
- Resource depletes from tile as harvested
- Multi-tick harvesting works correctly
- Lua script can call harvest() function
- Integration test demonstrates full workflow

**API Changes Needed**:

In src/entities/systems.zig:
\```zig
pub const HarvestAction = struct {
    target: HexCoord,
    ticks_remaining: u32,
};

pub fn processHarvestActions(world: *World, entities: *EntityManager) void;
\```

In src/world/tile.zig:
\```zig
pub const ResourceDeposit = struct {
    resource_type: ResourceType,
    amount: u32,
};

pub const Tile = struct {
    // ... existing fields
    resource: ?ResourceDeposit,

    pub fn depleteResource(self: *Tile, amount: u32) void;
};
\```

In src/scripting/api.zig:
\```zig
// Lua: harvest(position)
fn luaHarvest(L: *lua.State) i32;
\```

Implement this feature across all affected modules. Write integration test demonstrating the workflow.
"""
)
```

## Common Pitfalls

### ❌ Pitfall 1: Breaking Module Boundaries
**Problem**: Feature creates tight coupling between modules.
**Solution**: Use clear interfaces, avoid direct access to module internals.

### ❌ Pitfall 2: No Integration Tests
**Problem**: Each module works, but feature doesn't work end-to-end.
**Solution**: Write integration test exercising full workflow.

### ❌ Pitfall 3: Regressions
**Problem**: Feature works but breaks existing functionality.
**Solution**: Run all existing tests, ensure they still pass.

### ❌ Pitfall 4: Incomplete Error Handling
**Problem**: Happy path works, but errors crash or corrupt state.
**Solution**: Test error cases, ensure graceful failure.

## Agent Self-Check

Before marking complete:

1. **Workflow Complete**: Can user/player complete intended workflow? ✓/✗
2. **All Modules Updated**: Every affected module has necessary changes? ✓/✗
3. **No Regressions**: All existing tests still pass? ✓/✗
4. **Integration Tested**: End-to-end test exists and passes? ✓/✗
5. **Error Handling**: Feature fails gracefully on errors? ✓/✗

---

**Template Version**: 1.0
**Last Updated**: 2025-11-09
