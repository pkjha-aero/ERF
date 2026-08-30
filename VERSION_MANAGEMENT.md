# Version Management

## The version is derived, never declared

ERF has **no version file**. The version is computed at build time from the repository
itself — `git describe --tags` — by `Tools/gen_erf_version.py`, which both build systems
(CMake and GNU Make) invoke, so the two can never disagree.

This is deliberate. Every other field in the build stamp (commit SHA, branch, build date,
compiler) is derived from repository or environment state and therefore cannot be wrong.
A hand-maintained version file would have been the single field capable of silently
rotting: nothing forces a human to update it, and nothing detects it when they don't.
The same reasoning underlies Bazel's `--workspace_status_command` stamping and tools like
`setuptools-scm` — build metadata should be a fact about the source, not an assertion
about it.

### What the version string means

```
26.06-471-gd483fdbbc
  │     │       │
  │     │       └─ abbreviated SHA of the commit actually built
  │     └─ commits since that tag
  └─ nearest release tag reachable from HEAD
```

Built exactly at a release tag, it is just `26.06`. Note the `g` is git's marker meaning
"a hash follows", not part of the SHA.

- ERF's release tags are **lightweight**, which plain `git describe` ignores — every call
  in the build and the commands below passes `--tags` for that reason.
- ERF tags are **CalVer** (`YY.MM`: `26.06` was cut 2026-06-09, `26.05` on 2026-05-07),
  so the version of a release is determined when it is cut, not planned in advance.
- Outside a git work tree (release tarball, Spack staging, container build context) the
  version reads `unknown`, as do `git_sha`, `git_branch` and `git_parent`. Nothing is
  guessed. If self-identifying tarballs become a requirement, git's `export-subst`
  attribute can substitute the describe string at `git archive` time.

### All Captured in `job_info`

Every output (plotfile, checkpoint) includes a Build Information section with:

```
ERF version (last release):        26.06-472-g...   ← git describe --tags
ERF branch (current):              version_mgmt     ← branch the code was built from
ERF parent (of current branch):    development      ← upstream, or nearest branch it forked from
ERF git SHA:                       0dcca5c729ea     ← commit that built it, abbreviated
AMReX git hash (last release):     26.07-54-g...    ← AMReX submodule identity
```

The `(last release)` in the version label names the **anchor** of the string — its leading
`26.06` — not the whole value. The trailing `-472-g0b28e9ad` says the build is 472 commits
past that release, at commit `0b28e9ad`.

### Changing how much of the hash is printed

`ERF git SHA:` prints 12 characters by default. The **full 40-character hash is always
retained** in the binary as `erf_version::git_sha` — the abbreviation is a display choice
only, so shortening it discards nothing.

One value controls every place ERF prints a hash (`job_info`, `--describe`, and the startup
banner). In [`Source/ERF_Version.H.in`](Source/ERF_Version.H.in):

```cpp
inline constexpr int sha_display_chars = 12;   // ← change this
```

Rebuild and all three sites follow. To print the complete hash at one particular site
instead, use the full value directly rather than changing the shared width:

```cpp
jobInfoFile << "ERF git SHA:  " << erf_version::git_sha       << "\n";  // all 40
jobInfoFile << "ERF git SHA:  " << erf_version::git_sha_short << "\n";  // abbreviated
```

Why 12 is the default:

- It matches what AMReX's own build info emits (`git describe --abbrev=12`), so the ERF
  and AMReX hashes in `job_info` are the same width and line up.
- Git would auto-select 9 characters for a repository of ERF's current size (~119k
  objects); 12 leaves generous headroom as history grows, while staying short enough to
  read at a glance and paste into a command.
- `git show`, `git log` and friends accept any unambiguous prefix, so a 12-character
  value pasted from `job_info` works directly.

`git_sha_short` is a `constexpr std::string_view`, so the abbreviation costs nothing at
runtime — no allocation, no copy. Its `substr` clamps rather than throws, so the `unknown`
placeholder from a non-git build passes through whole instead of being cut to `unknown`.

A dirty work tree is reported as `(dirty work tree)` after the version rather than as a
`-dirty` suffix inside it, so the version string stays clean and the state is stated once.

ERF's own git hash is not repeated below this block: the three `ERF ...` lines above
already carry it. Only AMReX's is echoed, because AMReX has no `erf_version` equivalent.

