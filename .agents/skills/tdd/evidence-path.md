# Evidence path

An **evidence path** is the route from the claim a change makes to evidence that can establish, limit or refute it. Plan it before the first red when one unit test at an obvious seam cannot carry the claim.

## 1. Frame the claim

State the behaviour that must become true, what must stay true, and the failure that would make a confident "done" wrong.

**Done when:** the claim and its worst failure mode are each one sentence.

## 2. Choose the path

List at least two ways this system can show the claim, then pick the one whose red is most direct for its cost. What the repo already offers:

| Evidence | Establishes |
|---|---|
| A Swift Testing test with the `Mocks/` knobs and `TestDataBuilder.fixedDate` | Domain, Data and ViewModel behaviour, date-dependent rules |
| A decode test on a saved `HealthTrackerData.json` | That existing users' files still load (root **Data Migrations**) |
| An AppIntentsTesting test | An intent's result, in `en` and `pt-BR` |
| An XCUITest on the isolated store the `-uiTesting` switch gives | A flow through the real UI |
| The same test over 20 runs | A failure **rate**. It limits a flake claim; it does not establish the cause |
| `device-interaction` on a store seeded with `mock-sim-data` | What only the running app shows |
| `RenderPreview` | Layout in light, dark and large type |
| A fitness check or SwiftLint rule | That a whole class of mistake cannot recur |

Give each distinct claim one piece of evidence, and add a second only when it covers a boundary the first cannot reach. `scripts/quality` still runs whatever you choose.

**Done when:** the preferred path is named with what it cannot show, and the fallback if it proves too slow or too flaky.

## 3. Build an affordance when the truth is indirect

When no path above shows the claim directly, add a **verification affordance**: the smallest capability that makes the state controllable, observable and repeatable. Examples here: a launch argument in `UITestingSupport.swift`, an injected clock, a fixture file, an accessibility identifier.

Decide before building whether it is temporary (removed once the claim is closed) or durable (kept, tested, documented). Ask the user before adding a dependency or a diagnostic surface that ships in the app.

For an unfamiliar Apple API, find what the platform offers for testing it with `DocumentationSearch` before designing your own.

**Done when:** the path runs without guessing at setup or state, and the affordance has its lifecycle decided.

## 4. Close the path

After the change, follow the path and report the claim as **established**, **limited** (say to what) or **refuted**, in the report's and the PR's "How verified". "20 of 20 green" after "3 of 20 red" limits a flake claim to that rate; name the mechanism to establish it.

**Done when:** a reader sees what supports the conclusion and what stays outside its reach.
