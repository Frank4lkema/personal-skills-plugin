---
name: feature-story
description: >
  Use when you want to pick up and fully ship a Shortcut *feature* story end-to-end
  (build new functionality), typically via `/feature-story <story-id>`. Triggers on a
  new feature, enhancement, or user story to implement — not a bug fix.
disable-model-invocation: true
argument-hint: "[story-id]"
allowed-tools: >
  Read, Grep, Glob, Edit, Write, Task, Skill,
  Bash(git *), Bash(gh *), Bash(plannotator:*),
  Bash(bin/rails *), Bash(rails *), Bash(bundle *), Bash(rspec *),
  Bash(npm run:*), Bash(npm test:*), Bash(pnpm *), Bash(yarn *),
  Bash(curl *), Bash(jq *)
---

# Feature Story

End-to-end workflow voor één Shortcut **feature**-story: van ophalen tot vastleggen
in Obsidian.

De story-id is **$ARGUMENTS**.

## Uitvoeren

Lees de gedeelde workflow en volg die stappen **ongewijzigd**, waarbij je overal
`<STORY_ID>` vervangt door `$ARGUMENTS`:

**Lees:** `../_shared/story-base.md` (relatief aan deze skill-map — het bestand
`skills/_shared/story-base.md` in deze plugin, naast deze skill-folder).

Feature-story = de gedeelde basis zoals hij is:

1. Story ophalen via de **`shortcut-story-api`-skill** (REST API — géén browser)
2. Analyseren en uitleggen (Explore-subagent)
3. Plan opstellen via **Plannotator** (annotate → verwerken → akkoord)
4. Branch aanmaken uit Shortcut (moet `/sc-$ARGUMENTS/` bevatten)
5. Plan uitvoeren (multi-agent subagents)
6. Self-review via **Plannotator Review**
7. Pull request maken
8. Wachten op Greptile
9. Greptile-comments verwerken
10. Nieuwe route? → PO-rechten onder de story
11. Testen op localhost (subagent)
12. Vastleggen in Obsidian (type: feature)

> Er is **geen** stap 2b (validatie-script) — dat is alleen voor `bug-story`.
> Zet bij het Obsidian-logboek `Type: feature` en laat de "Validatie (alleen bug)"-sectie leeg.
