# Module Agent Template

## Agent Name
`{MODULE_NAME}-agent`

## Purpose
Implement the `{MODULE_NAME}` module according to the API contract and specification.

## When to Use
- Module has clear API specification (interface defined)
- Module can be developed in isolation (dependencies mocked if needed)
- Task requires >100 lines of code or multiple files
- Module has comprehensive requirements in design docs

## Inputs Required

### Required Inputs
- **Module Name**: `{MODULE_NAME}` (e.g., "hex_grid", "entity_manager")
- **Module Path**: `{MODULE_PATH}` (e.g., "src/world/hex_grid.zig")
- **API Contract**: Full interface specification with function signatures
- **Dependencies**: List of modules this depends on (with their interfaces)
- **Test Criteria**: Specific test requirements and success criteria

### Optional Inputs
- **Reference Implementation**: Similar code or algorithm references
- **Performance Requirements**: Specific benchmarks to meet
- **Design Constraints**: Memory limits, threading requirements, etc.

## Instructions

### Step 1: Review Specification
1. Read the module's section in `ARCHITECTURE.md`
2. Review the API contract provided
3. Understand dependencies and their interfaces
4. Clarify any ambiguities (escalate if needed)

### Step 2: Design Module Structure
1. Plan internal data structures
2. Identify helper functions needed
3. Consider error handling strategy
4. Plan memory management approach

### Step 3: Implement Core Functionality
1. Create the module file at `{MODULE_PATH}`
2. Implement public API functions first
3. Implement internal helper functions
4. Add error handling and validation
5. Add documentation comments on all public functions

### Step 4: Write Tests
1. Create test file at `tests/{MODULE_NAME}_test.zig`
2. Write unit tests for each public function
3. Test edge cases and error conditions
4. Test performance if requirements specified
5. Ensure all tests pass

### Step 5: Integration Preparation
1. If dependencies are mocked, document what real implementation needs
2. Create module README summarizing API and usage
3. Document any deviations from original spec (with rationale)

### Step 6: Validation
1. Verify all API contract functions implemented
2. Verify all tests pass
3. Verify code follows Zig style guidelines
4. Verify documentation is complete

## Success Criteria

### Required
- [ ] All API contract functions implemented and working
- [ ] All public functions have doc comments
- [ ] Unit tests written for all public functions
- [ ] All tests pass (`zig build test`)
- [ ] Code compiles without errors or warnings
- [ ] No memory leaks (verified with tests)

### Optional
- [ ] Performance benchmarks meet targets (if specified)
- [ ] Integration tests pass (if dependencies available)
- [ ] Module README created

## Output Artifacts

### Primary Outputs
1. **Implementation**: `{MODULE_PATH}` with complete implementation
2. **Tests**: `tests/{MODULE_NAME}_test.zig` with comprehensive test suite
3. **Module README**: `{MODULE_PATH}/README.md` summarizing API

### Secondary Outputs
4. **Integration Notes**: Document for integration agent (if mocks used)
5. **Performance Report**: Benchmark results (if applicable)

## Example Invocation

```
Task(
  subagent_type="general-purpose",
  description="Implement hex grid module",
  prompt="""
You are implementing the hex_grid module for a Zig game engine.

**Module Name**: hex_grid
**Module Path**: src/world/hex_grid.zig
**Test Path**: tests/hex_grid_test.zig

**API Contract**:
\```zig
// src/world/hex_grid.zig

pub const HexCoord = struct {
    q: i32,
    r: i32,

    pub fn init(q: i32, r: i32) HexCoord;
    pub fn neighbors(self: HexCoord) [6]HexCoord;
    pub fn distance(self: HexCoord, other: HexCoord) u32;
    pub fn toPixel(self: HexCoord, hex_size: f32) Vec2;
};

pub const HexGrid = struct {
    width: u32,
    height: u32,
    tiles: []Tile,
    allocator: Allocator,

    pub fn init(allocator: Allocator, width: u32, height: u32) !*HexGrid;
    pub fn deinit(self: *HexGrid) void;
    pub fn getTile(self: *HexGrid, coord: HexCoord) ?*Tile;
    pub fn isValid(self: *HexGrid, coord: HexCoord) bool;
};
\```

**Dependencies**:
- Zig std library
- Vec2 type from src/utils/math.zig (can mock if not yet implemented)
- Tile type from src/world/tile.zig (can mock if not yet implemented)

**Test Requirements**:
- Test HexCoord.neighbors() returns correct 6 neighbors
- Test HexCoord.distance() with known coordinates
- Test HexGrid.init() and deinit() (no memory leaks)
- Test HexGrid.getTile() for valid and invalid coordinates
- Test HexGrid.isValid() for edge cases

**Reference**:
Use axial coordinate system. See: https://www.redblobgames.com/grids/hexagons/

**Success Criteria**:
- All API functions implemented
- All tests pass
- No compiler warnings
- Doc comments on all public functions

Follow the module agent template instructions. Implement, test, and document the module.
"""
)
```

## Common Pitfalls

### ❌ Pitfall 1: Incomplete API Implementation
**Problem**: Implementing only some functions from contract.
**Solution**: Checklist all contract functions at start and end.

### ❌ Pitfall 2: Insufficient Testing
**Problem**: Only testing happy path, missing edge cases.
**Solution**: Test boundary conditions, invalid inputs, error cases.

### ❌ Pitfall 3: Ignoring Dependencies
**Problem**: Assuming dependencies work without checking their interface.
**Solution**: Read dependency interfaces carefully, mock if not available.

### ❌ Pitfall 4: Poor Documentation
**Problem**: Code works but no comments explaining how to use it.
**Solution**: Document every public function with purpose, params, returns, errors.

### ❌ Pitfall 5: Memory Leaks
**Problem**: Allocations without corresponding deallocations.
**Solution**: Test init/deinit cycles, use Zig's leak detection in tests.

## Variations

### Variation 1: Prototype Module
If specification is unclear or experimental:
- Focus on core functionality only
- Document assumptions made
- Mark as prototype in code comments
- Plan for refactoring later

### Variation 2: Performance-Critical Module
If module is in hot path:
- Write benchmarks first
- Profile and optimize iteratively
- Document performance characteristics
- Consider SIMD or cache optimization

### Variation 3: Module with C Dependencies
If module wraps C library:
- Carefully handle C/Zig boundary
- Test C error codes thoroughly
- Document C library version requirements
- Provide safe Zig wrappers

## Agent Self-Check

Before marking task complete, agent should verify:

1. **Completeness**: All contract functions implemented? ✓/✗
2. **Correctness**: All tests pass? ✓/✗
3. **Quality**: Code reviewed for bugs, leaks, style? ✓/✗
4. **Documentation**: All public APIs documented? ✓/✗
5. **Integration**: Ready for integration? ✓/✗

If any ✗, continue working. If all ✓, task complete.

---

**Template Version**: 1.0
**Last Updated**: 2025-11-09
