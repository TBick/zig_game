# Agent Orchestration Framework

## Purpose

This document defines how to orchestrate AI agents (subagents, skills, and sessions) throughout the development of this game project. It establishes patterns for:

1. **When** to use agents vs. direct implementation
2. **What** types of agents to deploy
3. **How** to coordinate multiple agents
4. **How** to preserve context across sessions

---

## Agent Types and Roles

### 1. Development Agents (Implementation)

These agents write code, implement features, and build the game.

#### 1.1 Module Agents

**Purpose**: Implement a specific module/subsystem autonomously.

**When to Use**:
- Implementing a well-defined module with clear API contract
- Module can be developed in isolation (or with mocked dependencies)
- Task requires >100 lines of code or multiple files
- Module has comprehensive specification in design docs

**Examples for This Project**:
- `hex-grid-agent`: Implements `src/world/hex_grid.zig` and hex math
- `entity-manager-agent`: Implements `src/entities/entity_manager.zig`
- `lua-sandbox-agent`: Implements Lua sandboxing and CPU limiting
- `pathfinding-agent`: Implements A* pathfinding for hex grid
- `renderer-agent`: Implements rendering pipeline

**Template**: See `templates/module_agent_prompt.md`

**Success Criteria**:
- All specified functions implemented
- Unit tests written and passing
- Documentation comments on public APIs
- Integration tests pass (or mocks provided)

#### 1.2 Feature Agents

**Purpose**: Implement a cross-cutting feature spanning multiple modules.

**When to Use**:
- Feature touches 3+ modules
- Requires coordinated changes across systems
- Has end-to-end user workflow

**Examples for This Project**:
- `resource-harvesting-agent`: Implements harvest action, resource deposits, inventory management
- `construction-system-agent`: Implements build action, structure placement, resource consumption
- `energy-system-agent`: Implements energy depletion, recharging, energy-driven behavior

**Template**: See `templates/feature_agent_prompt.md`

**Success Criteria**:
- End-to-end workflow functional
- Integration tests demonstrate feature working
- All touched modules remain coherent

#### 1.3 Refactoring Agents

**Purpose**: Refactor existing code for performance, clarity, or maintainability.

**When to Use**:
- Performance profiling identifies bottleneck
- Code complexity has grown unwieldy
- Need to extract common patterns into utilities

**Examples for This Project**:
- `optimize-tick-processing-agent`: Refactor tick loop for performance
- `extract-hex-utilities-agent`: Consolidate scattered hex math into utilities
- `memory-pool-agent`: Implement custom allocators for entities

**Template**: See `templates/refactoring_agent_prompt.md`

**Success Criteria**:
- All existing tests still pass
- Measurable improvement (performance, LOC, complexity metrics)
- No functionality regression

### 2. Analysis Agents (Research and Planning)

These agents explore, analyze, and provide information without writing code.

#### 2.1 Exploration Agents

**Purpose**: Understand codebase structure, find files, answer architecture questions.

**When to Use**:
- New session needs to understand current state
- Looking for where specific functionality lives
- Understanding how systems interact
- NOT for simple file lookups (use Glob/Grep directly)

**Examples for This Project**:
- "Find all Lua API binding functions"
- "How does entity movement interact with the tick system?"
- "What's the current state of the rendering pipeline?"

**Tool**: Use `Task` tool with `subagent_type=Explore`

**Thoroughness Levels**:
- `quick`: Basic keyword search, 1-2 directories
- `medium`: Multi-directory search, follow imports (default)
- `very thorough`: Comprehensive codebase analysis

#### 2.2 Design Agents

**Purpose**: Research design decisions, propose solutions, evaluate trade-offs.

**When to Use**:
- Facing architectural decision with multiple options
- Need to research best practices or libraries
- Evaluating performance implications
- Designing API before implementation

**Examples for This Project**:
- "Research Lua C API patterns for efficient table access"
- "Design entity query API for script access"
- "Evaluate LuaJIT vs Lua 5.4 performance trade-offs"

**Template**: See `templates/design_agent_prompt.md`

**Success Criteria**:
- Clear recommendation with justification
- Trade-offs explicitly stated
- Implementation guidance provided

### 3. Quality Assurance Agents (Testing and Review)

#### 3.1 Test Generation Agents

**Purpose**: Write comprehensive test suites for modules.

**When to Use**:
- Module implemented but lacks tests
- Need edge case coverage
- Performance benchmark needed

