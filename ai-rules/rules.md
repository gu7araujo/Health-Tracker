# Rule & Documentation Management Framework

<primary_directive>
Keep AI guidance ACCURATE and EVOLVING with the codebase.
PROACTIVELY update rules and documentation when patterns emerge or change.
NEVER let documentation drift from reality.
</primary_directive>

<cognitive_anchors>
TRIGGERS: New pattern established, repeated guidance given, architecture change, new file/folder added, convention decided, mistake repeated, user correction, refactoring completed
SIGNAL: When triggered → Evaluate if rules or docs need update
</cognitive_anchors>

## CORE RULES [CRITICAL - ALWAYS APPLY]

<rule_1 priority="HIGHEST">
**DOCUMENT WHAT YOU TEACH**: If you explain something 2+ times, it belongs in a rule file
- Repeated explanations indicate missing documentation
- Capture the pattern before it's forgotten
- Future agents should not rediscover the same solution
</rule_1>

<rule_2 priority="HIGHEST">
**KEEP PROJECT.MD CURRENT**: Update when codebase structure changes
- New folders/files added → Update folder structure
- New domain concepts → Update key concepts section
- Architecture changes → Update architecture diagram
- New patterns adopted → Document in relevant section
</rule_2>

<rule_3 priority="HIGH">
**RULES REFLECT REALITY**: Update rules when conventions change
- User corrects your approach → Update relevant rule
- New best practice adopted → Add to appropriate file
- Pattern deprecated → Remove or mark as deprecated
- Edge case discovered → Document handling
</rule_3>

<rule_4 priority="HIGH">
**MINIMAL, FOCUSED RULES**: Each file has single responsibility
- One domain per rule file (views, testing, commits, etc.)
- Cross-cutting concerns go in `general.md`
- Tool-specific guidance goes in `mcp-tools-usage.md`
- Project-specific context goes in `project.md`
</rule_4>

---

## WHEN TO CREATE NEW RULES

<trigger name="new_rule_file">
Create a NEW rule file when:
- A new domain emerges that doesn't fit existing files (e.g., networking, persistence, accessibility)
- Guidance exceeds 50+ lines and deserves dedicated focus
- Multiple related patterns form a cohesive topic
- User explicitly requests conventions for a new area
</trigger>

<trigger name="update_existing_rule">
UPDATE an existing rule file when:
- New pattern discovered within that domain
- User corrects agent behavior in that area
- Best practice evolves or improves
- Anti-pattern identified that should be avoided
- Code example becomes outdated
</trigger>

<trigger name="update_project_md">
UPDATE `project.md` when:
- New source files or folders created
- Entity/model added or renamed
- Architecture layer modified
- Data flow changes
- New UI section added
- Domain concept introduced
- Key file purpose changes
</trigger>

---

## RULE FILE STRUCTURE

<template name="rule_file_structure">
```markdown
# [Domain] Framework

<primary_directive>
[One-line mission statement for this rule set]
[Key constraint or principle]
</primary_directive>

<cognitive_anchors>
TRIGGERS: [Comma-separated keywords that activate these rules]
SIGNAL: When triggered → [Action to take]
</cognitive_anchors>

## CORE RULES [CRITICAL - ALWAYS APPLY]

<rule_1 priority="HIGHEST">
**[RULE NAME]**: [Brief description]
- [Specific guidance point]
- [Specific guidance point]
- [Constraint or warning]
</rule_1>

## PATTERNS

<pattern name="[pattern_name]">
```swift
// Code example demonstrating the pattern
```
</pattern>

## QUALITY GATES

<checklist>
☐ [Verification item]
☐ [Verification item]
</checklist>

## ANTI-PATTERNS TO AVOID

<avoid>
❌ [Thing to avoid with brief reason]
❌ [Thing to avoid with brief reason]
</avoid>
```
</template>

---

## PROJECT.MD UPDATE PATTERNS

<pattern name="add_new_folder">
When a new folder is created, add it to the folder structure:
```markdown
├── NewFolder/                     # Brief description of purpose
│   ├── SubFile.swift              # What this file does
│   └── AnotherFile.swift          # What this file does
```
</pattern>

