# TESORIN

TESORIN is a goal-first personal finance operating system that turns a user’s cashflow, net worth,
and behavior into prioritized next actions — not charts.

## Core philosophy

Most finance apps:

* Track expenses
* Show charts
* Stop there

TESORIN:

* Understands structure
* Understands constraints
* Recommends what to do next

TESORIN is not a tracker.
TESORIN is a thinking layer on top of financial data.

## The Core Loop (non-negotiable)

This is the heart of the app:

INPUT → CLARITY → PLAN → ACTION → FEEDBACK → UPDATE

Mapped to features:

| Step     | Meaning                                    |
|----------|--------------------------------------------|
| INPUT    | Profile, cashflow, net worth, goals        |
| CLARITY  | Monthly breathing room, net worth snapshot |
| PLAN     | What matters now                           |
| ACTION   | Concrete steps (cut X, fund Y, wait Z)     |
| FEEDBACK | Progress & friction detection              |
| UPDATE   | Re-run plan automatically                  |

## App Navigation (Android-native)

Bottom Navigation (3 items only)

This is correct and Android-native:

[ Wallet ]   [ HOME ]   [ Goals ]

No side nav. No clutter.

## HOME (The Brain)

This is one screen, vertically scrollable.

### Section 1 — Monthly Cashflow Summary

**Purpose:** “Can I breathe?”

**Shows:**

* Monthly income
* Monthly expenses
* Monthly surplus / deficit
* One sentence interpretation

**Example:**

“You have ~$1,120 of monthly flexibility.”

**CTA:**

* Add transaction → Wallet

### Section 2 — Net Worth Snapshot

**Purpose:** “Where do I stand?”

**Shows:**

* Total assets
* Total liabilities
* Net worth

**CTA:**

* ➜ opens Net Worth page (not modal)

### Section 3 — Goals Progress

**Purpose:** “Am I moving forward?”

**Shows:**

* 1–3 goals only
* % funded or time remaining

**CTA:**

* ➜ Goals page

### Top-Right Icons

* 🔔 Action button (blinks if action required)
* 👤 Profile

## WALLET (Cashflow Engine)

**Purpose:** Truth of behavior

**Features:**

* Add transaction (expense = negative, income = positive)
* Categories
* Notes
* Monthly roll-up

**Important:**

* Wallet feeds everything
* No budgeting envelopes initially
* Behavior first, optimization later

## NET WORTH (Structural Reality)

**Purpose:** Constraints & leverage

**Assets:**

* Cash
* Bank
* Investments
* Property

**Liabilities:**

* Credit cards
* Loans
* Mortgage

**Rules:**

* Simple first
* Rough numbers allowed
* Precision can come later

**Net worth updates:**

* Dashboard
* Retirement picture
* Risk profile

## PROFILE (Deep, thoughtful, strategic)

This is where TESORIN becomes powerful.

Not just:

* Country
* Income

But also:

* Employment stability
* Family obligations
* Risk comfort
* Time horizon
* Life phase (building / stabilizing / protecting)

These answers feed:

* Planning engine
* Action prioritization
* Tone of recommendations

## ACTIONS (The Differentiator)

This is TESORIN’s edge.

Actions are generated from:

* Cashflow stress
* Recurring expense waste
* Goal conflicts
* Net worth imbalance

**Examples:**

* “You’re paying for 3 streaming services — save $41/mo”
* “Your emergency fund covers only 1.4 months”
* “Delay investing; fix cashflow first”

**No overwhelm:**

* Max 3 actions
* Clear “why”
* Clear “impact”

## ENGINES (Technology-agnostic)

You already designed this correctly.

Think of these as pure logic modules, regardless of language:

* **Cashflow Engine**
    * Monthly surplus
    * Burn rate
    * Variability
* **Recurring Detection Engine**
    * Finds silent drains
    * Flags discretionary leakage
* **Net Worth Engine**
    * Balance sheet health
    * Leverage risk
* **Planning Engine (Orchestrator)**
    * Decides priority
    * Resolves conflicts
    * Chooses next action
* **Goals Engine (later)**
    * Feasibility
    * Tradeoffs
    * Timeline realism



