# SwiftLint Warnings Fix — Plan Index

**Goal:** Eliminate all 22 SwiftLint warnings across 10 source files.

Implement the three batches in order. Each is a self-contained plan:

| Batch | Plan | Warnings fixed | Commit |
|-------|------|----------------|--------|
| 1 | [batch1-quick-fixes](2026-03-29-swiftlint-batch1-quick-fixes.md) | 13× `line_length`, 1× `for_where`, 1× `type_name` | `fix: resolve batch 1 SwiftLint warnings` |
| 2 | [batch2-struct-extractions](2026-03-29-swiftlint-batch2-struct-extractions.md) | 2× `large_tuple`, 1× `file_length` | `fix: resolve batch 2 SwiftLint warnings` |
| 3 | [batch3-structural-refactors](2026-03-29-swiftlint-batch3-structural-refactors.md) | 1× `type_body_length` + 1× `function_body_length` (UseCase), 1× `type_body_length` (Tests) | `fix: resolve batch 3 SwiftLint warnings` |

**Verification:** After all batches, clean build (Cmd+Shift+K then Cmd+B). Expected: zero warnings.
