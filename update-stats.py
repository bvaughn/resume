#!/usr/bin/env python3
"""Refreshes the npm download and GitHub star counts in index.html.

Each stat in the Open Source list is tagged with data-npm="<package>" or
data-github="<owner>/<repo>"; this script fetches the current numbers and
rewrites the displayed values in place.

Usage: ./update-stats.py
Set GITHUB_TOKEN to avoid GitHub's unauthenticated rate limit (60 requests/hour).
"""

import json
import os
import re
import sys
import urllib.request

INDEX = os.path.join(os.path.dirname(os.path.abspath(__file__)), "index.html")

# The displayed value sits between the icon's closing </svg> and the
# visually-hidden label, e.g. ...</svg\n  >6.5M<span class="visually-hidden">
STAT_PATTERN = re.compile(
    r'(data-(npm|github)="([^"]+)".*?</svg\s*>)([^<]*)(<span class="visually-hidden">)',
    re.S,
)


def fetch_json(url, headers=None):
    request = urllib.request.Request(url, headers={"User-Agent": "resume-stats", **(headers or {})})
    with urllib.request.urlopen(request, timeout=15) as response:
        return json.load(response)


def npm_weekly_downloads(package):
    return fetch_json(f"https://api.npmjs.org/downloads/point/last-week/{package}")["downloads"]


def github_stars(repo):
    headers = {"Accept": "application/vnd.github+json"}
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return fetch_json(f"https://api.github.com/repos/{repo}", headers)["stargazers_count"]


def format_count(n):
    """31_326_477 -> "31M", 6_540_874 -> "6.5M", 5_608 -> "5.6k", 399 -> "399"."""
    for divisor, suffix in ((1_000_000, "M"), (1_000, "k")):
        if n >= divisor:
            value = n / divisor
            text = f"{value:.1f}" if value < 10 else f"{value:.0f}"
            return text.removesuffix(".0") + suffix
    return str(n)


def main():
    with open(INDEX) as f:
        html = f.read()

    changes = []
    errors = []

    def replace(match):
        prefix, kind, source, old_value, suffix = match.groups()
        try:
            count = npm_weekly_downloads(source) if kind == "npm" else github_stars(source)
        except Exception as error:
            errors.append(f"{kind} {source}: {error}")
            return match.group(0)
        new_value = format_count(count)
        if new_value != old_value:
            changes.append(f"{kind} {source}: {old_value} -> {new_value}")
        return prefix + new_value + suffix

    updated, count = STAT_PATTERN.subn(replace, html)
    if count == 0:
        sys.exit("No tagged stats found in index.html")

    for line in changes:
        print(line)
    if updated != html:
        with open(INDEX, "w") as f:
            f.write(updated)
    print(f"Checked {count} stats, {len(changes)} changed")

    if errors:
        for line in errors:
            print(f"Failed to fetch {line}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
