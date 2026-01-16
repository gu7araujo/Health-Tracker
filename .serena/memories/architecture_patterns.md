# Architecture Patterns

## Clean Architecture Layers

### Domain Layer (Pure Swift)
- **Entities**: Business models (`DayData`, `Meal`, `Mood`, `Workout`)
- **Use Cases**: Business rules (`LoadDayDataUseCase`, `SaveDayDataUseCase`)
- **Protocols**: Contracts (`HealthDataRepositoryProtocol`)
- **Rule**: Domain knows nobody - no dependencies on Data or Presentation

### Data Layer
- **DataSources**: Local/Remote data access (`UserDefaultsDataSource`)
- **Repositories**: Protocol implementations (`HealthDataRepository`)
- **Rule**: Data depends only on Domain

### Presentation Layer
- **ViewModels**: `@Observable` classes coordinating use cases (`MainViewModel`)
- **Views**: SwiftUI views (`MainView`, `AddEditModal`, Components)
- **Rule**: Presentation depends on Domain (via DI) and Data (via DI)

## Data Flow
```
View → ViewModel → UseCase → Repository → DataSource
                      ↓
                   Domain Entity
```

1. View instantiates ViewModel with injected use cases
2. ViewModel calls use case `execute()` methods
3. Use cases invoke repository protocols
4. Repositories use data sources for persistence

## Key Patterns

### Dependency Injection
```swift
// Always inject, never hardcode
final class MainViewModel {
    private let loadUseCase: LoadDayDataUseCase
    
    init(loadUseCase: LoadDayDataUseCase) {
        self.loadUseCase = loadUseCase
    }
}
```

### Parse, Don't Validate
```swift
// Use types that carry proof of validation
struct Email {
    let rawValue: String
    init?(_ rawValue: String) {
        guard rawValue.matches(emailRegex) else { return nil }
        self.rawValue = rawValue
    }
}
```

### Witness Pattern
```swift
// Turn conventions into compile-time requirements
struct PremiumEnabled {
    fileprivate init() {}  // Can't be forged
}
```

### Progressive Architecture
1. Start with direct implementation
2. Add protocol when second implementation exists
3. Generalize when pattern emerges
