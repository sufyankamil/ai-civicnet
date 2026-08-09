#!/usr/bin/env python3
"""Generate user-facing App Store release notes from git commit subjects.

Rewrites technical commit messages into short product-language bullets,
updates CHANGELOG.md ## Unreleased, and writes Fastlane release_notes.txt.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

SKIP_TYPES = {
    "chore",
    "ci",
    "test",
    "tests",
    "build",
    "style",
    "docs",
    "doc",
}

SKIP_PATTERNS = [
    re.compile(r"^merge\b", re.I),
    re.compile(r"^wip\b", re.I),
    re.compile(r"gitignore", re.I),
    re.compile(r"\breadme\b", re.I),
    re.compile(r"workflow", re.I),
    re.compile(r"fastlane", re.I),
    re.compile(r"testflight", re.I),
    re.compile(r"github actions?", re.I),
    re.compile(r"\bci\b", re.I),
    re.compile(r"secrets?", re.I),
    re.compile(r"provisioning", re.I),
    re.compile(r"certificate", re.I),
    re.compile(r"changelog", re.I),
    re.compile(r"\bpubspec\b", re.I),
    re.compile(r"bump.*(version|build)", re.I),
    re.compile(r"\blogic\b", re.I),
    re.compile(r"\benc\b", re.I),
    re.compile(r"\btighten\b", re.I),
]

# Whole-message topic shortcuts → polished product bullets
TOPIC_NOTES = [
    (
        re.compile(r"(encrypt|\benc\b|e2e|private messag|chat.*(secur|priv)|secur.*chat)", re.I),
        "Stronger privacy for your chats",
    ),
    (
        re.compile(r"(rls|privacy protect|row.?level)", re.I),
        "Stronger account and data privacy",
    ),
    (
        re.compile(r"(notif)", re.I),
        "More reliable notifications",
    ),
    (
        re.compile(r"(match|discover|nearby)", re.I),
        "Better matching with people nearby who can help",
    ),
    (
        re.compile(r"(map|locat|gps)", re.I),
        "Improved map and location experience",
    ),
    (
        re.compile(r"(login|sign.?in|auth|password)", re.I),
        "Smoother and more reliable sign-in",
    ),
    (
        re.compile(r"(crash|stability|perf|performance|speed)", re.I),
        "Improved speed and stability",
    ),
]

TECH_REPLACEMENTS = [
    (re.compile(r"\brls\b", re.I), "privacy"),
    (re.compile(r"\be2e\b", re.I), ""),
    (re.compile(r"\benc(ryption|rypt(ed|ion)?)?\b", re.I), "privacy"),
    (re.compile(r"\bsupabase\b", re.I), ""),
    (re.compile(r"\bapi\b", re.I), ""),
    (re.compile(r"\bui\b", re.I), "design"),
    (re.compile(r"\bux\b", re.I), "experience"),
    (re.compile(r"\brefactor(ed|ing)?\b", re.I), "improvements"),
    (re.compile(r"\bnull\s*check\b", re.I), "stability"),
    (re.compile(r"\bharden\b", re.I), "improved"),
    (re.compile(r"\btighten(ed)?\b", re.I), "improved"),
    (re.compile(r"\bupdated?\b", re.I), "improved"),
]

TYPE_PREFIX = re.compile(
    r"^(?P<type>feat|fix|bugfix|improve|improvement|enhancement|refactor|perf|"
    r"chore|ci|docs?|test|build|style|release)(?:\([^)]*\))?:\s*",
    re.I,
)


def run_git(*args: str) -> str:
    return subprocess.check_output(["git", *args], text=True).strip()


def last_released_commit(changelog: Path) -> str | None:
    if not changelog.exists():
        return None
    text = changelog.read_text(encoding="utf-8")
    m = re.search(
        r"^##\s+(?!Unreleased)(.+?)\s+-\s+(\d{4}-\d{2}-\d{2})\s*$",
        text,
        re.M,
    )
    if not m:
        return None
    date = m.group(2)
    try:
        return run_git("rev-list", "-n", "1", f"--before={date} 00:00:00", "HEAD")
    except subprocess.CalledProcessError:
        return None


def collect_subjects(since_ref: str | None, max_count: int) -> list[str]:
    args = ["log", f"--max-count={max_count}", "--pretty=format:%s", "--no-merges"]
    if since_ref:
        args.append(f"{since_ref}..HEAD")
    else:
        args.append("HEAD")
    out = run_git(*args)
    if not out:
        return []
    return [line.strip() for line in out.splitlines() if line.strip()]


def strip_technical(raw: str) -> str | None:
    original = raw.strip()
    msg = original
    msg = re.sub(r"\s*\(#\d+\)\s*$", "", msg)
    msg = re.sub(r"\s*\[skip ci\]\s*", " ", msg, flags=re.I)
    msg = re.sub(r"`[^`]+`", " ", msg)
    msg = re.sub(
        r"\b[\w./-]+\.(dart|ts|tsx|js|swift|kt|java|py|sh|rb|yml|yaml|md|plist|p12|p8)\b",
        " ",
        msg,
    )

    commit_type = None
    m = TYPE_PREFIX.match(msg)
    if m:
        commit_type = m.group("type").lower()
        if commit_type in SKIP_TYPES:
            return None
        msg = msg[m.end() :]

    msg = msg.strip(" -:")
    if not msg:
        return None

    # Prefer curated product bullets for common topics
    for pat, note in TOPIC_NOTES:
        if pat.search(original) or pat.search(msg):
            return note

    for pat in SKIP_PATTERNS:
        if pat.search(msg):
            return None

    for pat, repl in TECH_REPLACEMENTS:
        msg = pat.sub(repl, msg)

    msg = re.sub(r"\s+", " ", msg).strip(" -:")
    msg = re.sub(r"\b(\w+)(?:\s+\1\b)+", r"\1", msg, flags=re.I)  # dedupe repeated words
    if len(msg) < 4:
        return None

    if re.search(r"\b(sql|rpc|jwt|oauth|uuid|sha|hmac|tls|http|xcconfig|enc)\b", msg, re.I):
        return None

    if commit_type in {"fix", "bugfix"}:
        if not re.match(r"^(fixed|improved|better|more)\b", msg, re.I):
            msg = "Improved " + msg[0].lower() + msg[1:]
    else:
        msg = msg[0].upper() + msg[1:]

    msg = re.sub(r"\b[Ii]mproved improved\b", "Improved", msg)
    msg = re.sub(r"\s+", " ", msg).strip()
    if len(msg) < 8:
        return None
    if len(msg) > 120:
        msg = msg[:117].rstrip() + "..."
    return msg


def dedupe(bullets: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for b in bullets:
        key = b.lower()
        if key in seen:
            continue
        seen.add(key)
        out.append(b)
    return out


def extract_dated_sections(text: str) -> str:
    parts = re.split(r"(?m)^(## (?!Unreleased).+)$", text)
    # parts[0] is preamble; then heading, body, heading, body...
    if len(parts) < 2:
        return ""
    dated = []
    i = 1
    while i + 1 < len(parts):
        heading = parts[i].strip()
        body = parts[i + 1]
        # Stop body at next section already handled by split
        dated.append(f"{heading}\n{body.rstrip()}\n")
        i += 2
    if i < len(parts) and parts[i].startswith("## "):
        dated.append(parts[i].rstrip() + "\n")
    return "\n".join(dated).rstrip() + ("\n" if dated else "")


def update_changelog_unreleased(changelog: Path, bullets: list[str]) -> None:
    body = "\n".join(f"- {b}" for b in bullets) + "\n"
    dated = ""
    if changelog.exists():
        dated = extract_dated_sections(changelog.read_text(encoding="utf-8"))

    text = (
        "# Changelog\n\n"
        "User-facing App Store “What’s New”. "
        "`## Unreleased` is generated automatically from recent commit messages "
        "(technical wording is rewritten for shoppers).\n\n"
        f"## Unreleased\n\n{body}"
    )
    if dated:
        text += f"\n{dated}"
        if not text.endswith("\n"):
            text += "\n"
    changelog.write_text(text, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--changelog", default="CHANGELOG.md")
    parser.add_argument("--out", default="ios/fastlane/metadata/en-US/release_notes.txt")
    parser.add_argument("--max-commits", type=int, default=40)
    parser.add_argument("--since", default=None, help="Git ref to start after (optional)")
    args = parser.parse_args()

    root = Path.cwd()
    changelog = root / args.changelog
    out = root / args.out

    since = args.since or last_released_commit(changelog)
    subjects = collect_subjects(since, args.max_commits)

    bullets: list[str] = []
    for subj in subjects:
        rewritten = strip_technical(subj)
        if rewritten:
            bullets.append(rewritten)
    bullets = dedupe(bullets)[:8]

    if not bullets:
        bullets = ["Bug fixes and performance improvements"]

    update_changelog_unreleased(changelog, bullets)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(f"- {b}" for b in bullets) + "\n", encoding="utf-8")

    print(f"Commits scanned: {len(subjects)} (since {since or 'recent history'})")
    print("Generated release notes:")
    print("-----")
    print(out.read_text(encoding="utf-8").rstrip())
    print("-----")
    return 0


if __name__ == "__main__":
    sys.exit(main())
