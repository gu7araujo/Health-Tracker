# Agent Guide

## Guide Purpose

Agents act as senior Swift collaborators. Keep responses concise, clarify uncertainty before coding, and align suggestions with the rules linked below.

## Project Idea

HealthTracker is a modern Swift 6 and iOS 26.0 user-focused, distraction-free app designed to help monitor healthy habits through a few pre-defined points.

## High-Level System Organization

Designed with a modular architecture that promotes separation of concerns, maintainability, testability and extensibility.

### Clean Architecture

Apply Clean Architecture via folders. The golden rule is the **Dependency Rule**: The Domain knows nobody.

```
📂 Root Folder
├── 📂 Domain (The "Heart" - Pure Swift)
│   ├── 📂 Entities (Business Models, e.g., UserCredentials)
│   ├── 📂 UseCases (Business Rules, e.g., AuthenticateUserUseCase)
│   └── 📂 Protocols/Repositories (Contracts, e.g., AuthRepositoryProtocol)
│
├── 📂 Data (The "How" Layer)
│   ├── 📂 DTOs (API Models - Data Transfer Objects)
│   ├── 📂 DataSources (Remote/Local)
│   └── 📂 Repositories (Protocol Implementations)
│
└── 📂 Presentation (The "View" Layer)
    ├── 📂 UI (Views/ViewControllers)
    └── 📂 ViewModels/Presenters
```

#### Data Communication Between Layers

Communication follows the **Dependency Inversion** principle. Here is the step-by-step flow:

<layer name="domain" description="Defines WHAT needs to be done, not HOW">
```swift
// Domain/Entities/Email.swift
public struct Email {
    let rawValue: String
    
    public init?(_ rawValue: String) {
        guard rawValue.matches("#email regex#") else {
            return nil
        }
        self.rawValue = rawValue
    }
}

// Domain/Entities/Password.swift
public struct Password {
    let rawValue: String
    
    public init?(_ rawValue: String) {
        guard rawValue.count > 7 else {
            return nil
        }
        self.rawValue = rawValue
    }
}

// Domain/Protocols/AuthRepositoryProtocol.swift
public protocol AuthRepositoryProtocol {
    func login(email: Email, password: Password) async throws -> User
}

// Domain/UseCases/LoginUseCase.swift
public final class LoginUseCase {
    private let repository: AuthRepositoryProtocol  // Depends on abstraction, NOT implementation
    
    public init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(email: Email, password: Password) async throws -> User {
        try await repository.login(email: email, password: password)
    }
}
```
</layer>

<layer name="data" description="Implements the Domain contracts">
```swift
// Data knows Domain
// Data/Repositories/AuthRepository.swift
final class AuthRepository: AuthRepositoryProtocol {
    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    // ✅ Receives domain types, converts to strings/JSON at boundary
    func login(email: Email, password: Password) async throws -> User {
        // 1. Convert domain types → strings/JSON for network
        let request = LoginRequest(
            email: email.rawValue,  // Domain type → string at boundary
            password: password.rawValue
        )
        
        // 2. Call API (network works with strings/JSON)
        let dto = try await networkService.post("/auth/login", body: request)
        
        // 3. Convert DTO → Domain Entity (via Mapper)
        return dto.toDomain()
    }
}
```
</layer>

<layer name="presentation" description="UI communicates with ViewModel, which uses UseCases">
```swift
// Presentation/ViewModels/LoginViewModel.swift
@Observable
final class LoginViewModel {
    private let loginUseCase: LoginUseCase

    private(set) var isLoading = false
    private(set) var error: Error?

    init(loginUseCase: LoginUseCase) {
        self.loginUseCase = loginUseCase
    }

    // ✅ UI works with strings, parses to domain types at boundary
    func onLoginButtonTapped(emailString: String, passwordString: String) async {
        // Parse strings → domain types at boundary
        guard let email = Email(emailString),
              let password = Password(passwordString) else {
            // Handle validation error
            return
        }
        
        isLoading = true
        defer { isLoading = false }

        do {
            // Domain receives validated types
            let user = try await loginUseCase.execute(email: email, password: password)
            // Handle success
        } catch {
            self.error = error
        }
    }
}
```
</layer>

