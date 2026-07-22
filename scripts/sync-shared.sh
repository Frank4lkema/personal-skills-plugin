#!/usr/bin/env bash
# Kopieert de gedeelde basis-workflow naar elke skill-map, zodat elke skill
# self-contained is (vereist voor installers als `npx skills` die alleen
# mappen mét een SKILL.md meenemen).
set -euo pipefail
cd "$(dirname "$0")/.."

src="skills/_shared/story-base.md"
header="<!-- GEGENEREERD uit ${src} — niet handmatig bewerken. Bewerk de bron en draai \`npm run sync\`. -->"

for skill in feature-story bug-story; do
  { echo "$header"; echo; cat "$src"; } > "skills/${skill}/story-base.md"
  echo "sync: skills/${skill}/story-base.md"
done
