#!/usr/bin/env python3
"""Generate ERF_Version.H from Source/ERF_Version.H.in.

This is invoked by *both* the CMake build (CMake/ERFGitVersion.cmake) and the
GNU Make build (Exec/Make.ERF) so the two paths stamp identical version
metadata into the binary.  See VERSION_MANAGEMENT.md.

The version is *derived*, never declared: it is `git describe --tags` against
the source tree, so it cannot drift from the code it labels. There is no
version file for anyone to hand-edit and forget.

The output is written only when its contents change, so an unchanged git state
does not force a rebuild of the translation units that include the header.
Every git call is best-effort: a source tree with no .git (release tarball,
Spack staging, container build context) still produces a valid header, with the
git-derived fields reading "unknown".
"""

import argparse
import os
import subprocess
import sys

_PLACEHOLDERS = (
    "ERF_VERSION",
    "ERF_GIT_SHA",
    "ERF_GIT_DIRTY",
    "ERF_GIT_BRANCH",
    "ERF_GIT_PARENT",
)


def _git(source_dir, *args):
    """Return stripped stdout of a git command, or "" on any failure."""
    try:
        out = subprocess.check_output(
            ["git", "-C", source_dir, *args],
            stderr=subprocess.DEVNULL,
        )
    except (OSError, subprocess.CalledProcessError):
        return ""
    return out.decode("utf-8", "replace").strip()


def _git_ok(source_dir, *args):
    """True when a git command exits zero.

    Needed for commands that answer through their exit status and print nothing,
    such as `merge-base --is-ancestor`, where _git cannot distinguish success
    from failure because both yield an empty string.
    """
    try:
        subprocess.check_call(
            ["git", "-C", source_dir, *args],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except (OSError, subprocess.CalledProcessError):
        return False
    return True


def _parent_branch(source_dir, current_branch):
    """Best-effort parent of the current branch.

    Git does not record which branch a branch was created from, so this resolves
    in two steps:

      1. The nearest local branch that HEAD descends from. Requiring an ancestor
         is what makes the answer meaningful: a topic branch cut from
         `development` reports `development`, while an unrelated topic branch,
         whose merge base is some ancient shared commit, is rejected outright --
         as is a branch that has already merged this one in, which is downstream
         rather than a parent. Among several ancestors the nearest wins, so a
         branch descending from both `main` and `development` reports the latter.
      2. Otherwise the configured upstream tracking ref. This is the answer for
         an integration branch like `development`, which by definition has no
         local branch above it, and whose real parent is the remote it tracks.

    Deliberately not the other order: a pushed topic branch tracks its own remote
    copy, so consulting the upstream first would answer `<remote>/<same-name>` --
    true but self-referential, and not the branch the work belongs to.

    Step 1 scans local branches only. A clone of a shared repository can carry
    hundreds of remote-tracking refs (ERF has 400+), and probing each one would
    add git invocations per ref to every build.

    Returns "unknown" when neither step resolves, rather than naming a branch
    that was never consulted.
    """
    best = None
    refs = _git(source_dir, "for-each-ref", "--format=%(refname:short)", "refs/heads")
    for ref in refs.splitlines():
        ref = ref.strip()
        if not ref or ref == current_branch:
            continue
        if not _git_ok(source_dir, "merge-base", "--is-ancestor", ref, "HEAD"):
            continue
        distance = _git(source_dir, "rev-list", "--count", "{}..HEAD".format(ref))
        if not distance.isdigit():
            continue
        # Nearest ancestor wins; shorter then lexically smaller name breaks ties
        # so the result does not depend on ref enumeration order.
        candidate = (int(distance), len(ref), ref)
        if best is None or candidate < best:
            best = candidate

    if best:
        return best[2]

    upstream = _git(source_dir, "rev-parse", "--abbrev-ref", "@{upstream}")
    return upstream or "unknown"


def _resolve(source_dir):
    inside_tree = _git(source_dir, "rev-parse", "--is-inside-work-tree") == "true"
    if not inside_tree:
        return "unknown", "unknown", "false", "unknown", "unknown"

    # --tags is required because ERF's release tags are lightweight, which plain
    # `git describe` ignores. --dirty is deliberately omitted: the dirty state is
    # reported separately as a boolean, and appending "-dirty" here as well would
    # print it twice on the same line.
    version = _git(source_dir, "describe", "--tags", "--always") or "unknown"
    sha = _git(source_dir, "rev-parse", "HEAD") or "unknown"
    dirty = "true" if _git(source_dir, "status", "--porcelain") else "false"
    branch = _git(source_dir, "symbolic-ref", "--short", "HEAD") or "unknown"
    parent = _parent_branch(source_dir, branch)
    return version, sha, dirty, branch, parent


def version_string(source_dir):
    """The derived version alone, for callers that need nothing else.

    Importable so that anything else describing this source tree -- the Sphinx
    configuration, for one -- reports the same version the build stamps into the
    binary, instead of reimplementing the git call and drifting from it.
    """
    return _resolve(source_dir)[0]


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--source-dir", required=True)
    args = parser.parse_args(argv)

    version, sha, dirty, branch, parent = _resolve(args.source_dir)

    with open(args.template, "r", encoding="utf-8") as handle:
        text = handle.read()

    values = {
        "ERF_VERSION": version,
        "ERF_GIT_SHA": sha,
        "ERF_GIT_DIRTY": dirty,
        "ERF_GIT_BRANCH": branch,
        "ERF_GIT_PARENT": parent,
    }
    for key in _PLACEHOLDERS:
        text = text.replace("@{}@".format(key), values[key])

    existing = None
    if os.path.exists(args.output):
        with open(args.output, "r", encoding="utf-8") as handle:
            existing = handle.read()

    if existing != text:
        out_dir = os.path.dirname(os.path.abspath(args.output))
        if out_dir:
            os.makedirs(out_dir, exist_ok=True)
        with open(args.output, "w", encoding="utf-8") as handle:
            handle.write(text)

    return 0


if __name__ == "__main__":
    sys.exit(main())