#### Data Flow

1. View instantiates ViewModel with injected use cases.
2. ViewModel calls use case `execute()` methods.
3. Use cases invoke repository protocols.
4. Repositories use data sources (e.g., UserDefaults) for persistence.

#### Layer Dependencies Summary

| Layer | Can Depend On | Cannot Depend On |
|-------|--------------|------------------|
| Domain | Nothing (pure Swift) | Data, Presentation |
| Data | Domain | Presentation |
| Presentation | Domain, Data (via DI) | — |

## Code Style Conventions

- Swift files use 4-space indentation, ≤180-character width, and always-trailing commas

### File Headers and Documentation

All source files must include the standard license header:
- Author: Gustavo Araujo Santos
- Date: Creation date in the mm/dd/yy format

```swift
//
//  FileName.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on [Date].
//
```

## CORE RULES [CRITICAL - ALWAYS APPLY]

<rule_1 priority="HIGH">
**PROGRESSIVE ARCHITECTURE**: Start simple → Add complexity only when proven necessary
```swift
// Step 1: Direct implementation
// Step 2: Protocol when second implementation exists
// Step 3: Generic when pattern emerges
```
</rule_1>

<rule_2 priority="HIGH">
**COMPREHENSIVE ERROR HANDLING**: Make impossible states unrepresentable
- Use exhaustive enums with associated values
- Provide actionable recovery paths
- NEVER force unwrap in production
</rule_2>

<rule_3 priority="HIGH">
**PARSE, DON'T VALIDATE**: Use types to carry proof of validation
- Create validation-carrying types (e.g., `Email`, `Password`) instead of validating raw strings
- Types serve as vessels for validated data, carrying validation invariants within them
- Prefer parsing (transformation with retention) over validation (check with discard)
- Validation checks can be displaced; parsed types cannot be created without validation
- Eliminates systemic vulnerabilities from scattered validation logic
</rule_3>

<rule_4 priority="HIGH">
**DOMAIN BOUNDARIES & TYPE PLACEMENT**: Keep strongly-typed domain types in the domain, weakly-typed primitives at boundaries
- Domain logic lives with domain types (e.g., `Email`, `Password` in login domain)
- UI domain works with strings (for display purposes)
- Network/Data layer works with strings/JSON (for serialization)
- Parse at boundaries: convert strings → domain types when entering domain, domain types → strings when leaving
- Pushing weakly-typed types outside the domain achieves clean, robust domain code
- Domain code becomes unbreakable: even if boundary checks are commented out, domain invariants remain enforced by types
</rule_4>

<rule_5 priority="HIGH">
**WITNESS PATTERN FOR ACCESS CONTROL**: Turn conventions into compile-time requirements
- A **Witness** is a value that proves a precondition is met (e.g., feature enabled, user authenticated, data saved)
- Replace boolean flags with optional witness types (e.g., `isEnabled: Bool` → `enabled: FeatureEnabled?`)
- Use `fileprivate init()` to prevent forging witnesses outside their origin
- Require witnesses as non-optional arguments to enforce access control at compile time
- Code fails to compile if access control isn't enforced, catching mistakes early
- Use "black hole" arguments (`init(_: Witness)`) when witness is only proof, not data
</rule_5>

<rule_6 priority="MEDIUM">
**TESTABLE BY DESIGN**: Inject all dependencies
- Design for testing from start
- Test behavior, not implementation
- Decouple from frameworks
</rule_6>

## Common Implementation Patterns

<pattern name="dependency_injection">
```swift
// ALWAYS inject, NEVER hardcode
protocol TimeProvider { var now: Date { get } }
struct Service {
    init(time: TimeProvider = SystemTime()) { }
}
```
</pattern>

<pattern name="error_design">
```swift
enum DomainError: LocalizedError {
    case specific(reason: String, recovery: String)

    var errorDescription: String? { /* reason */ }
    var recoverySuggestion: String? { /* recovery */ }
}
```
</pattern>

<pattern name="progressive_enhancement">
```swift
// 1. Start direct
func fetch() { }

// 2. Abstract when needed
protocol Fetchable { func fetch() }

// 3. Generalize when pattern emerges
protocol Repository<T> { }
```
</pattern>

