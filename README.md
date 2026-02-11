# Feature Flag Engine

A database backed feature flag system that allows features to be defined, overridden, and evaluated at runtime with predictable precedence rules.

This project was built as a coding exercise with a focus on correctness, separation of concerns, and production oriented design rather than UI polish.

---

## Overview

Feature flags allow applications to enable or disable functionality at runtime without redeploying code. They are commonly used to:

* Roll out features gradually
* Enable functionality for specific users or groups
* Disable problematic features quickly
* Experiment safely in production

This implementation provides a deterministic, database backed feature flag engine with clear override precedence.

---

## Architecture

The system is split into two layers:

### Core Feature Flag Engine

A pure Ruby service responsible for evaluating whether a feature is enabled for a given context.

### Admin Interface

A minimal Rails based interface used to create features and manage overrides.

The evaluation logic is fully decoupled from controllers and views, allowing the engine to be reused by other interfaces such as APIs, background jobs, or CLI tools.

---

## Data Model

### Feature

Each feature includes:

* `key` (unique)
* `default_enabled`
* `description` (optional)

The default value is used when no overrides apply.

### FeatureOverride

Each override includes:

* `feature_id`
* `target_type` (`User` or `Group`)
* `target_identifier`
* `enabled`

Overrides are uniquely constrained per feature and target to prevent conflicting entries.

---

## Evaluation Precedence

When evaluating a feature:

1. User specific override
2. Group specific override
3. Feature default

This order is explicitly enforced in the evaluation service to guarantee predictable behavior.

---

## Runtime Usage

Feature evaluation is performed via:

```ruby
FeatureFlags::Evaluator.new(
  feature_key: "dark_mode",
  user_id: "123",
  groups: ["beta_testers"]
).enabled?
```

The evaluator:

* Is side effect free
* Returns a boolean
* Can be invoked anywhere in the application

---

## Admin Capabilities

From the admin interface, you can:

* Create and update feature flags
* Toggle the global default state
* Add or remove user overrides
* Add or remove group overrides

This satisfies the requirement to support runtime mutations while keeping evaluation logic isolated.

---

## Validation and Safety

* Feature keys are unique
* Overrides are uniquely constrained per feature and target
* Missing features safely evaluate to `false`
* Invalid operations fail explicitly

---

## Database

The system uses:

* `features` table
* `feature_overrides` table
* Indexes and constraints to ensure correctness and performance

---

## Tests

Unit tests focus on:

* Evaluation correctness
* Override precedence
* Edge cases such as missing features or overrides

Tests are written to reflect business rules rather than framework behavior.

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
* The engine is independent of application specific user or group models
* Admin access is trusted and authentication is out of scope

---

## Tradeoffs

* A simple web interface was chosen over a REST API or CLI for clarity
* No caching layer was added to keep behavior explicit within the time box
* Region based overrides were not implemented

---

## Known Limitations

* No region based overrides
* No caching or memoization for high throughput evaluation
* Basic UI without authentication

---

## What I Would Improve Next

* Add request scoped or in memory caching
* Introduce region based overrides as an additional precedence layer
* Expose a REST API for evaluation
* Add audit logging for override changes
* Add performance benchmarking

---

## References

The following resources informed the design and approach:

1. [https://martinfowler.com/articles/feature-toggles.html](https://martinfowler.com/articles/feature-toggles.html)
2. [https://developer.atlassian.com/platform/forge/feature-flags/concepts/](https://developer.atlassian.com/platform/forge/feature-flags/concepts/)
3. [https://12factor.net/config](https://12factor.net/config)
4. [https://www.flippercloud.io/docs/optimization](https://www.flippercloud.io/docs/optimization)
5. [https://blog.cloud66.com/how-to-add-feature-flags-to-your-ruby-on-rails-applications](https://blog.cloud66.com/how-to-add-feature-flags-to-your-ruby-on-rails-applications)
6. [https://dev.to/ackshaey/feature-flags-in-rails-how-to-roll-out-and-manage-your-features-like-a-pro-1l7](https://dev.to/ackshaey/feature-flags-in-rails-how-to-roll-out-and-manage-your-features-like-a-pro-1l7)