<pattern name="add_new_entity">
When a new domain entity is created, add to Key Domain Concepts:
```markdown
### NewEntity
Brief description of what it represents and its role in the system.
- `property1: Type` — what it holds
- `property2: Type` — what it holds
- Key behavior or computed property explanation
```
</pattern>

<pattern name="update_data_flow">
When data flow changes, update the Data Flow diagram:
```markdown
## Data Flow

```
User Action → View → ViewModel → UseCase → Repository → DataSource
                ↑                                           │
                └───────────────────────────────────────────┘
```
```
</pattern>

<pattern name="add_key_file">
When a significant file is added, update Key Files Quick Reference:
```markdown
| `NewFile.swift` | Purpose description |
```
</pattern>

---

## RULE UPDATE WORKFLOW

<workflow name="capture_new_pattern">
```
1. IDENTIFY: Pattern explained or corrected 2+ times
2. LOCATE: Find appropriate rule file (or create new one)
3. DRAFT: Write rule following template structure
4. INTEGRATE: Place in correct section (rules, patterns, anti-patterns)
5. VERIFY: Ensure no contradiction with existing rules
```
</workflow>

<workflow name="update_after_refactor">
```
1. LIST: All files/folders changed
2. CHECK: Does project.md reflect new structure?
3. UPDATE: Folder structure, key files, domain concepts as needed
4. REVIEW: Are any rule examples now outdated?
5. FIX: Update code examples to match new patterns
```
</workflow>

<workflow name="respond_to_correction">
```
1. ACKNOWLEDGE: User correction received
2. IDENTIFY: Which rule file governs this area
3. UPDATE: Add correct approach as rule or pattern
4. OPTIONALLY: Add incorrect approach to anti-patterns
5. CONFIRM: Show user the documentation update
```
</workflow>

---

## DOCUMENTATION MAINTENANCE CHECKLIST

<checklist name="after_feature_implementation">
☐ New files added to `project.md` folder structure?
☐ New entities documented in Key Domain Concepts?
☐ Data flow still accurate?
☐ Key Files table updated if significant file added?
☐ Any new patterns worth capturing in rule files?
</checklist>

<checklist name="after_architecture_change">
☐ Architecture diagram updated?
☐ Layer descriptions still accurate?
☐ Dependency flow documented?
☐ Affected rule files updated with new patterns?
☐ Old patterns marked deprecated if replaced?
</checklist>

<checklist name="after_user_feedback">
☐ Feedback captured in appropriate rule file?
☐ Anti-pattern added if mistake was made?
☐ Code examples updated to show correct approach?
☐ Quality gates updated if new check needed?
</checklist>

---

## QUALITY GATES

<checklist>
☐ RULES use consistent XML-tag structure
☐ PATTERNS include working code examples
☐ PROJECT.MD reflects actual folder structure
☐ NO contradictions between rule files
☐ ANTI-PATTERNS explain WHY to avoid
☐ TRIGGERS clearly define when rules apply
☐ CHECKLISTS are actionable and verifiable
</checklist>

## ANTI-PATTERNS TO AVOID

<avoid>
❌ Stale documentation (project.md doesn't match codebase)
❌ Duplicate guidance across multiple files
❌ Rules without code examples
❌ Vague anti-patterns without explanation
❌ Overly long rule files (split into focused domains)
❌ Rules that contradict each other
❌ Undocumented conventions (tribal knowledge)
❌ Ignoring user corrections (capture in rules)
❌ Documentation updates without verification
</avoid>

---

## FILE RESPONSIBILITIES

<reference name="file_purposes">
| File | Governs | Update When |
|------|---------|-------------|
| `project.md` | Codebase structure, architecture, domain concepts | Files/folders change, new entities added |
| `general.md` | Core Swift principles, patterns, quality standards | New engineering pattern adopted |
| `mcp-tools-usage.md` | External tool integration (Context7, Serena) | New tool added, workflow improved |
| `rule-loading.md` | Which rules to load and when | New rule file created, triggers change |
| `rules.md` | Meta-rules for documentation itself | Documentation process changes |
</reference>
