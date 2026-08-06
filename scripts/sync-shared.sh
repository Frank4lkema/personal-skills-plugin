#!/usr/bin/env bash
# Kopieert de gedeelde basis-workflow naar elke skill-map, zodat elke skill
# self-contained is (vereist voor installers als `npx skills` die alleen
# mappen mét een SKILL.md meenemen).
set -euo pipefail
cd "$(dirname "$0")/.."

src="skills/_shared/story-base.md"
header="<!-- GEGENEREERD uit ${src} — niet handmatig bewerken. Bewerk de bron en draai \`npm run sync\`. -->"

for skill in feature-story bug-story feedback-story; do
  { echo "$header"; echo; cat "$src"; } > "skills/${skill}/story-base.md"
  echo "sync: skills/${skill}/story-base.md"
done

# De drie versienummers moeten gelijk zijn: Claude Code detecteert updates op de
# versie in marketplace.json, Pi/npm op die in package.json.
version_of() { grep -m1 -o '"version": *"[^"]*"' "$1" | sed 's/.*"\([^"]*\)"$/\1/'; }
v_market=$(version_of .claude-plugin/marketplace.json)
v_plugin=$(version_of .claude-plugin/plugin.json)
v_pkg=$(version_of package.json)

if [ "$v_market" = "$v_plugin" ] && [ "$v_plugin" = "$v_pkg" ]; then
  echo "versie: $v_pkg (marketplace.json, plugin.json, package.json gelijk)"
else
  echo "FOUT: versies lopen uiteen —" >&2
  echo "  marketplace.json: $v_market" >&2
  echo "  plugin.json:      $v_plugin" >&2
  echo "  package.json:     $v_pkg" >&2
  echo "Bump alle drie naar dezelfde versie, anders zien gebruikers de update niet." >&2
  exit 1
fi
