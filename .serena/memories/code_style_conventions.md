# Code Style & Conventions

## Formatting Rules
- **Indentation**: 4 spaces
- **Line width**: ≤180 characters
- **Trailing commas**: Always use trailing commas in multi-line collections/parameters

## File Headers
All source files must include the standard header:
```swift
//
//  FileName.swift
//  HealthTracker
//
//  Created by Gustavo Araujo Santos on [Date].
//
```
Date format: `mm/dd/yy`

## Naming Conventions
- **Types**: PascalCase (`MainViewModel`, `DayData`)
- **Properties/Methods**: camelCase (`selectedDate`, `loadData()`)
- **Protocols**: Suffix with `Protocol` (`HealthDataRepositoryProtocol`)
- **Use Cases**: Suffix with `UseCase` (`LoadDayDataUseCase`)

## Documentation
- Use `///` doc comments for public APIs
- Include `// MARK: -` sections to organize code

## SwiftUI Patterns
- Use `@Observable` macro for ViewModels (not `ObservableObject`)
- Use `@State` for view-local state
- Extract complex view sections into computed properties

## Architecture Patterns
- **Dependency Injection**: Always inject dependencies via `init`
- **Parse, Don't Validate**: Use validation-carrying types (e.g., `Email`, `Password`)
- **Witness Pattern**: Use witness types for access control instead of boolean flags
- **Progressive Architecture**: Start simple, add complexity only when proven necessary

## Anti-Patterns to Avoid
- ❌ Force unwrapping (`!`, `try!`)
- ❌ God objects (500+ line ViewModels)
- ❌ Stringly-typed APIs
- ❌ Passing raw strings through domain layer
- ❌ Boolean flags for access control