**Examples for This Project**:
- `test-hex-math-agent`: Generate exhaustive hex coordinate tests
- `benchmark-lua-scripts-agent`: Create performance test suite for script execution
- `integration-test-agent`: Write end-to-end scenario tests

**Template**: See `templates/test_agent_prompt.md`

**Success Criteria**:
- Test coverage >80% for module
- Edge cases covered
- Performance tests establish baselines

#### 3.2 Code Review Agents

**Purpose**: Review code for bugs, performance, style, and best practices.

**When to Use**:
- After significant feature implementation
- Before merging to main branch
- After performance-critical code written

**Examples for This Project**:
- Review Lua C API bindings for memory leaks
- Review pathfinding for correctness and performance
- Review rendering code for GPU efficiency

**Template**: See `templates/review_agent_prompt.md`

**Success Criteria**:
- List of issues found (bugs, performance, style)
- Prioritization (critical, important, nice-to-have)
- Suggested fixes

### 4. Documentation Agents

**Purpose**: Generate or update documentation.

**When to Use**:
- API documentation needed for implemented modules
- Tutorial or guide needed
- README or design doc updates

**Examples for This Project**:
- Generate API reference from Lua bindings
- Write tutorial for creating first entity script
- Update ARCHITECTURE.md after implementation changes

**Template**: See `templates/documentation_agent_prompt.md`

---

## When to Create Custom Agents vs. Using General Purpose

### Use General-Purpose Agent When:
- Task is simple and well-understood
- Single file edit or small change
- Exploratory work (reading code, understanding)
- Quick iterations needed

### Create Custom Agent When:
- Task is complex (>3 files, >200 LOC)
- Requires specialized knowledge (e.g., Lua C API)
- Will be reused multiple times (template for similar tasks)
- Benefits from focused context (avoid irrelevant information)

### Creating a Custom Agent

**Process**:
1. Define clear scope and success criteria
2. Write prompt template in `templates/`
3. Document agent in this file (add to relevant section)
4. Test agent on small task first
5. Iterate on prompt based on results

**Template Structure**:
```markdown
# [Agent Name]

## Purpose
[One sentence description]

## When to Use
- [Trigger condition 1]
- [Trigger condition 2]

## Inputs Required
- [Input 1: e.g., Module name]
- [Input 2: e.g., API specification]

## Instructions
[Detailed step-by-step instructions for agent]

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Example Invocation
[Example Task tool call]
```

---

## Orchestration Patterns

### Pattern 1: Sequential Pipeline

**Use When**: Tasks have strict dependencies (A must complete before B can start).

**Example**: Build system setup
1. Agent creates `build.zig`
2. Agent creates directory structure
3. Agent writes placeholder files
4. Agent tests compilation

**Implementation**:
```
Session 1: Task(create-build-system-agent) → wait for completion
Session 2: Task(create-directory-structure-agent) → wait for completion
Session 3: Task(test-compilation-agent)
```

### Pattern 2: Parallel Fan-Out

**Use When**: Tasks are independent and can run simultaneously.

**Example**: Phase 1 module implementation
- Agent A: Implements hex grid
- Agent B: Implements entity manager
- Agent C: Implements rendering
- Agent D: Implements game loop

**Implementation** (SINGLE message with multiple Task calls):
```
Task(hex-grid-agent)
Task(entity-manager-agent)
Task(renderer-agent)
Task(game-loop-agent)
```

**Integration**: After all complete, run integration agent to connect modules.

### Pattern 3: Map-Reduce

**Use When**: Multiple similar tasks, then aggregate results.

**Example**: Implementing Lua API functions
1. **Map**: Each agent implements subset of API functions
   - Agent A: Entity query functions (5 functions)
   - Agent B: World query functions (6 functions)
   - Agent C: Action functions (7 functions)
2. **Reduce**: Integration agent combines into cohesive API module

**Implementation**:
```
Parallel: Task(entity-query-api-agent), Task(world-query-api-agent), Task(action-api-agent)
Sequential: Task(integrate-lua-api-agent)
```

### Pattern 4: Iterative Refinement

**Use When**: Need multiple passes to reach quality bar.

**Example**: Performance optimization
1. Benchmark agent measures baseline
2. Profiling agent identifies bottlenecks
3. Optimization agent refactors hot paths
4. Benchmark agent measures improvement
5. Repeat if needed

