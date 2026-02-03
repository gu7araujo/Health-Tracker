# MCP Tools Integration Framework

<primary_directive>
Leverage MCP (Model Context Protocol) servers for ACCURATE, UP-TO-DATE information.
ALWAYS prefer MCP tools over assumptions. NEVER hallucinate APIs or project structure.
</primary_directive>

<cognitive_anchors>
TRIGGERS: Documentation lookup, API reference, library usage, symbol search, code navigation, dependency tracing, refactoring, understanding codebase
SIGNAL: When triggered → Use appropriate MCP tool BEFORE writing code
</cognitive_anchors>

## CORE RULES [CRITICAL - ALWAYS APPLY]

<rule_1 priority="HIGHEST">
**EXTERNAL KNOWLEDGE → Context7**: Fetch latest library documentation before using any external API
- MUST resolve library ID first with `resolve-library-id`
- MUST retrieve docs with `get-library-docs` before generating code
- NEVER assume API signatures — always verify
</rule_1>

<rule_2 priority="HIGHEST">
**INTERNAL KNOWLEDGE → Serena**: Use symbolic tools for codebase navigation
- MUST use `get_symbols_overview` before reading entire files
- MUST use `find_symbol` to locate exact definitions
- NEVER read full files when symbol extraction suffices
</rule_2>

<rule_3 priority="HIGH">
**TOKEN EFFICIENCY**: Minimize context window usage
- Use Serena's symbolic extraction over full-file reads
- Request only necessary documentation sections from Context7
- Prefer targeted symbol lookups over broad searches
</rule_3>

## MCP SERVER REFERENCE

<server name="context7" purpose="External Documentation">
**When to Use**: Fetching latest library docs, API references, framework documentation

<tool name="resolve-library-id">
**Purpose**: Find the correct library identifier before fetching docs
**Use When**: You need documentation for a Swift package or Apple framework
**Example Flow**:
```
1. resolve-library-id("SwiftUI") → returns library ID
2. get-library-docs(libraryId) → returns current documentation
```
</tool>

<tool name="get-library-docs">
**Purpose**: Retrieve comprehensive documentation for a resolved library
**Use When**: You need API signatures, code examples, or best practices
**Capabilities**:
- Apple frameworks (SwiftUI, UIKit, Core ML, Foundation, etc.)
- Swift packages and third-party libraries
- Up-to-date API references with code examples
</tool>

<workflow name="documentation_lookup">
```
User asks about library → resolve-library-id → get-library-docs → Apply to task
```
</workflow>
</server>

<server name="serena" purpose="Internal Codebase Navigation">
**When to Use**: Understanding project structure, finding symbols, tracing dependencies

<tool name="get_symbols_overview">
**Purpose**: Get high-level view of symbols in a file without reading full content
**Use When**: Exploring unfamiliar files, understanding file structure
**Benefits**: Saves tokens by showing only symbol signatures
</tool>

<tool name="find_symbol">
**Purpose**: Locate exact function/class/variable definitions with optional body
**Use When**: You know the symbol name (or partial name) and need its location
**Parameters**:
- `name_path`: Symbol path pattern (e.g., `Foo/__init__`, `MainViewModel/loadData`)
- `include_body`: Set `true` only when you need implementation details
- `depth`: Use `1` to get immediate children without full traversal
**Example**:
```
find_symbol(name_path="MainViewModel", include_body=false, depth=1)
→ Returns all methods of MainViewModel without reading entire file
```
</tool>

<tool name="find_referencing_symbols">
**Purpose**: Trace call hierarchies and understand component interactions
**Use When**: Refactoring, understanding impact of changes, finding usages
**Benefits**: Shows code snippets around references with symbolic context
</tool>

<tool name="replace_symbol_body">
**Purpose**: Replace entire symbol definition with precision
**Use When**: Modifying complete methods, classes, or functions
**NOT For**: Small line-by-line edits within a symbol
</tool>

<tool name="insert_before_symbol" / name="insert_after_symbol">
**Purpose**: Add new code adjacent to existing symbols
**Use When**: Adding new methods to a class, new functions to a file
</tool>

<tool name="search_for_pattern">
**Purpose**: Fast regex-based search across codebase
**Use When**: Symbol name is unknown, finding candidates before symbolic tools
**Fallback**: Use when `find_symbol` substring matching isn't sufficient
</tool>

<workflow name="code_exploration">
```
1. get_symbols_overview(file) → Understand structure
2. find_symbol(name, include_body=false) → Locate target
3. find_symbol(name, include_body=true) → Read implementation (only if needed)
4. find_referencing_symbols(name) → Understand dependencies
```
</workflow>

<workflow name="safe_refactoring">
```
1. find_symbol(target) → Confirm location
2. find_referencing_symbols(target) → Map all usages
3. Edit symbol + Update all references → Maintain consistency
```
</workflow>
</server>

## DECISION MATRIX

<decision_matrix>
| Scenario | Tool | Rationale |
|----------|------|-----------|
| Need SwiftUI API signature | Context7 | External, up-to-date docs |
| Find where `DayData` is defined | Serena `find_symbol` | Internal symbol lookup |
| Understand file structure | Serena `get_symbols_overview` | Token-efficient exploration |
| Check who calls `loadData()` | Serena `find_referencing_symbols` | Dependency tracing |
| Unknown symbol name | Serena `search_for_pattern` | Flexible pattern search |
| Modify entire method | Serena `replace_symbol_body` | Precise symbolic edit |
| Add new method to class | Serena `insert_after_symbol` | Structured insertion |
</decision_matrix>

## QUALITY GATES

<checklist>
☐ EXTERNAL APIs verified via Context7 before use
☐ INTERNAL symbols located via Serena before editing
☐ FULL FILE reads avoided when symbol extraction suffices
☐ REFACTORING preceded by `find_referencing_symbols` impact analysis
☐ DOCUMENTATION fetched for unfamiliar frameworks/libraries
</checklist>

## ANTI-PATTERNS TO AVOID

<avoid>
❌ Assuming API signatures without verification
❌ Reading entire files when only one symbol is needed
❌ Guessing project structure instead of using symbolic tools
❌ Editing code without checking references (breaking changes)
❌ Hallucinating function names or parameters
❌ Using grep/find when Serena provides symbolic alternatives
</avoid>
