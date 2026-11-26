---
name: app-copy
description: Name and word every text an app user reads or hears: screen labels, buttons, empty states, notifications, intent titles and Siri phrases, day-status wording, App Store text. Use before writing, changing or reviewing any such string, in en and pt-BR.
---

# App copy

A name is a design decision, as much as layout. It follows Apple's WWDC26 session 290 ("Craft clear names for features and labels in your app"). Prose in a PR, README or reply follows `unslop`; this skill covers the words the app shows.

## 1. Know the surface

| Surface | Where | Constraint |
|---|---|---|
| Screens, buttons, pickers, empty states | `Localizable.strings`, both locales | Change values, not keys; keys stay in parity (`scripts/fitness/localization-parity.sh`) |
| Notifications | `notification_*` | Name the action and use the vocabulary below |
| Intent titles, parameters, dialogs | `intent_*` | `Presentation/Intents/AGENTS.md` rules apply; the dialog is spoken |
| Siri phrases | `AppShortcuts.strings` | Frozen contract: never edit |
| Day status | `day_status_explanation.*`, `day_status_reason.*` | Composed as `header: reason, reason.` and read by Siri |
| App Store name, subtitle, description | outside the repo | Same vocabulary and criteria; the app name is "Clune" |

**Done when:** each string you touch has its surface and its Swift call site (`grep` the key), so you know what composes it.

## 2. Test each candidate against three criteria

1. **Belongs.** It fits the app's tone and sits well beside neighbouring labels.
2. **Sets the expectation.** A user predicts what they find or what happens before tapping.
3. **Works everywhere.** It holds in en and pt-BR, aloud through Siri and VoiceOver, and next to its neighbours.

The criteria are guides. Weigh them by context: a health or trust screen takes plain, neutral words over brand voice; a feature name can be more expressive if people still understand it.

## 3. Rules that follow

- **Describe the data, not the person.** "Below targets", not "Poor day". A low value must never read as a verdict.
- **One concept, one name.** Use the vocabulary below on every surface. A new word for an existing concept is a bug.
- **Say it aloud.** If nobody would say "Current Funds" in conversation, it does not belong.
- **Verb for an action the user controls**, noun for a thing they have. Name what it does for them, not how it is built.
- **State facts a rule can back.** A reason string must match the condition in `Domain` that triggers it ("a large meal or 3+ medium meals", not "multiple large/medium meals").
- **Keep scales on one axis.** "Good / Neutral / Bad" stays evaluative; one emotion ("Sad") in that list breaks it.
- **No gendered forms in pt-BR** ("Satisfeito(a)" reads badly aloud): use the noun ("Satisfação"). Check that adjectives agree with the noun they modify ("Porção … Pequena").
- **Sentence case** in pt-BR. English title case exists today in intent titles, Apple's Shortcuts convention.
- **Test it in a sentence** ("Log a meal in Clune", "Nothing logged yet") before keeping it.

## 4. Vocabulary

| Concept | en | pt-BR |
|---|---|---|
| Add a record by voice or shortcut | Log | Registrar |
| Meal size (Very small to Large) | Size | Porção |
| Meal rating | Satisfaction | Satisfação |
| Workout length | Duration | Duração |
| Exercise | Workout | Treino |
| Nothing recorded | Nothing logged yet | Nada registrado ainda |
| Day verdicts | All targets met. / Near targets / Below targets | Todas as metas atingidas. / Perto das metas / Abaixo das metas |

A new row goes here in the same change that introduces the word.

## 5. Verify with adversaries

Write en and pt-BR as two natural wordings, never a translation of each other. Then start one fresh-context reviewer per locale, briefed with the proposal, the criteria above and the call sites, with instructions to reject or improve each item (`reviewing` skill, `parallel-agents` for briefing). A native pt-BR reviewer is the only check on agreement, idiom and tone.

**Done when:** each item has an accept, a change or a rejection from the reviewer of its locale, and your disagreements with a reviewer are written down with the reason.

## 6. Update what asserts the text

UI tests assert visible text in English: `HealthTrackerUITests` and `HealthTrackerIntentsUITests` (`card.label.contains(...)`) and `EnglishLabel`. Change those first, watch one fail (red), then change the strings. Unit tests that use `String(localized:)` keys need no edit.

**Done when:** `grep -rn '<old text>' HealthTrackerUITests HealthTrackerIntentsUITests` returns nothing and `scripts/quality --full` exits 0.
