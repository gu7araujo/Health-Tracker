# Agent Guide

## Guide Purpose
Agents act as senior Swift collaborators. Keep responses concise, clarify uncertainty before coding, and align suggestions with the rules linked below.

## Rule Index
- @ai-rules/rule-loading.md — always load this file to understand which other files you need to load

## Project Idea
HealthTracker is a modern Swift 6 and iOS 26.0 user-focused, distraction-free app designed to help monitor healthy habits through a few pre-defined points.

## Repository Overview
- Deep product and architecture context: @ai-docs/project.md

## Build & Run
- iOS 26.0 target
- Swift 6 language version

## Commands
- `swiftformat .`: Apply formatting (run after finishing edit)
- `swiftlint .`: Lint Swift sources (run after finishing edit)

## Agent Skills - Available Skills

<skills_system priority="1">

<!-- SKILLS_TABLE_START -->
<usage>
When users ask you to perform tasks, check if any of the available skills below can help complete the task more effectively. Skills provide specialized capabilities and domain knowledge.

How to use skills:
- Invoke: Bash("openskills read <skill-name>")
- The skill content will load with detailed instructions on how to complete the task
- Base directory provided in output for resolving bundled resources (references/, scripts/, assets/)

Usage notes:
- Only use skills listed in <available_skills> below
- Do not invoke a skill that is already loaded in your context
- Each skill invocation is stateless
</usage>

<available_skills>

<skill>
<name>swift-concurrency</name>
<description>'Expert guidance on Swift Concurrency best practices, patterns, and implementation. Use when developers mention: (1) Swift Concurrency, async/await, actors, or tasks, (2) "use Swift Concurrency" or "modern concurrency patterns", (3) migrating to Swift 6, (4) data races or thread safety issues, (5) refactoring closures to async/await, (6) @MainActor, Sendable, or actor isolation, (7) concurrent code architecture or performance optimization, (8) concurrency-related linter warnings (SwiftLint or similar; e.g. async_without_await, Sendable/actor isolation/MainActor lint).'</description>
<location>project</location>
</skill>

</available_skills>
<!-- SKILLS_TABLE_END -->

</skills_system>

## Workflow
- Ask for clarification when requirements are ambiguous; surface 2–3 options when trade-offs matter
- When unsure or need to make a significant decision ASK the user for guidance
- For external knowledge consult the `context7` tool for most up-to-date software package documentation
- For internal knowledge consult the `serena` tool before editing code to verify existing function signatures, find references, or map project dependencies
- Prefer serena's symbol-based reading over full-file reading for large files to maintain a lean context window and efficiency
- Use the agent skills to perform activities