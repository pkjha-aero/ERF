#!/usr/bin/env python3
"""Generate ERF_Version.H from Source/ERF_Version.H.in.

This is invoked by *both* the CMake build (CMake/ERFGitVersion.cmake) and the
GNU Make build (Exec/Make.ERF) so the two paths stamp identical version
metadata into the binary.  See IMPROVEMENTS_SCOPE.md item 0.1.

The output is written only when its contents change, so an unchanged git state
does not force a rebuild of the translation units that include the header.
Every git call is best-effort: a source tree with no .git (release tarball,
Spack staging, container build context) still produces a valid header whose
git fields read "unknown".
"""

import argparse
import os
import subprocess
import sys
from datetime import datetime, timezone

_PLACEHOLDERS = (
    "ERF_VERSION",
    "ERF_GIT_DESCRIBE",
    "ERF_GIT_SHA",
    "ERF_GIT_DIRTY",
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


def _resolve(source_dir):
    inside_tree = _git(source_dir, "rev-parse", "--is-inside-work-tree") == "true"
    if not inside_tree:
        return "unknown", "unknown", "false"

    describe = _git(source_dir, "describe", "--tags", "--always", "--dirty") or "unknown"
    sha = _git(source_dir, "rev-parse", "HEAD") or "unknown"
    dirty = "true" if _git(source_dir, "status", "--porcelain") else "false"
    return describe, sha, dirty


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--template", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--source-dir", required=True)
    parser.add_argument("--project-version", default="0.0.0")
    parser.add_argument("--cxx-compiler", default="unknown")
    parser.add_argument("--amrex-version", default="unknown")
    args = parser.parse_args(argv)

    describe, sha, dirty = _resolve(args.source_dir)

    with open(args.template, "r", encoding="utf-8") as handle:
        text = handle.read()

    values = {
        "ERF_VERSION": args.project_version.strip() or "0.0.0",
        "ERF_GIT_DESCRIBE": describe,
        "ERF_GIT_SHA": sha,
        "ERF_GIT_DIRTY": dirty,
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
