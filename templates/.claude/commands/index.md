# /index - Generate Project Index

Generate a project index file for faster navigation.

## Usage
- `/index` - Generate index for current project
- `/index --update` - Update existing index
- `/index --show` - Show current index

## What It Does

Creates `.claude/project-index.json` containing:
1. Project structure overview
2. Key entry points
3. Important files and their purposes
4. Directory purposes

## Instructions

### 1. Analyze Project Structure
Use Glob to find key files:
```
**/package.json, **/Cargo.toml, **/go.mod, **/requirements.txt
**/src/index.*, **/src/main.*, **/src/app.*
**/README.md, **/CLAUDE.md
```

### 2. Identify Entry Points
Look for:
- Main files (index.ts, main.py, main.go)
- Config files (*.config.*, settings.*)
- API routes (routes/, api/, handlers/)
- Components (components/, views/, pages/)

### 3. Generate Index
Create `.claude/project-index.json`:
```json
{
  "name": "project-name",
  "type": "typescript|python|go|rust|...",
  "structure": {
    "src": "Source code",
    "tests": "Test files",
    "docs": "Documentation"
  },
  "entryPoints": {
    "src/index.ts": "Main entry point",
    "src/api/routes.ts": "API routes"
  },
  "keyFiles": [
    {"path": "src/config.ts", "purpose": "Configuration"},
    {"path": "src/types.ts", "purpose": "Type definitions"}
  ]
}
```

### 4. Save Index
Write to `.claude/project-index.json`
Add to .gitignore if not present

## Token Optimization

The index file is:
- Compact JSON (~50-100 lines)
- Loaded only when /search is used
- Updated on demand, not every session
- Contains pointers, not content

## Example Output

```
Project index generated: .claude/project-index.json

Summary:
- Type: TypeScript/React
- Entry: src/index.tsx
- 15 key directories mapped
- 8 entry points identified

Use /search to find files quickly.
```
