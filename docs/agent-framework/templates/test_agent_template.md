# Test Agent Template

## Agent Name
`test-{MODULE_NAME}-agent`

## Purpose
Generate comprehensive test suite for a module or feature.

## When to Use
- Module implemented but lacks tests
- Need edge case coverage beyond basic tests
- Performance benchmarking required
- Integration testing needed

## Inputs Required

### Required Inputs
- **Module/Feature Name**: `{MODULE_NAME}`
- **Code to Test**: Path to implementation file(s)
- **Test Coverage Goals**: Percentage or specific areas to cover
- **Test Type**: Unit, integration, or performance

### Optional Inputs
- **Known Edge Cases**: Specific scenarios to test
- **Performance Targets**: Benchmarks to verify
- **Existing Tests**: Don't duplicate these

## Instructions

### Step 1: Analyze Code
1. Read the implementation thoroughly
2. Identify all public functions/APIs
3. Understand function contracts (inputs, outputs, errors)
4. Identify edge cases and boundary conditions

### Step 2: Plan Test Coverage
1. List all functions to test
2. For each function, identify test cases:
   - Happy path (typical usage)
   - Boundary conditions (min, max, zero, etc.)
   - Error conditions (invalid inputs, null pointers, etc.)
   - Edge cases (special states, unusual inputs)

### Step 3: Write Unit Tests
For each function:
1. Create test function in `tests/{MODULE_NAME}_test.zig`
2. Test happy path first
3. Test boundary conditions
4. Test error handling
5. Use descriptive test names (e.g., `test "getTile with invalid coord returns null"`)

### Step 4: Write Integration Tests (if applicable)
If testing multiple modules together:
1. Create integration test file
2. Set up test environment (init modules)
3. Execute multi-module workflow
4. Verify end-to-end behavior
5. Clean up (deinit modules)

### Step 5: Write Performance Tests (if applicable)
If benchmarking required:
1. Create benchmark file
2. Implement timing harness
3. Run function N times, measure average
4. Compare against performance targets
5. Document results

### Step 6: Verify Coverage
1. Ensure all public functions tested
2. Check code coverage (if tools available)
3. Ensure all error paths tested
4. Add missing tests for gaps

## Success Criteria

### Required
- [ ] All public functions have tests
- [ ] Happy path tested for each function
- [ ] Error cases tested
- [ ] All tests pass
- [ ] Test coverage >80% (or specified target)

### Optional
- [ ] Performance benchmarks created
- [ ] Integration tests written
- [ ] Edge cases comprehensively covered
- [ ] Test utilities created for future tests

## Output Artifacts

### Primary Outputs
1. **Test Files**: Complete test suite in `tests/`
2. **Test Report**: Summary of what's tested

### Secondary Outputs
3. **Performance Benchmarks**: If applicable
4. **Test Utilities**: Helper functions for future tests
5. **Coverage Report**: What percentage is covered

## Example Invocation

```
Task(
  subagent_type="general-purpose",
  description="Write tests for hex grid module",
  prompt="""
Write comprehensive test suite for the hex_grid module.

**Module**: src/world/hex_grid.zig
**Test File**: tests/hex_grid_test.zig
**Coverage Goal**: >80%

**Functions to Test**:
1. HexCoord.init(q, r)
2. HexCoord.neighbors()
3. HexCoord.distance(other)
4. HexCoord.toPixel(hex_size)
5. HexGrid.init(allocator, width, height)
6. HexGrid.deinit()
7. HexGrid.getTile(coord)
8. HexGrid.isValid(coord)

**Test Cases Required**:

For HexCoord.neighbors():
- Returns exactly 6 neighbors
- Neighbors are in correct positions (clockwise from top)
- Works for origin (0, 0)
- Works for edge coordinates

For HexCoord.distance():
- Distance to self is 0
- Distance is symmetric (dist(a,b) == dist(b,a))
- Test known coordinates: (0,0) to (3,3) should be 6

For HexGrid.init/deinit():
- Successfully creates grid
- No memory leaks (verify with test allocator)
- Invalid dimensions (0, negative) return error

For HexGrid.getTile():
- Valid coord returns tile
- Invalid coord returns null
- Boundary coords tested (edges of grid)

Write all tests in tests/hex_grid_test.zig using Zig test framework.
Ensure all tests pass with `zig build test`.
"""
)
```

## Test Patterns

### Pattern 1: Table-Driven Tests
For testing multiple inputs:
```zig
test "distance calculation with known values" {
    const cases = [_]struct {
        a: HexCoord,
        b: HexCoord,
        expected: u32,
    }{
        .{ .a = .{.q=0,.r=0}, .b = .{.q=0,.r=0}, .expected = 0 },
        .{ .a = .{.q=0,.r=0}, .b = .{.q=1,.r=0}, .expected = 1 },
        .{ .a = .{.q=0,.r=0}, .b = .{.q=3,.r=3}, .expected = 6 },
    };

    for (cases) |case| {
        const dist = case.a.distance(case.b);
        try testing.expectEqual(case.expected, dist);
    }
}
```

### Pattern 2: Memory Leak Detection
```zig
test "no memory leaks in grid init/deinit" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var grid = try HexGrid.init(arena.allocator(), 10, 10);
    defer grid.deinit();

    // Use grid...

    // Arena will catch leaks when deinit
}
```

### Pattern 3: Error Testing
```zig
test "init fails with invalid dimensions" {
    const result = HexGrid.init(testing.allocator, 0, 10);
    try testing.expectError(error.InvalidDimensions, result);
}
```

## Common Pitfalls

### ❌ Pitfall 1: Only Testing Happy Path
**Problem**: Tests pass but bugs exist in edge cases.
**Solution**: Test boundaries, errors, and unusual inputs.

### ❌ Pitfall 2: Tests Too Brittle
**Problem**: Tests break with any refactoring.
**Solution**: Test behavior, not implementation details.

### ❌ Pitfall 3: No Memory Leak Tests
**Problem**: Code leaks memory but tests don't catch it.
**Solution**: Use test allocator, verify all allocations freed.

### ❌ Pitfall 4: Unclear Test Names
**Problem**: Test fails, unclear what's wrong.
**Solution**: Descriptive names: `test "getTile returns null for out of bounds coord"`

## Agent Self-Check

Before marking complete:

1. **Coverage**: All public functions tested? ✓/✗
2. **Passing**: All tests pass? ✓/✗
3. **Edge Cases**: Boundaries and errors tested? ✓/✗
4. **No Leaks**: Memory management verified? ✓/✗
5. **Clear**: Test names descriptive? ✓/✗

---

**Template Version**: 1.0
**Last Updated**: 2025-11-09
