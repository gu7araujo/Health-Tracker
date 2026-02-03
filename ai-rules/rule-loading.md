# Rule Loading Guide
This file helps determine which rules to load based on the context and task at hand. Each rule file contains specific guidance for different aspects of Swift development.

## Rule Loading Triggers
Rules are under `ai-rules` folder.

### 📝 general.md - Core Engineering Principles
**Load when:**
- Always
- Starting any new Swift project or feature
- Making architectural decisions
- Discussing code quality, performance, or best practices
- Planning implementation strategy
- Reviewing code for improvements

**Keywords:** architecture, design, performance, quality, best practices, error handling, planning, strategy

### 🔧 mcp-tools-usage.md - MCP Tools Integration
**Load when:**
- Always
- Using Context7 for library documentation
- Optimizing searches usage and performance with Serena
- Working with external MCP tools

**Keywords:** MCP, Context7, Serena, tool, integration, library docs, feedback

### 📚 rules.md - Rule & Documentation Management
**Load when:**
- Creating new rule files
- Updating existing rules after user corrections
- Maintaining `project.md` after codebase changes
- Documenting new patterns or conventions
- Responding to repeated explanations (capture in rules)
- After refactoring or architecture changes

**Keywords:** rule file, documentation, project.md, update docs, new pattern, convention, maintenance, meta-rules

## Quick Reference
```swift
// When reviewing code:
// Load: general.md, mcp-tools-usage.md

// When creating documentation:
// Load: general.md, rules.md
```

## Rule Combinations

### Feature Development
1. Start with `general.md` for architecture decisions
2. Load `mcp-tools-usage.md` for available mcp tools, ignore TaskMaster rules and use internal tasks system

### Code Review & Maintenance
1. Apply `general.md` for quality standards
2. Reference specific domain rules as needed

### Complex Problem Solving
1. Load `mcp-tools-usage.md` 
2. Apply `general.md` for chain-of-thought reasoning
3. Follow domain-specific rules for implementation

## Loading Strategy
1. **Always load `general.md` and `mcp-tools-usage.md first`** - It provides the foundation
2. **Load domain-specific rules** based on the task
3. **Load supporting rules** as needed
4. **Keep loaded rules minimal** - Only what's directly relevant
5. **Refresh rules** when switching contexts or tasks
