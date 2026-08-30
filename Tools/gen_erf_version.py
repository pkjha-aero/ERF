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
from datetime import datetime, timezone

_PLACEHOLDERS = (
    "ERF_VERSION",
    "ERF_GIT_SHA",
    "ERF_GIT_DIRTY",
    "ERF_GIT_BRANCH",
    "ERF_GIT_PARENT",
    "ERF_BUILD_DATE",
    "ERF_CXX_COMPILER",
    "ERF_AMREX_VERSION",
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


def _build_date():
    """ISO-8601 UTC build timestamp, honoring SOURCE_DATE_EPOCH."""
    epoch = os.environ.get("SOURCE_DATE_EPOCH")
    if epoch:
        try:
            dt = datetime.fromtimestamp(int(epoch), tz=timezone.utc)
        except (ValueError, OverflowError, OSError):
            dt = datetime.now(timezone.utc)
    else:
        dt = datetime.now(timezone.utc)
    return dt.strftime("%Y-%m-%dT%H:%M:%SZ")


def _parent_branch(source_dir, current_branch):
    """Best-effort parent of the current branch.

    Git does not record which branch a branch was created from, so this
    resolves in two steps:

      1. The configured upstream tracking ref, when there is one. That is the
         branch this one is set up to merge back into.
      2. Otherwise the local branch whose merge base with HEAD is nearest,
         which is what "branched off X" means in practice.

    Step 2 scans local branches only. A clone of a shared repository can carry
    hundreds of remote-tracking refs (ERF has 400+), and probing each one would
    add two git invocations per ref to every build.

    Returns "unknown" when neither step resolves, rather than naming a branch
    that was never consulted.
    """
    upstream = _git(source_dir, "rev-parse", "--abbrev-ref", "@{upstream}")
    if upstream:
        return upstream

    if current_branch == "unknown":
        return "unknown"

    best = None
    refs = _git(source_dir, "for-each-ref", "--format=%(refname:short)", "refs/heads")
    for ref in refs.splitlines():
        ref = ref.strip()
        if not ref or ref == current_branch:
            continue
        base = _git(source_dir, "merge-base", "HEAD", ref)
        if not base:
            continue
        distance = _git(source_dir, "rev-list", "--count", "{}..HEAD".format(base))
        if not distance.isdigit():
            continue
        # Nearest merge base wins; shorter then lexically smaller name breaks ties
        # so the result does not depend on ref enumeration order.
        candidate = (int(distance), len(ref), ref)
        if best is None or candidate < best:
            best = candidate

    return best[2] if best else "unknown"


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


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--source-dir", required=True)
    parser.add_argument("--cxx-compiler", default="unknown")
    parser.add_argument("--amrex-version", default="unknown")
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
        "ERF_BUILD_DATE": _build_date(),
        "ERF_CXX_COMPILER": args.cxx_compiler.strip() or "unknown",
        "ERF_AMREX_VERSION": args.amrex_version.strip() or "unknown",
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