**Implementation**:
```
Loop:
  Task(benchmark-agent) → get results
  If meets target: exit
  Task(profile-agent) → identify bottleneck
  Task(optimize-agent, target=bottleneck)
```

### Pattern 5: Review-Revise Loop

**Use When**: Quality assurance needed before acceptance.

**Example**: Feature implementation
1. Implementation agent writes feature
2. Test agent writes tests → some fail
3. Implementation agent fixes failures
4. Review agent checks code → suggests improvements
5. Implementation agent applies improvements
6. Final acceptance

**Implementation**:
```
Task(implement-feature-agent)
Task(test-generation-agent)
[Run tests, check results]
Task(fix-failures-agent)
Task(code-review-agent)
Task(apply-improvements-agent)
```

---

## Context Preservation Across Sessions

### The Context Problem

Each new session has:
- Limited context window
- No memory of previous sessions
- Must rebuild understanding from artifacts

### Solution: Layered Context Architecture

#### Layer 1: Permanent Artifacts (Always Available)

These files are the "source of truth" and persist across all sessions:

**Design Documents** (in repo root):
- `GAME_DESIGN.md`: Gameplay vision
- `ARCHITECTURE.md`: Technical design
- `DEVELOPMENT_PLAN.md`: Phases and milestones
- `LUA_API_SPEC.md`: Scripting API
- `AGENT_ORCHESTRATION.md`: This file
- `CONTEXT_HANDOFF_PROTOCOL.md`: Session transition protocol

**Code** (`src/`):
- Working implementations
- Tests
- Comments and documentation

**State Tracking**:
- `SESSION_STATE.md`: Current progress, what's done, what's next
- `DECISIONS.md`: Log of all major decisions and rationale
- `ISSUES.md`: Known bugs, blockers, technical debt

#### Layer 2: Session Context (Created Each Session)

**Session Start**:
- `SESSION_[DATE]_START.md`: Goals for this session
- Current working branch
- Recent changes (git log)

**Session End**:
- `SESSION_[DATE]_END.md`: What was accomplished, what's next
- Updated `SESSION_STATE.md`
- Commit and push changes

#### Layer 3: Agent Context (Scoped to Agent Execution)

**Agent Prompt**:
- Includes relevant subset of Layer 1 docs
- Specific task definition
- Success criteria
- Context from dependencies (e.g., API contracts from other modules)

**Agent Output**:
- Implementation artifacts (code, tests)
- Execution log (what it did)
- Handoff notes (for next agent or session)

### Context Compression Techniques

#### Technique 1: Progressive Summarization

As project grows, summarize old details:

**Early Project** (now):
- Full design docs (all details relevant)

**Mid Project** (Phase 2-3):
- Design docs: Keep high-level architecture, summarize details
- `SESSION_STATE.md`: List completed modules, in-progress, blocked
- Focus on active development areas

**Late Project** (Phase 4-5):
- Design docs: Pointer to implementation ("see src/world/hex_grid.zig for details")
- State: High-level progress (Phase 4 80% complete)
- Focus on current goals only

#### Technique 2: Artifact-Based Context

Instead of re-reading all code:
- **Module Manifests**: Each module has `README.md` summarizing its API
- **Dependency Graphs**: Visual map of module interactions
- **Test Results**: Latest test run shows what works
- **Git History**: Recent commits show what changed

Example: Starting a new session
1. Read `SESSION_STATE.md` (2 pages) → know where we are
2. Read current phase goals from `DEVELOPMENT_PLAN.md` (1 page)
3. Read module manifests for relevant modules (3-5 pages)
4. Total: <10 pages of reading vs. rereading entire codebase

#### Technique 3: Question-Driven Exploration

Don't read everything upfront. Instead:
1. Start with goal: "Implement Lua API function `harvest()`"
2. Ask: What modules does this touch? → Use Explore agent
3. Read only those modules
4. Implement with focused context

---

## Session Initialization Protocol

When starting a new session, follow this protocol:

### Step 1: Context Loading (Autonomous)

The primary agent (you, Claude Code) should:

1. **Read `SESSION_STATE.md`** (REQUIRED)
   - What phase are we in?
   - What's completed?
   - What's in progress?
   - What's next?

2. **Read `CONTEXT_HANDOFF_PROTOCOL.md`** (REQUIRED)
   - What does previous session want us to know?
   - Any blockers or critical info?

