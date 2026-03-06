# Private Source -> Public Site Setup

Use this if you want to keep drafts/notes/private files in a private repository while continuing to publish the live site publicly.

## Target model
- Private repo: `architecture-to-autonomy-source` (authoring + internal files)
- Public repo: `architecture-to-autonomy` (publish-only static site)

## What is already set up in this public repo
- GitHub Pages deploy now publishes only the explicit allowlist from `publish-allowlist.txt`.
- Workflow builds a clean bundle in `_site/` before deploy.
- Workflow has a basic secret-pattern guard.

## One-time steps (GitHub)
1. Create a new private repository (example: `architecture-to-autonomy-source`).
2. Copy this codebase into that private repo as your working source.
3. In the private repo, add a fine-grained PAT secret named `PUBLIC_REPO_TOKEN`:
   - Scope: only the public site repository.
   - Permission: `Contents: Read and write`.
4. In the public repo, set branch protection on `main`:
   - Require pull request (optional but recommended).
   - Restrict who can push (recommended).

## Private repo publish workflow (add in private repo)
Create `.github/workflows/publish-public-site.yml` in the private repo:

```yaml
name: Publish Public Site

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout source repo
        uses: actions/checkout@v4

      - name: Build publish bundle
        shell: pwsh
        run: ./scripts/build_publish_bundle.ps1

      - name: Push bundle to public repo
        env:
          TARGET_REPO: code4freedom/architecture-to-autonomy
          TARGET_BRANCH: main
          TOKEN: ${{ secrets.PUBLIC_REPO_TOKEN }}
        shell: bash
        run: |
          set -euo pipefail
          workdir="$(mktemp -d)"
          git clone "https://x-access-token:${TOKEN}@github.com/${TARGET_REPO}.git" "$workdir"
          rm -rf "$workdir"/*
          cp -R _site/. "$workdir"/
          cd "$workdir"
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add .
          if git diff --cached --quiet; then
            echo "No publish changes."
            exit 0
          fi
          git commit -m "Publish from private source ${GITHUB_SHA}"
          git push origin "$TARGET_BRANCH"
```

## Notes
- This keeps non-allowlisted files out of the live site artifact.
- If you use the private-source workflow above, the public repo becomes publish-only content.
