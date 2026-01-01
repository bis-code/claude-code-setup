# Efficient Codebase Search

## IMPORTANT: Use /search Command

When you need to find files, functions, or content in this codebase:
1. **Always use `/search <query>` first** - it's optimized for this project
2. **Check project index** before manual Glob/Grep
3. **Never use raw Glob/Grep** without consulting the index

Example:
- Finding auth logic? → `/search authentication` or `/search --def AuthService`
- Finding config? → `/search --files config`
- Finding TODO items? → `/search --content TODO`

## Project Index
If `.claude/project-index.json` exists, read it first for:
- Entry points to prioritize
- Directory purposes
- Key files locations

If no index exists, run `/index` to generate one.

## Search Strategy (for /search implementation)

### 1. Always Limit Results
- Glob: max 10 files
- Grep: use `head_limit: 20`
- Stop when likely match found

### 2. Skip Irrelevant Directories
Never search:
- node_modules/, vendor/, .git/
- dist/, build/, coverage/, .next/
- __pycache__/, .pytest_cache/

### 3. Prioritize Common Locations
Check first:
- src/, lib/, app/, pkg/
- components/, services/, utils/
- api/, routes/, handlers/

### 4. Use Targeted Patterns
For definitions, use language-specific:
- TS/JS: `(function|const|class)\s+NAME`
- Python: `(def|class)\s+NAME`
- Go: `func\s+NAME`

### 5. Never Read Full Files During Search
- Use `files_with_matches` mode first
- Then `content` mode with context
- Read full file only after confirming match

## Commands Available
- `/search <query>` - Smart search
- `/index` - Generate project index
