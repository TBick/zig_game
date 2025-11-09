# Context Handoff Protocol

## Purpose

This document serves as the **primary communication channel** between sessions. Each session appends a handoff entry, creating a chronological log of progress, decisions, and context.

**CRITICAL**: Any new session MUST read this file immediately after `SESSION_STATE.md` to understand recent context.

---

## How to Use This Document

### At Session Start
1. **Read the most recent entry** (at bottom)
2. **Scan backward** for unresolved items or blockers
3. **Understand trajectory** of recent work

### At Session End
1. **Append new entry** using template below
2. **Be explicit** about what future sessions need to know
3. **Commit immediately** so it's available to next session

---

## Handoff Entry Template

```markdown
---

## Session [N]: [YYYY-MM-DD] - [Brief Title]

### Session Goal
[What did this session set out to accomplish?]

### What Was Accomplished
- [Accomplishment 1]
- [Accomplishment 2]
- [Accomplishment 3]

### What's In Progress (Not Complete)
- [In-progress item 1] - [Status/blocker]
- [In-progress item 2] - [Status/blocker]

### Critical Context for Next Session
[Anything the next session MUST know that isn't obvious from code/docs]
- [Context item 1]
- [Context item 2]

### Decisions Made
- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

### Blockers / Issues
- [Blocker 1] - [Why blocked, what's needed]
- [Issue 1] - [Description]

### Recommended Next Steps
1. [Next step 1]
2. [Next step 2]
3. [Next step 3]

### Files Modified
- [file1.zig]
- [file2.md]

### Agents Used (if any)
- [Agent type]: [Purpose] - [Outcome]

### Notes
[Any other context, lessons learned, gotchas discovered]

---
```

---

## Handoff History

---

## Session 1: 2025-11-09 - Project Initialization and Planning

### Session Goal
1. Initialize Git repository and connect to GitHub
2. Create comprehensive planning documentation before any code
3. Define agent orchestration and context management framework

### What Was Accomplished
- ✅ Git repository initialized at `/home/tbick/Projects/claude/zig_game`
- ✅ GitHub remote created: https://github.com/TBick/zig_game
- ✅ Comprehensive planning documents created:
  - `GAME_DESIGN.md` (156 lines) - Gameplay vision, mechanics, entity systems
  - `ARCHITECTURE.md` (445 lines) - Technical design, module structure, systems
  - `DEVELOPMENT_PLAN.md` (652 lines) - 6-phase roadmap, testing strategy, metrics
  - `LUA_API_SPEC.md` (515 lines) - Complete Lua scripting API specification
  - `README.md` (128 lines) - Project overview
  - `.gitignore` - Zig project excludes
- ✅ Agent orchestration framework created:
  - `AGENT_ORCHESTRATION.md` (800+ lines) - Agent types, orchestration patterns, context preservation
  - `CONTEXT_HANDOFF_PROTOCOL.md` (this file) - Session transition protocol
- ✅ Initial commit pushed to GitHub

### What's In Progress (Not Complete)
- [ ] `SESSION_STATE.md` - Need to create initial state tracking document
- [ ] `templates/` directory - Need to create agent prompt templates
- [ ] `CLAUDE.md` - Need to create guidance for future Claude Code instances
- [ ] Phase 0 tasks - Project setup not yet started

### Critical Context for Next Session

**Game Vision**:
- Lua-scripted automation game inspired by Screeps
- Hex-based world, tick-based simulation (2-3 ticks/sec), 60 FPS rendering
- Players write Lua scripts to control entities (workers, combat, scouts)
- Meta-game is iterative script optimization
- Single-player first, multiplayer potential later

**Key Technical Decisions**:
1. **Zig** for engine (performance, safety, cross-platform)
2. **Lua 5.4** for player scripts (embeddable, sandboxed)
3. **Raylib** recommended for rendering (prototype speed)
4. **Tick-based simulation** with rendering interpolation (deterministic)
5. **Data-oriented design** with ECS-inspired entity system

**Development Approach**:
- 6 phases (Phase 0 → Phase 5)
- Timeline: 10-15 weeks to playable prototype
- Parallel agent development for independent modules
- Comprehensive testing: unit, integration, performance, user

**Agent Orchestration Philosophy**:
- Use agents for complex tasks (>100 LOC, >3 files)
- Direct implementation for simple tasks
- Define API contracts before parallel agents
- Always update `SESSION_STATE.md` and this handoff file
- Context preservation is critical (small context window)

**Repository Structure** (as of now):
```
zig_game/
├── .gitignore
├── README.md
├── GAME_DESIGN.md
├── ARCHITECTURE.md
├── DEVELOPMENT_PLAN.md
├── LUA_API_SPEC.md
├── AGENT_ORCHESTRATION.md
├── CONTEXT_HANDOFF_PROTOCOL.md (this file)
└── [to be created: SESSION_STATE.md, templates/, CLAUDE.md, src/, etc.]
```

### Decisions Made

**Decision 1: Extensive Planning Before Code**
- **Rationale**: Complex project with potential for many subagents. Need shared context and clear vision before implementation. Prevents rework and misalignment.
- **Trade-off**: Upfront time investment, but saves time later

