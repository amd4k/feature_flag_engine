# Feature Flag Engine

A database-backed feature flag system that allows features to be defined, overridden, and evaluated at runtime with predictable precedence rules.

This project was built as a coding exercise with a focus on **correctness**, **clear separation of concerns**, and **production-style design**, rather than UI polish.

---

## Why Feature Flags

Feature flags (also known as feature toggles) allow applications to enable or disable functionality at runtime without redeploying code. They are commonly used to:

* Roll out features gradually
* Enable functionality for specific users or groups
* Disable problematic features quickly
* Experiment safely in production

---

## High-Level Design

The system is split into two clear layers:

### 1. Core Feature Flag Engine

A pure Ruby service responsible for evaluating whether a feature is enabled for a given context.

### 2. Admin Interface (Configuration Layer)

A simple Rails-based admin UI used to define features and manage overrides.

This separation allows the core engine to be reused by any interface (web, API, CLI, background jobs, etc.).

---

## Feature Model

Each feature flag has:

* A unique `key`
* A global default state (`default_enabled`)
* An optional human-readable `description`

The global default applies unless overridden.

---

## Override Model

Overrides allow feature behavior to differ for specific contexts.

Each override includes:

* `target_type` – currently supports:

  * `User`
  * `Group`
* `target_identifier` – the identifier for the user or group
* `enabled` – whether the feature is enabled or disabled for that target

Overrides are stored in the database and enforced with uniqueness constraints to prevent conflicting entries.

---

## Evaluation Rules (Precedence)

When evaluating a feature flag, the following precedence rules apply:

1. **User-specific override** (highest priority)
2. **Group-specific override**
3. **Global default state** (fallback)

This behavior is deterministic and explicitly enforced in the evaluation logic.

---

## Runtime Evaluation

Feature evaluation is performed via a dedicated service:

```ruby
FeatureFlags::Evaluator.new(
  feature_key: "dark_mode",
  user_id: "123",
  groups: ["beta_testers"]
).enabled?
```

The evaluator:

* Is side-effect free
* Does not depend on UI or controllers
* Can be called from anywhere in the application

---

## Admin Interface

The system is exposed via a **simple admin web interface**, implemented using standard Rails controllers and views.

From the admin UI, you can:

* Create and update feature flags
* Toggle global default state
* Add or remove user-specific overrides
* Add or remove group-specific overrides

This satisfies the requirement to support feature mutations while keeping the core engine isolated.

---

## Validation & Error Handling

The system validates inputs to ensure predictable behavior:

* Feature keys must be unique
* Overrides are uniquely constrained per feature + target
* Non-existent features safely evaluate to `false`
* Invalid operations fail explicitly rather than silently

---

## Database

Phase 1 uses a **database-backed implementation** with:

* `features` table
* `feature_overrides` table
* Appropriate indexes and constraints for correctness and performance

---

## Tests

Core logic is covered with unit tests focused on:

* Feature evaluation correctness
* Override precedence
* Edge cases (missing features, missing overrides)

Tests are written to read like documentation for the feature flag behavior.

---

## How to Run

```bash
bundle install
rails db:create db:migrate
rails server
```

Visit:

```
http://localhost:3000
```

to access the admin interface.

---

# Verifying Feature Flags via Rails Console

The easiest way to validate the feature-flag system is via the Rails console.

```bash
rails console
```

These checks exercise the core business logic (`FeatureFlags::Evaluator`) independent of UI.

---

## Assumptions

* Feature key: `dark_mode`
* Feature exists in the `features` table
* Evaluator precedence order:

```
User override → Group override → Feature default
```

---

## A. Feature Does Not Exist

```ruby
FeatureFlags::Evaluator.new(
  feature_key: "non_existent_feature",
  user_id: "123",
  groups: ["beta_testers"]
).enabled?
```

**Expected:** `false`

**Why:**
If the feature cannot be found, the evaluator safely returns `false`.

---

## B. Feature Exists, No Overrides

First, clear all overrides:

```ruby
FeatureOverride.delete_all
```

Ensure default is disabled:

```ruby
Feature.find_by(key: "dark_mode").update!(default_enabled: false)

FeatureFlags::Evaluator.new(
  feature_key: "dark_mode",
  user_id: "123",
  groups: ["beta_testers"]
).enabled?
```

**Expected:** `false`

Now flip the default:

```ruby
Feature.find_by(key: "dark_mode").update!(default_enabled: true)

FeatureFlags::Evaluator.new(
  feature_key: "dark_mode",
  user_id: "123",
  groups: ["beta_testers"]
).enabled?
```

**Expected:** `true`

**Why:**
With no overrides present, the evaluator falls back to the feature default.

---

## C. User Override Beats Group Override

```ruby
FeatureOverride.create!(
  feature: Feature.find_by(key: "dark_mode"),
  target_type: "User",
  target_identifier: "123",
  enabled: false
)

FeatureOverride.create!(
  feature: Feature.find_by(key: "dark_mode"),
  target_type: "Group",
  target_identifier: "beta_testers",
  enabled: true
)
```

Test:

```ruby
FeatureFlags::Evaluator.new(
  feature_key: "dark_mode",
  user_id: "123",
  groups: ["beta_testers"]
).enabled?
```

**Expected:** `false`

**Why:**
User-specific overrides always take precedence over group overrides.

---

## D. Multiple Group Memberships

```ruby
FeatureOverride.create!(
  feature: Feature.find_by(key: "dark_mode"),
  target_type: "Group",
  target_identifier: "admins",
  enabled: true
)
```

Test:

```ruby
FeatureFlags::Evaluator.new(
  feature_key: "dark_mode",
  user_id: "999",
  groups: ["beta_testers", "admins"]
).enabled?
```

**Expected:**

* `true` if the `admins` override is the most recently created
* `false` otherwise

**Why:**
When multiple group overrides apply, the evaluator resolves conflicts using creation order.

---

## E. No Groups Provided

```ruby
FeatureFlags::Evaluator.new(
  feature_key: "dark_mode",
  user_id: "999",
  groups: []
).enabled?
```

**Expected:** feature default value

**Why:**
With no applicable user or group overrides, the evaluator falls back to the feature default.

---

## Why This Matters

These console checks demonstrate:

* Safe handling of missing features
* Correct fallback behavior
* Clear precedence rules
* Deterministic override resolution

This is the core of the system.

---

## Assumptions

* User and group identifiers are treated as opaque strings
* The feature flag engine is decoupled from application-specific user or group models
* Admin access is assumed to be trusted (authentication is out of scope)

---

## Tradeoffs

* A simple admin UI was chosen over a REST API or CLI for clarity and ease of demonstration
* No caching was added to keep behavior explicit and easy to reason about within the time box
* Region-based overrides were not implemented

---

## Known Limitations

* No region-based overrides (Phase 2 “nice to have”)
* No caching or memoization for high-throughput evaluation
* Basic UI with minimal styling
* No authentication/authorization for admin actions

---

## What I’d Do Next With More Time

* Add in-memory or request-scoped caching for evaluation
* Support region-based overrides as an additional precedence layer
* Expose a REST API for feature evaluation
* Add audit logging for override changes
* Improve admin UI validation and UX
* Add performance benchmarks

---

## Commit History

Commits were made incrementally to reflect design decisions and implementation progress, rather than squashing into a single commit.

---

## Final Notes

This project prioritizes **correct behavior**, **predictable evaluation**, and **clean design** over UI polish, in line with the challenge goals.