<pattern name="type_safe_validation">
```swift
// ❌ AVOID: Validation that discards information
func isValidEmail(_ string: String) -> Bool {
    return string.matches("#email regex#")
}
if isValidEmail(email) {
    // ⚠️ No proof retained - validation can be bypassed
}

// ✅ PREFER: Parsing that retains validation proof
struct Email {
    let rawValue: String
    
    init?(_ rawValue: String) {
        guard rawValue.matches("#email regex#") else {
            return nil
        }
        self.rawValue = rawValue
    }
}

// Usage: Type carries proof of validation
func login(email: Email, password: Password) {
    // ✅ Has proof that email and password are validated
    // No need to validate again
}

// Parse at boundaries, propagate validated types
guard let validEmail = Email(emailString),
      let validPassword = Password(passwordString) else {
    return
}
login(email: validEmail, password: validPassword)
```
</pattern>

<pattern name="domain_boundaries">
```swift
// ✅ CORRECT: Parse at boundaries, use domain types in domain

// UI Layer: Works with strings
struct LoginView: View {
    @State var emailString: String = ""  // UI uses strings
    @State var passwordString: String = ""
    
    func onLoginTapped() {
        // Parse strings → domain types at boundary
        guard let email = Email(emailString),
              let password = Password(passwordString) else {
            return
        }
        viewModel.login(email: email, password: password)
    }
}

// Domain Layer: Works with domain types
final class LoginUseCase {
    func execute(email: Email, password: Password) async throws -> User {
        // ✅ Domain code is robust - types enforce invariants
        // Even if boundary checks are removed, domain types prevent invalid data
        return try await repository.login(email: email, password: password)
    }
}

// Data Layer: Converts domain types → strings/JSON at boundary
final class AuthRepository: AuthRepositoryProtocol {
    func login(email: Email, password: Password) async throws -> User {
        // Convert domain types → strings for network
        let request = LoginRequest(
            email: email.rawValue,      // Domain → string at boundary
            password: password.rawValue
        )
        let dto = try await networkService.post("/login", body: request)
        return dto.toDomain()
    }
}

// ❌ AVOID: Passing strings through domain
func execute(email: String, password: String) {
    // ⚠️ Domain doesn't know if data is validated
    // Must check everywhere, can be bypassed
}
```
</pattern>

<pattern name="witness_access_control">
```swift
// ❌ AVOID: Boolean flags for access control
struct FeatureFlags {
    let isPremiumEnabled: Bool  // ⚠️ Can be ignored, no compile-time enforcement
}

if featureFlags.isPremiumEnabled {
    showPremiumFeature()  // ⚠️ Another entry point might forget this check
}

// ✅ PREFER: Witness pattern for type-safe access control

// 1. Define witness with fileprivate init (can't be forged)
struct PremiumEnabled {
    fileprivate init() {}  // Only creatable in this file
}

// 2. Replace Bool with optional witness
struct FeatureFlags: Decodable {
    let premiumEnabled: PremiumEnabled?
    
    enum CodingKeys: String, CodingKey {
        case isPremiumEnabled = "premium-enabled"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let isPremiumEnabled = try container.decode(Bool.self, forKey: .isPremiumEnabled)
        // Embed proof into witness during decoding
        self.premiumEnabled = isPremiumEnabled ? PremiumEnabled() : nil
    }
}

// 3. Require witness as proof (black hole argument)
struct PremiumFeatureScreen: View {
    init(_: PremiumEnabled) {}  // Requires proof, not data
}

// 4. Propagate witness through navigation
enum Path {
    case premium(PremiumEnabled)  // Witness travels with path
}

// Usage: Compile-time enforcement
if let premiumEnabled = featureFlags.premiumEnabled {
    path.append(.premium(premiumEnabled))  // ✅ Can only navigate with proof
}

// Deep link without witness = compile error
.onOpenURL { url in
    if url.path() == "/premium" {
        path.append(.premium(???))  // ❌ ERROR: Missing proof!
    }
}
```
</pattern>