**Decision 2: Explicit Agent Orchestration Framework**
- **Rationale**: Context window limitations and session boundaries require systematic approach to context preservation. Without this, each session loses critical knowledge.
- **Trade-off**: Meta-work overhead, but essential for multi-session project

**Decision 3: Hex Grid Over Square Grid**
- **Rationale**: Differentiation from Screeps, movement symmetry, organic feel
- **Trade-off**: Slightly more complex math, but well-understood problem

**Decision 4: Single-Player First**
- **Rationale**: Scope management, faster iteration, lower barrier to entry
- **Trade-off**: No multiplayer novelty initially, but architecture preserves option

**Decision 5: Tick-Based Simulation**
- **Rationale**: Determinism (save/load, debugging), fairness (all entities equal CPU), performance budgeting (Lua expensive)
- **Trade-off**: Not real-time, but interpolation provides smoothness

### Blockers / Issues
- **None currently** - Still in planning phase

### Recommended Next Steps

**Immediate (Next Session)**:
1. **Create `SESSION_STATE.md`** - Initialize progress tracking
2. **Create `templates/` directory** - Add initial agent templates (start with 3-4 key ones)
3. **Create `CLAUDE.md`** - Guidance for future Claude Code instances in this repo
4. **Commit meta-framework** - Push orchestration documents to GitHub

**After Meta-Framework Complete**:
5. **Begin Phase 0** - Project setup and infrastructure
   - Create `build.zig`
   - Set up directory structure (`src/`, `tests/`, `scripts/`, `assets/`)
   - Choose and integrate Zig dependencies (Lua bindings, Raylib)
   - Configure testing framework
   - Set up CI/CD (GitHub Actions)

**Phase 0 Specific Tasks** (from DEVELOPMENT_PLAN.md):
- [ ] Create `build.zig` with compilation targets
- [ ] Configure debug and release builds
- [ ] Set up project directory structure
- [ ] Integrate Lua library (ziglua or custom bindings)
- [ ] Integrate Raylib (raylib-zig)
- [ ] Configure Zig test framework
- [ ] Create test utilities module
- [ ] Set up CI pipeline (GitHub Actions)
- [ ] Verify `zig build`, `zig build test`, `zig build run` all work

### Files Modified
- `.gitignore` (created)
- `README.md` (created)
- `GAME_DESIGN.md` (created)
- `ARCHITECTURE.md` (created)
- `DEVELOPMENT_PLAN.md` (created)
- `LUA_API_SPEC.md` (created)
- `AGENT_ORCHESTRATION.md` (created)
- `CONTEXT_HANDOFF_PROTOCOL.md` (created - this file)

### Agents Used
- No agents deployed yet (all direct implementation by primary Claude Code instance)
- Agent framework defined for future use

### Notes

**User Guidance**:
The user emphasized the importance of:
1. Defining meta-level orchestration BEFORE starting implementation
2. Ensuring autonomous context preservation across sessions
3. Creating explicit templates and protocols

This was wise - the context window limitation is real, and without systematic handoff, we'd lose critical information between sessions.

**Documentation Quality**:
The planning documents are comprehensive and detailed:
- Game design covers vision, mechanics, and philosophy
- Architecture provides technical blueprint with concrete examples
- Development plan has measurable success criteria for each phase
- Lua API spec includes complete examples and usage patterns
- Agent orchestration defines when/how to use agents

These docs should provide sufficient context for future sessions and subagents.

**Git Workflow Note**:
- Initially used SSH remote, but authentication failed
- Switched to HTTPS remote: `https://github.com/TBick/zig_game.git`
- Successfully pushed initial commit

**Complexity Assessment**:
This is an ambitious project (10-15 week timeline), but the phased approach and clear architecture make it tractable. The agent orchestration framework should enable effective parallel development.

**Risk Areas to Monitor**:
1. Lua C API integration (Phase 2) - Most complex/risky component
2. Performance of Lua scripts at scale (benchmark early and often)
3. Gameplay fun factor (need early playtesting, not just technical validation)

---

## Archive of Older Sessions

(Future sessions will be archived here after 10-15 entries to keep recent history readable)

---

## Quick Reference for Common Scenarios

### "What should I work on next?"
→ Read most recent session's "Recommended Next Steps"
→ Check `SESSION_STATE.md` for current phase and in-progress tasks

### "Why was this decision made?"
→ Search this file for "Decisions Made" sections
→ Check `DECISIONS.md` (if it exists)
→ Search design docs for rationale

### "What files were recently modified?"
→ Check most recent session's "Files Modified"
→ Run `git log --oneline -20` and `git status`

### "Is there a template for X?"
→ Check `templates/` directory
→ See `AGENT_ORCHESTRATION.md` for template naming conventions

### "I'm stuck, what do I do?"
→ Check "Blockers / Issues" in recent sessions
→ Review relevant design docs
→ Escalate to user with specific question

---

## Session Handoff Checklist

Before ending a session, verify:
- [ ] Handoff entry added to this file
- [ ] `SESSION_STATE.md` updated with progress
- [ ] All code changes committed
- [ ] Commit message describes changes clearly
- [ ] Changes pushed to GitHub
- [ ] Any new decisions documented
- [ ] Next steps clearly stated

---

**End of Context Handoff Protocol**
