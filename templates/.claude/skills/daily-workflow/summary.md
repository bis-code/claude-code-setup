# /summary

Show a consolidated view of all work completed during the current day.

## What This Skill Does

1. Reads the daily state file(s) for today
2. Aggregates completed items across all `/plan-day` sessions
3. Shows pending/active items still in progress
4. Allows developer to verify each completed item
5. Optionally shows time tracking and pivots

## Multi-Repo Project Tracking

A **project** can span multiple GitHub repos (tracked via `claw repos add`).
Daily state is stored in `~/.claw/daily/YYYY-MM-DD.md` - **one file for all your work**.

```
~/.claw/daily/2025-01-07.md   # All work across all tracked repos
```

This means:
- `/plan-day` aggregates issues from ALL tracked repos into one plan
- `/summary` shows ALL completed work across all repos
- Work on `frontend`, `backend`, `infra` repos appears in one summary

### Example Multi-Repo Day

```
📋 Daily Summary: 2025-01-07
════════════════════════════════════════════════════════════════════

✅ COMPLETED (5 items)
────────────────────────────────────────────────────────────────────
 myorg/frontend#42 - Add payment modal
      Completed: 10:30 | Billing

 myorg/backend#18 - Add payment webhook handler
      Completed: 12:00 | API

 myorg/frontend#55 - Update checkout flow
      Completed: 14:30 | UI

 myorg/infra#12 - Configure Stripe webhook endpoint
      Completed: 15:00 | DevOps
```

All repos tracked via `claw repos add` are included.

## Invocation

```
/summary                  # Show today's summary
/summary --verify         # Interactive verification mode
/summary --date 2025-01-06 # Show specific date
/summary --week           # Show this week's summary
```

---

## Output Format

### Basic Summary

```
📋 Daily Summary: 2025-01-07
════════════════════════════════════════════════════════════════════

✅ COMPLETED (5 items)
────────────────────────────────────────────────────────────────────
 #42 - Add payment method update modal
      Completed: 10:30 | Session 1 | Billing
      Notes: Implemented with Stripe Elements, added 3D Secure

 #38 - Fix checkout validation
      Completed: 11:45 | Session 1 | Checkout
      Notes: Added edge case handling for expired cards

 #55 - Update dashboard layout
      Completed: 14:20 | Session 2 | UI
      Notes: Quick CSS fix

 #61 - Add license tier migration
      Completed: 15:30 | Session 2 | License
      Notes: Migration script with rollback support

 #63 - Fix typo in error message
      Completed: 16:00 | Session 2 | Quick fix

────────────────────────────────────────────────────────────────────

🔄 IN PROGRESS (1 item)
────────────────────────────────────────────────────────────────────
 #65 - API rate limiting
      Started: 16:15 | Est: 2h remaining

────────────────────────────────────────────────────────────────────

⏸️ DEFERRED (2 items)
────────────────────────────────────────────────────────────────────
 #58 - API key encryption (4h) → Tomorrow with full focus
 #47 - License sync → Blocked by external dependency

────────────────────────────────────────────────────────────────────

📊 STATS
────────────────────────────────────────────────────────────────────
 Sessions today: 2
 Items completed: 5
 Items deferred: 2
 Pivots made: 1
 Time logged: 6.5h
```

---

## Verification Mode

When run with `--verify`, allows interactive confirmation:

```
/summary --verify
```

Output:

```
📋 Verification Mode: 2025-01-07
════════════════════════════════════════════════════════════════════

Verify each completed item:

 1. #42 - Add payment method update modal
    🔴 HIGH PRIORITY - Billing changes
    → Stripe integration working?
    → Error handling tested?
    → 3D Secure flow verified?
    [y/n/skip] _

 2. #38 - Fix checkout validation
    🔴 HIGH PRIORITY - Revenue flow
    → Edge cases handled?
    → Error messages clear?
    [y/n/skip] _

 3. #55 - Update dashboard layout
    🟢 LOW PRIORITY - UI only
    → Visual check done?
    [y/n/skip] _

...

Verification complete: 5/5 items verified ✓
Ready to /ship-day
```

---

## Steps

### 1. Locate Daily File

```bash
# Today's state file (global - spans all tracked repos)
CLAW_HOME="${CLAW_HOME:-$HOME/.claw}"
STATE_FILE="$CLAW_HOME/daily/$(date +%Y-%m-%d).md"

# Check if exists
if [[ ! -f "$STATE_FILE" ]]; then
    echo "No daily plan found. Run /plan-day first."
    exit 1
fi
```

### 2. Parse Completed Items

Extract from the "Completed" section:

```markdown
### Completed
- [x] #42 - Add payment method update modal
  - status: done
  - completed: 10:30
  - session: 1
  - notes: Implemented with Stripe Elements
```

### 3. Parse In-Progress

Extract from "Active" section:

```markdown
### Active
- [ ] #65 - API rate limiting
  - status: in-progress
  - started: 16:15
```

### 4. Parse Deferred

Extract from "Deferred" section with reasons.

### 5. Calculate Stats

- Count sessions (look for "Session started" in log)
- Sum completed items
- Count pivots from "Pivots" section
- Calculate time if tracked

### 6. Display

Format output as shown above.

---

## Integration Points

| Skill | How /summary Uses It |
|-------|---------------------|
| `/plan-day` | Creates the state file that /summary reads |
| `/done` | Updates completed section that /summary displays |
| `/pivot` | Records pivots that /summary reports |
| `/ship-day` | Uses /summary data for PR description |
| `/validate` | /summary --verify runs validation checks |

---

## Weekly Summary

When run with `--week`:

```
/summary --week
```

Output:

```
📋 Weekly Summary: 2025-01-01 to 2025-01-07
════════════════════════════════════════════════════════════════════

Monday (01-01):     3 completed | 1 deferred
Tuesday (01-02):    5 completed | 0 deferred
Wednesday (01-03):  2 completed | 3 deferred (sick day)
Thursday (01-04):   4 completed | 1 deferred
Friday (01-05):     6 completed | 0 deferred
Saturday (01-06):   - (no work)
Sunday (01-07):     2 completed | 0 deferred (today)

────────────────────────────────────────────────────────────────────
WEEK TOTALS
────────────────────────────────────────────────────────────────────
 Total completed: 22 items
 Total deferred: 5 items
 Most productive: Friday (6 items)
 Categories: Billing (8), UI (6), API (5), Fixes (3)
```

---

## State File Location

Daily state files are stored in `~/.claw/daily/`:

```
~/.claw/daily/
├── 2025-01-05.md
├── 2025-01-06.md
└── 2025-01-07.md   # Today
```

The `/summary` command is **read-only** - it doesn't modify the state file.

To update state:
- Use `/done` to mark items complete
- Use `/pivot` to defer or change plans
- Use `/ship-day` to archive the day

---

## Error Handling

| Scenario | Response |
|----------|----------|
| No daily file | "No daily plan found. Run /plan-day first." |
| Empty completed | "Nothing completed yet today. Keep going!" |
| Parse error | "Could not parse state file. Check format." |
| Date not found | "No records for [date]. Available: [list dates]" |

---

## Tips

- Run `/summary` before `/ship-day` to review
- Use `--verify` for high-stakes changes
- Weekly view helps spot patterns
- Export to standup notes with `--format markdown`