3. **Scan Recent Git History** (REQUIRED)
   ```bash
   git log --oneline -20
   git status
   ```
   - What changed since last session?
   - Any uncommitted work?

4. **Conditionally Read Design Docs** (as needed)
   - If starting new phase: Read that phase's section in `DEVELOPMENT_PLAN.md`
   - If implementing module: Read relevant section in `ARCHITECTURE.md`
   - If designing feature: Read `GAME_DESIGN.md`

### Step 2: Session Goal Definition

After context loading, explicitly state:
- **Session Goal**: What will we accomplish today?
- **Success Criteria**: How do we know we're done?
- **Approach**: High-level plan (sequential, parallel agents, etc.)

### Step 3: Execution

Proceed with work, using orchestration patterns defined above.

### Step 4: Session Handoff (End of Session)

Before ending session:

1. **Update `SESSION_STATE.md`**:
   - Mark completed tasks
   - Update in-progress status
   - Note any blockers

2. **Create Handoff Entry in `CONTEXT_HANDOFF_PROTOCOL.md`**:
   - Date and session number
   - What was accomplished
   - Critical context for next session
   - Recommended next steps

3. **Commit and Push**:
   ```bash
   git add .
   git commit -m "Session [N]: [Summary]"
   git push
   ```

4. **Document Decisions**:
   - If major decision made, add to `DECISIONS.md`
   - Include date, decision, rationale, alternatives considered

---

## Agent Coordination Mechanisms

### Mechanism 1: API Contracts

**Before** parallel agents start:
- Define interfaces between modules
- Write interface definition files (e.g., `src/world/hex_grid_interface.zig` with function signatures)
- Each agent implements to contract
- Integration tests validate contracts

**Example**:
```zig
// src/world/hex_grid_interface.zig
// Contract for hex grid module (defined before implementation)

pub const HexCoord = struct {
    q: i32,
    r: i32,
};

pub const HexGrid = opaque {};

// API contract
pub fn init(allocator: Allocator, width: u32, height: u32) !*HexGrid;
pub fn getTile(grid: *HexGrid, coord: HexCoord) ?*Tile;
pub fn neighbors(coord: HexCoord) [6]HexCoord;
// ... etc
```

Agents implement this, tests validate compliance.

### Mechanism 2: Mock Implementations

When Agent A depends on Agent B's module (not yet implemented):
- Agent A creates mock of Agent B's interface
- Agent A proceeds with implementation and testing
- Later: Swap mock for real implementation
- Integration tests catch mismatches

### Mechanism 3: Integration Checkpoints

After N parallel agents complete:
- **Integration Agent** runs
- Attempts to connect all modules
- Reports conflicts, mismatches, gaps
- Assigns fix tasks to agents or creates new agent

### Mechanism 4: Shared State Document

For coordinated agents working on related tasks:
- Create `[FEATURE]_STATUS.md` tracking file
- Each agent updates status when completing work
- Agents read status to check dependencies

**Example**: `lua_api_implementation_status.md`
```markdown
# Lua API Implementation Status

## Entity Query Functions
- [x] getEnergy() - Implemented by Agent A
- [x] getPosition() - Implemented by Agent A
- [ ] getInventory() - In progress by Agent C

## World Query Functions
- [x] getTile() - Implemented by Agent B
- [ ] findNearbyResources() - Blocked on getTile() - Ready now!
```

---

## Agent Templates

Templates are stored in `templates/` directory. Each template is a markdown file with:
- Agent name and purpose
- When to use
- Inputs required
- Step-by-step instructions
- Success criteria
- Example invocation

### Template Naming Convention

`[type]_[name]_agent_template.md`

Examples:
- `module_hex_grid_agent_template.md`
- `feature_resource_harvesting_agent_template.md`
- `test_pathfinding_agent_template.md`
- `review_lua_bindings_agent_template.md`

### Template Variables

Templates use placeholders for customization:

- `{MODULE_NAME}`: Name of module (e.g., "hex_grid")
- `{FEATURE_NAME}`: Name of feature (e.g., "resource_harvesting")
- `{FILES}`: List of files to work on
- `{DEPENDENCIES}`: List of dependencies
- `{API_CONTRACT}`: Interface definition
- `{TEST_CRITERIA}`: Specific test requirements

When invoking agent, substitute variables with actual values.

---

## Anti-Patterns (What NOT to Do)