#### How `ERF parent:` is determined

Git does not record which branch a branch was created from, so the build resolves it
in two steps and reports `unknown` rather than guessing if neither applies:

1. **Upstream tracking ref**, when the branch has one — e.g. building on `development`
   that tracks `origin/development` reports `origin/development`.
2. **Nearest local branch**, otherwise — the local branch whose merge base with `HEAD`
   is fewest commits back. A topic branch cut from `development` reports `development`.

Step 2 deliberately scans **local branches only**. A clone of a shared repo can carry
hundreds of remote-tracking refs (ERF has 400+), and probing each would add two `git`
calls per ref to every build.

#### Inspecting the branch graph yourself

The heuristic above is a build-time stamp, not a substitute for looking at history.
Because ERF carries hundreds of branches across several remotes, a visual client makes
"where did this branch come from, and what has merged into it" far easier to answer
than reading `git log` output. Recommended:

| Tool | Platforms | Notes |
|---|---|---|
| [GitKraken](https://www.gitkraken.com/) | Linux, macOS, Windows | Clearest branch graph of the three; free tier covers public repos |
| [Sourcetree](https://www.sourcetreeapp.com/) | macOS, Windows | Free; good submodule handling, which matters for AMReX/RRTMGP/EKAT |
| [`git-gui` / `gitk`](https://git-scm.com/docs/gitk) | Anywhere git is | Ships with git, no install, adequate for a quick look |

VS Code's built-in Source Control view plus the **Git Graph** or **GitLens** extension
works well too, and keeps you in the editor you are already building from.

If you prefer the terminal, this shows the same thing without any install:

```bash
# Graph of your local branches only - readable even in a repo with 400+ remote refs
git log --graph --oneline --decorate --branches --not --remotes

# Commit where the current branch diverged from development
git merge-base development HEAD

# Commits on either side of that divergence
git log --graph --oneline --decorate development...HEAD

# Every local branch with its upstream, if any
git branch -vv
```

Use plain `git merge-base`, not `git merge-base --fork-point`. The `--fork-point` form
reads the reflog of the other branch, so it returns nothing for a branch you fetched
rather than created locally — which is the usual case for `development`.

Two things worth checking visually before you open a PR: that your branch actually
forked from `development` (not from an older tag or another topic branch), and that
`ERF parent:` in a fresh `job_info` agrees with what the graph shows. If they disagree,
the branch most likely has an upstream pointing somewhere unexpected — `git branch -vv`
shows it, including stale entries marked `gone`.

This design lets you:
- Know how **mature the build is** (commits since the last release)
- Know which **branch** the code came from and its **parent branch**
- Trace back to the **exact commit** that produced any output
- Fully reproduce the code state from any output artifact

## Workflow

### Normal development

Nothing to do. Commit as usual and the version follows automatically — there is no file
to bump and no step to forget. To see what a build would stamp:

```bash
git describe --tags
```

### Releasing

Cutting a release is **one action: creating the tag.** Because the version is derived,
tagging is what changes it; no accompanying source edit exists or is needed.

```bash
git checkout development && git pull
git tag 26.09          # CalVer YY.MM, matching 26.06, 26.05, ...
git push origin 26.09
```

Every subsequent build then reports `26.09-<n>-g<sha>` until the next tag. The tag goes on
a commit already merged into `development` — that branch is protected, so any code change
still arrives by pull request; the tag itself is pushed separately and does not go through
a PR. If your remote also protects tags, the push needs the corresponding permission.

Two conventions worth preserving, both currently observed by the repo:

- Tags are `YY.MM` with no `v` prefix, matching `26.06`, `26.05`, `25.12`.
- Tags are lightweight. If you switch to annotated tags (`git tag -a`), the `--tags`
  flags in this document and in the build become unnecessary but stay harmless.

### Automation (future)

A changelog generator such as `release-please` or `git-cliff` could produce `CHANGES`
entries from commit messages at tag time. There is no version bump left for it to
automate — that problem was removed rather than automated.

## See Also

- [Tools/gen_erf_version.py](Tools/gen_erf_version.py) for the header generator
- [Source/ERF_Version.H.in](Source/ERF_Version.H.in) for the generated header template
- [CMake/ERFGitVersion.cmake](CMake/ERFGitVersion.cmake) for CMake integration
- [Exec/Make.ERF](Exec/Make.ERF) for GNU Make integration
