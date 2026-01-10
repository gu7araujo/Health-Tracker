# Agent Guide

## Guide Purpose
Agents act as senior Swift collaborators. Keep responses concise, clarify uncertainty before coding, and align suggestions with the rules linked below.

## Project Idea
HealthTracker is a user-focused, distraction-free modern Swift/iOS 26.0 app designed to help you monitor your healthy habits through a few pre-defined points.

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

### Data Communication Between Layers

Communication follows the **Dependency Inversion** principle. Here is the step-by-step flow:

<layer name="domain" description="Defines WHAT needs to be done, not HOW">
```swift
// Domain/Protocols/AuthRepositoryProtocol.swift
public protocol AuthRepositoryProtocol {
    func login(username: String, password: String) async throws -> User
}

// Domain/UseCases/LoginUseCase.swift
public final class LoginUseCase {
    private let repository: AuthRepositoryProtocol  // Depends on abstraction, NOT implementation
    
    public init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(username: String, password: String) async throws -> User {
        try await repository.login(username: username, password: password)
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

    func login(username: String, password: String) async throws -> User {
        // 1. Call API
        let dto = try await networkService.post("/auth/login", body: LoginRequest(username: username, password: password))
        // 2. Convert DTO → Domain Entity (via Mapper)
        // 3. Return Entity
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

    func onLoginButtonTapped(username: String, password: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await loginUseCase.execute(username: username, password: password)
            // Handle success
        } catch {
            self.error = error
        }
    }
}
```
</layer>

### Layer Dependencies Summary

| Layer | Can Depend On | Cannot Depend On |
|-------|--------------|------------------|
| Domain | Nothing (pure Swift) | Data, Presentation |
| Data | Domain | Presentation |
| Presentation | Domain, Data (via DI) | — |

## Code Style Conventions
- Swift files use 4-space indentation, ≤180-character width, and always-trailing commas

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

<rule_3 priority="MEDIUM">
**TESTABLE BY DESIGN**: Inject all dependencies
- Design for testing from start
- Test behavior, not implementation
- Decouple from frameworks
</rule_3>

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

## QUALITY GATES

<checklist>
☐ NO force unwrapping (!, try!)
☐ ALL errors have recovery paths
☐ DEPENDENCIES injected via init
☐ PUBLIC APIs documented
☐ EDGE CASES handled (nil, empty, invalid)
</checklist>

## ANTI-PATTERNS TO AVOID

<avoid>
❌ God objects (500+ line ViewModels)
❌ Stringly-typed APIs
❌ Synchronous network calls
❌ Retained cycles in closures
❌ Force unwrapping optionals
</avoid>

## Workflow
- Ask for clarification when requirements are ambiguous; surface 2–3 options when trade-offs matter
