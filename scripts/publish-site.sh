#!/usr/bin/env bash
# Publish web/ to the gh-pages branch, which is what psyto.github.io/confide actually serves.
#
#   ./scripts/publish-site.sh          # show what would change
#   ./scripts/publish-site.sh --push   # commit and push it
#
# There is no workflow doing this. On 2026-09-16 the decision page had been committed to main for
# hours and returned 404, because main is the source and gh-pages is the site, and nothing moved
# files between them. A page nobody can open is not a deliverable.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
WORK="${TMPDIR:-/tmp}/confide-gh-pages"

git fetch -q origin gh-pages
rm -rf "$WORK"
git worktree prune
git worktree add -q --detach "$WORK" origin/gh-pages

# Everything the site needs, named rather than globbed: a stray file in web/ should not silently
# become public.
FILES="index.html kamino.html mints.json proofs.json kamino-summary.json kamino-reserves.json capacity.json poster.jpg"
# kamino.json is 822K and the page reads two numbers out of it; the summary carries those.
for f in $FILES; do
  [ -f "web/$f" ] || { echo "  web/$f is missing — run the script that generates it" >&2; exit 1; }
  cp "web/$f" "$WORK/$f"
done

cd "$WORK"
git add -A                       # so new files show up; the dry run below reads the index, and
                                 # `git diff` alone hid three new pages on the first run of this
if git diff --cached --quiet; then
  echo "  gh-pages already matches web/ — nothing to publish"
  cd "$ROOT"; git worktree remove --force "$WORK"; exit 0
fi

echo "  changes to publish:"
git --no-pager diff --cached --stat | sed 's/^/    /'

if [ "${1:-}" = "--push" ]; then
  git -c user.name="$(git -C "$ROOT" config user.name)" \
      -c user.email="$(git -C "$ROOT" config user.email)" \
      commit -q -m "site: $(cd "$ROOT" && git log -1 --format=%h) — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  git push -q origin HEAD:gh-pages
  echo "  pushed to gh-pages"
  cd "$ROOT"; git worktree remove --force "$WORK"
else
  echo
  echo "  dry run. Re-run with --push to publish."
  cd "$ROOT"; git worktree remove --force "$WORK"
fi
