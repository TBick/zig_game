# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## New Session? Start Here

**Choose your path:**

###  Quick Start (5-10 minutes)
**→ Read [CLAUDE_QUICK_START.md](CLAUDE_QUICK_START.md)**
- Essential first steps
- Current project status
- Common build commands
- What to work on next

### 📚 Detailed Reference (as needed)
**→ Read [CLAUDE_REFERENCE.md](CLAUDE_REFERENCE.md)**
- Complete build commands
- Full project structure
- Architecture details
- Agent orchestration patterns
- Troubleshooting guide

---

## Session Startup Protocol

**Every new session MUST:**

1. Read [SESSION_STATE.md](SESSION_STATE.md) (3 min) - Current status
2. Read [CONTEXT_HANDOFF_PROTOCOL.md](CONTEXT_HANDOFF_PROTOCOL.md) (5 min) - Recent work
3. Check recent commits: `git log --oneline -20`

**Then:**
- See [CLAUDE_QUICK_START.md](CLAUDE_QUICK_START.md) for immediate action items
- Reference [CLAUDE_REFERENCE.md](CLAUDE_REFERENCE.md) as needed for details

---

## Quick Reference

### Project Status
- **Phase**: Phase 1 Complete (100%), Phase 2 (Lua Integration) at 70%
- **Tests**: 149 passing (100% pass rate, 0 memory leaks)
- **Tech Stack**: Zig 0.15.1 + Lua 5.4 (raw C bindings) + Raylib 5.6.0

### Essential Commands
```bash
zig build run              # Build and run
zig build test             # Run all 149 tests
git log --oneline -20      # Check recent work
```

### Current Focus (Phase 2)
Next tasks: Script integration (Phase 2C), sandboxing, example scripts
See [CONTEXT_HANDOFF_PROTOCOL.md](CONTEXT_HANDOFF_PROTOCOL.md) Session 7 for details.

---

## Documentation Structure

```
CLAUDE.md                      # This file - navigation hub
├── CLAUDE_QUICK_START.md      # Fast session startup (read this first)
└── CLAUDE_REFERENCE.md        # Complete reference (consult as needed)

SESSION_STATE.md               # Current progress tracking
CONTEXT_HANDOFF_PROTOCOL.md    # Session-by-session log
CONTEXT_HANDOFF_ARCHIVE.md     # Archived sessions (1-2)
```

---

## Session End Protocol

**Before ending ANY session:**
1. Update [SESSION_STATE.md](SESSION_STATE.md)
2. Add handoff entry to [CONTEXT_HANDOFF_PROTOCOL.md](CONTEXT_HANDOFF_PROTOCOL.md)
3. Commit and push changes

**This is NOT optional.** See [CLAUDE_QUICK_START.md](CLAUDE_QUICK_START.md) for details.

---

**Version**: 2.1 (metrics updated)
**Last Updated**: 2025-11-24 (Session 7 - Phase 2B World API Complete)
**Previous Version**: See git history for monolithic CLAUDE.md v1.2
