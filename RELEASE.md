# Release Checklist

Before releasing a new version of claw, complete all items in this checklist.

## Automated Checks (CI)

These run automatically on every PR and push:

- [ ] Unit tests pass (`./tests/bats/bin/bats tests/*.bats`)
- [ ] Integration tests pass
- [ ] Homebrew integration tests pass (`./test/homebrew-integration.sh --local`)
- [ ] Shellcheck passes (warnings allowed)

## Manual Verification

### 1. Local Testing

```bash
# Run the comprehensive integration tests
./test/homebrew-integration.sh --local
```

All 65+ tests should pass, covering:
- All CLI commands and flags
- All subcommands (repos, project, templates)
- Edge cases (special characters, spaces in paths)
- Path resolution (critical for Homebrew)

### 2. Build and Test Tarball

```bash
# Create tarball (simulates what Homebrew will install)
VERSION="X.Y.Z"
mkdir -p /tmp/claw-release/claw-$VERSION
cp -r bin lib templates /tmp/claw-release/claw-$VERSION/
cd /tmp/claw-release
tar -czvf claw-$VERSION.tar.gz claw-$VERSION
shasum -a 256 claw-$VERSION.tar.gz  # Save this hash!
```

### 3. Test Installed Binary

```bash
# Simulate Homebrew installation
mkdir -p /tmp/test-install/bin /tmp/test-install/lib/claw
tar -xzf claw-$VERSION.tar.gz
cp claw-$VERSION/bin/claw /tmp/test-install/bin/
cp -r claw-$VERSION/lib/* /tmp/test-install/lib/claw/
cp -r claw-$VERSION/templates /tmp/test-install/lib/claw/

# Apply Homebrew-style path rewrite
sed -i '' 's|LIB_DIR="${SCRIPT_DIR}/../lib"|LIB_DIR="/tmp/test-install/lib/claw"|' /tmp/test-install/bin/claw

# Test critical commands
export PATH="/tmp/test-install/bin:$PATH"
claw --version                    # Should show version
claw templates list               # CRITICAL: Must show templates
claw repos --help                 # Should show help
claw project --help               # Should show help
```

### 4. Verify Templates Path (Bug We Caught)

```bash
# This was the v1.3.0 -> v1.3.1 bug
claw templates list | grep -q "bug-report"
claw templates list | grep -q "claude-ready"
claw templates list | grep -q "feature-request"
claw templates list | grep -q "tech-debt"
```

If any template is missing, the path resolution is broken!

## Release Process

### 1. Update Version

```bash
# Update version in bin/claw
vim bin/claw  # Change VERSION="X.Y.Z"

# Update .release-please-manifest.json
echo '{"."": "X.Y.Z"}' > .release-please-manifest.json
```

### 2. Commit and Tag

```bash
git add -A
git commit -m "chore: bump version to X.Y.Z"
git push origin main
git tag vX.Y.Z
git push origin vX.Y.Z
```

### 3. Create GitHub Release

```bash
# Create tarball
cd /tmp/claw-release
gh release create vX.Y.Z claw-X.Y.Z.tar.gz \
  --title "vX.Y.Z" \
  --notes "Release notes here"
```

### 4. Update Homebrew Tap

```bash
# Get SHA256
SHA=$(shasum -a 256 claw-X.Y.Z.tar.gz | cut -d' ' -f1)

# Clone tap repo
git clone https://github.com/bis-code/homebrew-tap.git /tmp/homebrew-tap
cd /tmp/homebrew-tap

# Update formula
vim Formula/claw.rb
# Update: url, sha256, version

# Commit and push
git add Formula/claw.rb
git commit -m "claw X.Y.Z"
git push origin main
```

### 5. Verify Homebrew Update

```bash
brew update
brew upgrade claw
claw --version
claw templates list  # Verify templates work!
```

## Common Issues

### Templates Not Found After Install

**Symptom:** `claw templates list` shows "template not found locally"

**Cause:** Path resolution issue. The `issue-templates.sh` script looks for templates in the wrong location.

**Fix:** Ensure `lib/issue-templates.sh` checks both:
- `${SCRIPT_DIR}/templates/github-issue-templates` (Homebrew installed)
- `${SCRIPT_DIR}/../templates/github-issue-templates` (dev mode)

### Homebrew Shows Old Version

**Symptom:** `brew upgrade claw` says already installed with old version

**Cause:** Homebrew tap not updated

**Fix:**
1. Update Formula/claw.rb in homebrew-tap repo
2. Push to homebrew-tap
3. Run `brew update && brew upgrade claw`

## Version History

| Version | Date | Notable Changes |
|---------|------|-----------------|
| 1.3.1 | 2025-01-07 | Fix templates path for Homebrew |
| 1.3.0 | 2025-01-07 | Project-based multi-repo, comprehensive testing |
