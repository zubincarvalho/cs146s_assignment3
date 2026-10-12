#!/usr/bin/env bash
# Fixed-cost survey of an unfamiliar repo. Read-only: prints facts, changes nothing.
# Usage: bash survey.sh [repo-root]   (defaults to the current directory)
set -u
cd "${1:-.}" || exit 1
root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not a git repository: $PWD"; exit 1; }
cd "$root" || exit 1

section() { printf '\n== %s ==\n' "$1"; }

section "Repo"
echo "root: $root"
echo "remote: $(git remote get-url origin 2>/dev/null || echo none)"
echo "branch: $(git rev-parse --abbrev-ref HEAD)   commits: $(git rev-list --count HEAD 2>/dev/null)"
echo "tracked files: $(git ls-files | wc -l | tr -d ' ')"
[ "$(git rev-parse --is-shallow-repository)" = "true" ] && echo "clone: SHALLOW (history queries are incomplete)"
[ -n "$(git config --get remote.origin.promisor 2>/dev/null)" ] && echo "clone: PARTIAL (git log -L / blame fetch blobs on demand and can be very slow)"
dirty=$(git status --porcelain | wc -l | tr -d ' ')
echo "uncommitted paths: $dirty"

section "Contribution rules and agent instructions (read these before anything else)"
git ls-files | grep -iE '(^|/)(CONTRIBUTING|CODE_OF_CONDUCT|SECURITY|GOVERNANCE|MAINTAINERS|AGENTS|CLAUDE|DEVELOPMENT|HACKING)[^/]*$|(^|/)\.github/PULL_REQUEST_TEMPLATE|(^|/)\.(NO_AI|cursorrules)' | head -20
[ -n "$(git ls-files '.github/ISSUE_TEMPLATE' | head -1)" ] && echo ".github/ISSUE_TEMPLATE/ ($(git ls-files '.github/ISSUE_TEMPLATE' | wc -l | tr -d ' ') templates)"
for f in $(git ls-files | grep -iE '(^|/)CONTRIBUTING[^/]*$' | head -3); do
  echo "-- headings in $f ($(wc -l < "$f" | tr -d ' ') lines)"
  # Skip fenced code blocks so shell comments are not mistaken for headings.
  awk '/^[[:space:]]*```/ { fence = !fence; next } !fence && /^#{1,2} / { print NR": "$0 }' "$f" | head -25
done

section "Build and test manifests"
git ls-files | grep -E '(^|/)(pyproject\.toml|setup\.py|setup\.cfg|tox\.ini|noxfile\.py|requirements[^/]*\.txt|uv\.lock|poetry\.lock|package\.json|pnpm-workspace\.yaml|pnpm-lock\.yaml|yarn\.lock|Cargo\.toml|go\.mod|Makefile|justfile|Taskfile\.ya?ml|CMakeLists\.txt|build\.gradle[^/]*|pom\.xml|Gemfile|composer\.json|\.pre-commit-config\.yaml)$' | awk -F/ 'NF<=2' | head -30

section "CI (what the maintainers actually run)"
git ls-files '.github/workflows' '.gitlab-ci.yml' '.circleci' 2>/dev/null | head -20

section "Tools this repo expects: on PATH?"
# A tool counts as expected if its manifest exists, or (for Python tools) the docs or config name it.
expects() {
  case "$1" in
    make) [ -f Makefile ] ;;
    just) [ -f justfile ] ;;
    node|npm) [ -f package.json ] ;;
    pnpm) [ -f pnpm-lock.yaml ] ;;
    yarn) [ -f yarn.lock ] ;;
    bun) [ -f bun.lockb ] || [ -f bun.lock ] ;;
    cargo) [ -f Cargo.toml ] ;;
    go) [ -f go.mod ] ;;
    gradle) ls build.gradle* >/dev/null 2>&1 ;;
    mvn) [ -f pom.xml ] ;;
    *) git grep -qIwF "$1" -- ':(glob)*.md' ':(glob)*.toml' ':(glob)*.cfg' ':(glob)*.ini' 2>/dev/null ;;
  esac
}
for t in hatch uv poetry pdm tox nox pytest ruff pre-commit make just node npm pnpm yarn bun cargo go gradle mvn; do
  if expects "$t"; then
    if command -v "$t" >/dev/null 2>&1; then echo "$t: yes"; else echo "$t: MISSING"; fi
  fi
done
echo "(checked against the current PATH; activate the project's environment first if it has one)"

section "Top-level layout (tracked files per directory)"
git ls-files | awk -F/ '{ if (NF>1) d[$1]++; else d["(root)"]++ } END { for (k in d) printf "%6d  %s\n", d[k], k }' | sort -rn | head -20

section "Largest second-level directories"
git ls-files | awk -F/ 'NF>2 { d[$1"/"$2]++ } END { for (k in d) printf "%6d  %s\n", d[k], k }' | sort -rn | head -10

section "Last 15 commit subjects (the real commit-message convention)"
git log -n 15 --format='%ad  %s' --date=short
