# Swift API Design Guidelines — Full Reference

This file contains the detailed guidelines extracted from [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/). Use it when you need examples or full wording.

---

## Introduction

Delivering a clear, consistent developer experience in Swift is largely defined by the names and idioms in APIs. These guidelines help code feel like part of the larger Swift ecosystem.

## Fundamentals

- **Clarity at the point of use** is the most important goal. Design so uses are clear and concise; evaluate at call sites, not only at the declaration.
- **Clarity is more important than brevity.** Brevity is a side-effect of the type system and reduced boilerplate, not a goal.
- **Write a documentation comment for every declaration.** If you have trouble describing the API in simple terms, you may have designed the wrong API.
- Use Swift's dialect of Markdown. Begin with a summary. Use a single sentence fragment when possible, ending with a period. Describe what functions/methods do and return; what subscripts access; what initializers create; what other entities are.
- Use symbol documentation markup and symbol command syntax (Parameter, Returns, Throws, Note, SeeAlso, etc.) where appropriate.

## Naming

### Promote Clear Usage

- Include all words needed to avoid ambiguity at the use site (e.g. `remove(at: position)` not `remove(position)` so it's clear you remove at a position, not an equal element).
- Omit needless words; omit words that merely repeat type information (e.g. `remove(_ member:)` not `removeElement(_ member:)`).
- Name variables, parameters, and associated types by their **roles**, not type constraints (e.g. `ContentView`, `supplier`).
- If an associated type is so bound to its protocol that the protocol name is the role, append `Protocol` to avoid collision (e.g. `Iterator : IteratorProtocol`).
- For weak type information (`NSObject`, `Any`, `AnyObject`, `Int`, `String`), precede with a noun describing role (e.g. `addObserver(_:forKeyPath:)`).

### Strive for Fluent Usage

- Prefer names that form grammatical English at use: `x.insert(y, at: z)`, `x.subviews(havingColor: y)`, `x.capitalizingNouns()`.
- Factory methods begin with **make** (e.g. `x.makeIterator()`).
- The first argument to initializers and factory methods should not form a phrase with the base name (e.g. `Color(red: 32, green: 64, blue: 128)` not `Color(havingRGBValuesRed: 32, ...)`). Value-preserving conversions are an exception: first argument often has no label, e.g. `RGBColor(cmykForeground)`.
- **Side effects**: none → noun phrase (`x.distance(to: y)`); with side effects → imperative verb (`print(x)`, `x.sort()`, `x.append(y)`).
- **Mutating/nonmutating pairs**: verb imperative for mutating; past participle (-ed) or present participle (-ing) for nonmutating. Examples: `reverse()` / `reversed()`, `stripNewlines()` / `strippingNewlines()`. When the operation is a noun: noun for nonmutating, **form** prefix for mutating (`union(_:)` / `formUnion(_:)`).
- Boolean methods/properties should read as assertions: `x.isEmpty`, `line1.intersects(line2)`.
- Protocols that describe what something is → nouns (`Collection`). Protocols that describe a capability → `-able`, `-ible`, or `-ing` (`Equatable`, `ProgressReporting`). Other types, properties, variables, constants → nouns.

### Use Terminology Well

- Avoid obscure terms when a common word works. Use terms of art only when meaning would otherwise be lost.
- Use terms in their established meaning. Avoid abbreviations unless the meaning is easily discoverable (e.g. by web search). Embrace precedent (e.g. `Array`, `sin(x)`).

## Conventions

### General Conventions

- Document complexity of any computed property that is not O(1).
- Prefer methods and properties to free functions. Use free functions when: there's no obvious `self` (`min(x, y, z)`), unconstrained generic (`print(x)`), or domain notation (`sin(x)`).
- **Case**: types and protocols `UpperCamelCase`; everything else `lowerCamelCase`. Acronyms that are all-caps in English follow the same case (`utf8Bytes`, `userSMTPServer`); others as words (`radarDetector`).
- Methods can share a base name when they share the same basic meaning or operate in distinct domains. Do not overload on return type.

### Parameters

- Choose parameter names to serve documentation; they should read naturally in doc comments.
- Use defaulted parameters to simplify common uses; prefer one method with defaults over method families.
- Prefer parameters with defaults toward the end of the parameter list.
- Production APIs: prefer `#fileID`. Use `#filePath` for dev-only (e.g. test helpers). Use `#file` for Swift 5.2 compatibility.

### Argument Labels

- Omit all labels when arguments can't be usefully distinguished: `min(number1, number2)`, `zip(sequence1, sequence2)`.
- **Value-preserving type conversion** initializers: omit the first argument label (e.g. `String(veryLargeNumber, radix: 16)`). **Narrowing** conversions: use a label (e.g. `init(truncating:)`, `init(saturating:)`).
- When the first argument is part of a prepositional phrase, give it a label starting at the preposition: `x.removeBoxes(havingLength: 12)`. When the first two arguments are parts of one abstraction, start the label after the preposition: `a.moveTo(x: b, y: c)`.
- When the first argument forms part of a grammatical phrase, omit its label (e.g. `x.addSubview(y)`). Otherwise use a label: `view.dismiss(animated: false)`, `words.split(maxSplits: 12)`. Arguments with default values should have labels.
- Label all other arguments.

## Special Instructions

- Label tuple members and name closure parameters where they appear in the API.
- With unconstrained polymorphism (`Any`, `AnyObject`, unconstrained generics), avoid overload ambiguity (e.g. name the sequence-append variant `append(contentsOf:)` instead of overloading `append(_:)` when `Element` could be `Any`).