<pattern name="witness_operation_order">
```swift
// ✅ Use witnesses to enforce operation order

// Witness proves video was saved
struct SavedVideo {
    let videoData: Data
    fileprivate init(_ videoData: Data) {
        self.videoData = videoData
    }
}

class VideoStorage {
    func save(_ videoData: Data) async throws -> SavedVideo {
        // ... saving logic ...
        return SavedVideo(videoData)  // Proof embedded on success
    }
}

class VideoUploader {
    // Requires proof that video was saved first
    func upload(_ savedVideo: SavedVideo) async { ... }
}

// Usage: Correct order enforced by types
let savedVideo = try await storage.save(videoData)
await uploader.upload(savedVideo)  // ✅ Must save first

// Wrong order = compile error
await uploader.upload(videoData)  // ❌ ERROR: Expected SavedVideo, not Data
```
</pattern>

## QUALITY GATES

<checklist>
☐ NO force unwrapping (!, try!)
☐ ALL errors have recovery paths
☐ DEPENDENCIES injected via init
☐ PUBLIC APIs documented
☐ EDGE CASES handled (nil, empty, invalid)
☐ VALIDATION uses parsing (validation-carrying types) not boolean checks
☐ VALIDATED data flows through system as typed values, not raw strings
☐ DOMAIN BOUNDARIES: Domain uses domain types, boundaries parse strings ↔ domain types
☐ ROBUST DOMAIN: Domain code unbreakable even if boundary checks are removed
☐ ACCESS CONTROL: Preconditions use witnesses, not boolean checks
☐ OPERATION ORDER: Sequential operations enforced by witness types when critical
</checklist>

## ANTI-PATTERNS TO AVOID

<avoid>
❌ God objects (500+ line ViewModels)
❌ Stringly-typed APIs
❌ Synchronous network calls
❌ Retained cycles in closures
❌ Force unwrapping optionals
❌ Scattered validation checks (validation that discards proof)
❌ Passing raw strings where validated types are needed
❌ Re-validating data that should already be validated (indicates missing type safety)
❌ Passing strings through domain layer (domain should use domain types)
❌ Domain types in UI/Network layers (boundaries should use primitives)
❌ Weakly-typed primitives in domain logic (domain should be strongly-typed)
❌ Boolean flags for access control (use witness types instead)
❌ Multiple entry points without compile-time access enforcement
❌ Forgeable proofs (witness init should be fileprivate)
❌ Relying on convention/discipline for access control (turn into compile-time requirement)
</avoid>

## Build & Run

- iOS 26.0 target
- Swift 6 language version

## Commands

- `swiftformat .`: Apply formatting (run after finishing edit)
- `swiftlint .`: Lint Swift sources (run after finishing edit)

## MCP Tools Integration - Use tools if you can

The AI agents leverage MCP (Model Context Protocol) servers to enhance development capabilities and access up-to-date documentation:

**Context7 MCP Server**:
- **Purpose**: Use to fetch latest library documentation and API references
- **Capabilities**: 
  - Resolve library IDs for Swift packages and frameworks
  - Retrieve comprehensive documentation for Apple frameworks (SwiftUI, UIKit, Core ML, etc.)
  - Access up-to-date API references and code examples
- **Integration**: Automatically used for code generation, setup, and configuration steps
- **Benefits**: Ensures agents work with current APIs and best practices

**Serena MCP Server**:
- **Purpose**: Use for high-precision internal navigation and symbolic understanding of the local codebase.
- **Capabilities**:
  - Symbolic Search: Find exact function definitions, class structures, and variable usages using LSP (Language Server Protocol)
  - Dependency Mapping: Trace call hierarchies to understand how components interact across different files
  - Context-Aware Extraction: Extract specific code blocks (e.g., a single method body) without reading entire files, saving token window space
- **Benefits**: Provides 100% accuracy in code navigation and significantly reduces "hallucinations" regarding local project structure.

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
- For external knowledge consult the `context7` tool for most up-to-date software package documentation
- For internal knowledge consult the `serena` tool before editing code to verify existing function signatures, find references, or map project dependencies
- Prefer serena's symbol-based reading over full-file reading for large files to maintain a lean context window and efficiency
- Use the agent skills to perform activities