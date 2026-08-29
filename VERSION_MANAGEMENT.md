# Version Management

## Single Source of Version Truth

ERF maintains a single version identity across both build systems (CMake and GNU Make) in the file **`version.txt`** at the repository root. This file contains a single line: the **planned development version** in semver format (e.g., `26.09.0`).

## How It Works

### `version.txt` — the Intended Release Version

- Contains the version **you are targeting**
- Read by both `CMakeLists.txt` and `Exec/Make.ERF` at build time
- Embedded in the binary as `erf_version::version`
- Appears in every `job_info` file written to outputs
- **Updated manually** when releasing or bumping the development target

### Git Tags — Historical Release Points

- Tags like `26.06`, `26.05`, etc., mark **past formal releases**
- ERF uses **lightweight tags** (not annotated), so use `git describe --tags` when querying locally
- `git describe --tags` shows how many commits (and which) have been added since the last tag
- Example: `26.06-466-g8bd85a801` means 466 commits after the `26.06` release
- Also embedded in binaries as `erf_version::git_describe` (build system automatically uses `--tags`)

### All Captured in `job_info`

Every output (plotfile, checkpoint) includes a Build Information section with:

```
ERF version (current development): 26.09.0          ← from version.txt (development target)
ERF describe (last release):       26.06-466-g...   ← from git describe (how far past last tag)
ERF branch:                        development      ← branch the code came from
ERF parent:                        main             ← parent/upstream branch
ERF git SHA:                       8bd85a80...      ← the exact commit that built it
```

This design lets you:
- Know what **version you intended** (`26.09.0`)
- Know how **mature that version is** (466 commits from the last release)
- Know which **branch** the code came from and its **parent branch**
- Trace back to the **exact commit** that produced any output
- Fully reproduce the code state from any output artifact

## Workflow

### Normal Development

1. Start with `version.txt` pointing to your target release (e.g., `26.09.0`)
2. Make commits as usual; `git describe --tags` will show tags + commit count
3. Write outputs; `job_info` captures both the target version and the commit identity

### Releasing

1. When code is ready to ship as version `X.Y.Z`:
   - Open a pull request to `development` with a commit that updates `version.txt`
     to the **next** development target (e.g., `X.Y+1.0` or `X+1.0.0`)
   - Get approval and merge to `development` (the branch is protected, so a PR is required)
2. After the merge, create and push the release tag on the merged commit:
   ```bash
   git checkout development && git pull origin development
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```
   Note: tags typically bypass branch protection rules. If push fails, check your repository's tag protection settings.
3. After this, `git describe --tags` will show commits relative to `vX.Y.Z`
4. The merged `version.txt` now identifies what you're building toward next

### Automation (Future)

Phase 3.4 of IMPROVEMENTS_SCOPE.md outlines automating version bumps using Conventional Commits + `release-please` or `git-cliff`, eliminating the manual update step.

## See Also

- [IMPROVEMENTS_SCOPE.md](IMPROVEMENTS_SCOPE.md) item 0.1 for implementation details
- [Source/ERF_Version.H.in](Source/ERF_Version.H.in) for the generated header template
- [CMake/ERFGitVersion.cmake](CMake/ERFGitVersion.cmake) for CMake integration
- [Exec/Make.ERF](Exec/Make.ERF) for GNU Make integration
