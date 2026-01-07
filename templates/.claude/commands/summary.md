# /summary - Daily Work Summary

Show consolidated view of all work completed today.

## Usage
- `/summary` - Show today's summary
- `/summary --verify` - Interactive verification mode
- `/summary --date 2025-01-06` - Show specific date
- `/summary --week` - Show this week's summary

## What It Shows
- All completed items across all `/plan-day` sessions
- In-progress items
- Deferred items with reasons
- Pivots made
- Time stats

## Verification Mode
Use `--verify` before `/ship-day` to confirm each item:
- High-priority items (billing, auth, license) flagged for extra review
- Interactive y/n confirmation for each

## Integration
- Reads from `.claude/daily/YYYY-MM-DD.md` state file
- Works with `/done` (updates completed), `/pivot` (records changes)
- Use before `/ship-day` to review day's work

See `.claude/skills/daily-workflow/summary.md` for full documentation.