### ❌ Anti-Pattern 1: Agent Overuse
**Problem**: Creating agents for trivial tasks.
**Example**: Task agent to add a single comment to a file.
**Solution**: Direct implementation for simple tasks (<50 LOC, 1 file).

### ❌ Anti-Pattern 2: Insufficient Context
**Problem**: Agent lacks information to succeed.
**Example**: "Implement pathfinding" with no spec, no grid interface, no target.
**Solution**: Provide API contract, dependencies, success criteria.

### ❌ Anti-Pattern 3: Circular Dependencies
**Problem**: Agent A waits for Agent B; Agent B waits for Agent A.
**Example**: Renderer needs entity positions; entity system needs render layer.
**Solution**: Define interfaces first, use mocks, or sequence properly.

### ❌ Anti-Pattern 4: No Integration Plan
**Problem**: Multiple agents complete, but no plan to combine their work.
**Example**: 5 agents implement different Lua API functions; no one integrates them.
**Solution**: Always define integration step in orchestration plan.

### ❌ Anti-Pattern 5: Lost Context
**Problem**: Session ends, no handoff, next session doesn't know what happened.
**Example**: Implementation 80% done, but `SESSION_STATE.md` not updated.
**Solution**: ALWAYS update state tracking before ending session.

### ❌ Anti-Pattern 6: Ignoring Failures
**Problem**: Agent completes but tests fail; move on anyway.
**Example**: Agent implements feature, 3 tests fail, agent marks task complete.
**Solution**: Success criteria MUST include passing tests. Fix failures or escalate.

---

## Metrics and Monitoring

### Agent Performance Metrics

Track these to improve orchestration:

**Completion Rate**:
- Did agent complete task successfully?
- Did it meet success criteria?

**Iteration Count**:
- How many times did we need to re-run agent?
- High iterations → poor initial prompt or unclear requirements

**Integration Failures**:
- Did agent's output integrate cleanly?
- High failures → poor API contracts or communication

**Context Efficiency**:
- How much context did agent need?
- Can we compress further?

### Session Metrics

**Velocity**:
- How many tasks completed per session?
- Trend over time (should increase as infrastructure solidifies)

**Rework Rate**:
- How often do we revisit "completed" tasks?
- High rework → inadequate testing or unclear requirements

**Context Load Time**:
- How long to get up to speed in new session?
- Should decrease with better handoff protocols

---

## Escalation and Intervention

### When to Escalate (Agent → Human)

Agents should escalate to human (you, the user) when:
1. **Ambiguous Requirements**: Multiple valid interpretations
2. **Design Decision**: Trade-off requires human judgment
3. **Blocked**: Dependency not available, can't proceed
4. **Failure**: Repeated attempts don't solve problem
5. **Scope Change**: Discovered work is larger than expected

### When to Intervene (Human → Agent)

Human should intervene when:
1. **Agent Stuck**: Making no progress after N iterations
2. **Wrong Direction**: Agent misunderstood requirements
3. **Context Bloat**: Agent asking for too much information (simplify prompt)
4. **Integration Issues**: Multiple agents' outputs don't fit together

---

## Evolution of This Framework

This orchestration framework is a living document. As we learn from experience:

**What to Track**:
- Which patterns worked well?
- Which agents were most/least effective?
- What context was critical vs. noise?

**When to Update**:
- After completing each phase
- When discovering new pattern
- When anti-pattern identified

**How to Update**:
- Add new patterns to "Orchestration Patterns"
- Create new agent templates in `templates/`
- Refine context handoff protocol
- Update anti-patterns section

---

## Summary: Quick Reference

### Starting a New Session?
1. Read `SESSION_STATE.md`
2. Read `CONTEXT_HANDOFF_PROTOCOL.md`
3. Check git log
4. Define session goal
5. Proceed with work

### Need to Use an Agent?
1. Is task simple? → Direct implementation
2. Is task complex? → Check existing templates
3. No template? → Create custom agent
4. Multiple agents? → Choose orchestration pattern
5. Define success criteria
6. Launch agent(s)

### Ending a Session?
1. Update `SESSION_STATE.md`
2. Add handoff to `CONTEXT_HANDOFF_PROTOCOL.md`
3. Commit and push
4. Document any decisions in `DECISIONS.md`

### Stuck or Uncertain?
1. Escalate to human with clear question
2. Provide context and options
3. Document decision once made

---

**Next Step**: Create the supporting documents and templates referenced in this framework.
