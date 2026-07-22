---
name: feature-story
description: >
  Use when you want to pick up and fully ship a Shortcut *feature* story end-to-end
  (build new functionality), typically via a `feature-story <story-id>` command. Triggers
  on a new feature, enhancement, or user story to implement — not a bug fix.
disable-model-invocation: true
argument-hint: "[story-id]"
---

# Feature Story

End-to-end workflow voor één Shortcut **feature**-story: van ophalen tot vastleggen
in Obsidian.

## Story-id

De story-id krijg je mee als argument bij het command (in Claude Code als `$ARGUMENTS`;
in Pi als de tekst die onder deze skill wordt toegevoegd). Gebruik die waarde overal waar
de basis-workflow `<STORY_ID>` schrijft. Ontbreekt de id of is hij niet eenduidig, vraag
er dan om voordat je begint.

## Uitvoeren

Lees de gedeelde workflow en volg die stappen **ongewijzigd**:

**Lees:** `story-base.md` (in deze skill-map, naast dit bestand). Het is een
gegenereerde kopie van `skills/_shared/story-base.md` — wijzigingen horen in die bron.

Feature-story = de gedeelde basis zoals hij is:

1. Story ophalen via de **`shortcut-story-api`-skill** (REST API — géén browser)
2. Analyseren en uitleggen (read-only; met subagent indien beschikbaar)
3. Plan opstellen via **Plannotator** (annotate → verwerken → akkoord)
4. Branch aanmaken uit Shortcut (moet `sc-<STORY_ID>` bevatten)
5. Plan uitvoeren (subagents indien beschikbaar, anders in de hoofdcontext)
6. Self-review via **Plannotator Review**
7. Pull request maken
8. Wachten op Greptile
9. Greptile-comments verwerken
10. Nieuwe route? → PO-rechten onder de story
11. Testen op localhost
12. Vastleggen in Obsidian (type: feature)

> Er is **geen** stap 2b (validatie-script) — dat is alleen voor `bug-story`.
> Zet bij het Obsidian-logboek `Type: feature` en zet bij "Validatie (alleen bug)" `n.v.t.`.
