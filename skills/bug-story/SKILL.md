---
name: bug-story
description: >
  Use when you want to pick up and fully ship a Shortcut *bug* story end-to-end,
  where you first validate the root cause against real data before planning a fix.
  Typically via a `bug-story <story-id>` command. Triggers on a defect, regression, broken
  behavior, or incident to fix — not a new feature.
disable-model-invocation: true
argument-hint: "[story-id]"
---

# Bug Story

End-to-end workflow voor één Shortcut **bug**-story. Gelijk aan de gedeelde basis,
met **één extra stap (2b)**: eerst de oorzaak valideren met echte data via een
read-only Ruby-script — dat je wegschrijft in `script/` — vóórdat er een plan wordt gemaakt.

## Story-id

De story-id krijg je mee als argument bij het command (in Claude Code als `$ARGUMENTS`;
in Pi als de tekst die onder deze skill wordt toegevoegd). Gebruik die waarde overal waar
de basis-workflow `<STORY_ID>` schrijft. Ontbreekt de id of is hij niet eenduidig, vraag
er dan om voordat je begint.

## Uitvoeren

Lees de gedeelde workflow en volg die stappen:

**Lees:** `story-base.md` (in deze skill-map, naast dit bestand). Het is een
gegenereerde kopie van `skills/_shared/story-base.md` — wijzigingen horen in die bron.

Volgorde voor een bug-story:

0. Hervatten-check — ligt er al werk voor deze story? (basis-stap 0)
1. Story ophalen via de **`shortcut-story-api`-skill** (REST API — géén browser)
2. Analyseren en uitleggen (read-only; met subagent indien beschikbaar) — richt de analyse
   op de **oorzaak**, niet alleen het symptoom.
3. **→ STAP 2b hieronder: validatie met read-only Ruby-script (harde gate).**
4. Plan opstellen via **Plannotator** (annotate → verwerken → akkoord)
5. Branch aanmaken uit Shortcut (moet `sc-<STORY_ID>` bevatten)
6. Plan uitvoeren (subagents indien beschikbaar, anders in de hoofdcontext) — **alleen de
   bug fixen**, geen extra features/refactors tenzij nodig voor de fix.
7. Self-review via **Plannotator Review**
8. Pull request maken
9. Wachten op Greptile
10. Greptile-comments samen beoordelen en pas na mijn expliciete akkoord verwerken
11. Nieuwe route? → PO-rechten onder de story
12. Naar staging? → vragen of het gedeployed moet, op welk sprint-kanaal en onder welke naam
13. Testen — eerst vragen met welke gebruiker, daarna mij om een UI-check vragen
14. Vastleggen in Obsidian (type: bug) — plak de validatie-output in de
    "Validatie / scope-check"-sectie als bewijs, met het pad van het validatiescript erbij,
    en zet `Uitkomst: geïmplementeerd`.

---

## Stap 2b — Validatie met read-only Ruby-script (harde gate vóór het plan)

Doel: **zeker weten dat we de goede oorzaak te pakken hebben** vóórdat we een plan maken.

1. Formuleer op basis van stap 2 een concrete **hypothese** over de oorzaak
   (bv. "records X hebben veld Y leeg waardoor Z faalt").
2. Schrijf een **Ruby-class die alleen leest** en de hypothese toetst tegen echte data, en
   **schrijf die direct weg als bestand** — niet alleen als codeblok in de chat, want dan is
   het weg zodra de sessie eindigt en kan ik het niet zelf nog eens draaien.
   - **Pad:** `script/sc-<STORY_ID>-validatie.rb`. Heeft de repo al een eigen map voor losse
     scripts (`scripts/`, `lib/tasks/oneoffs`, …)? Gebruik die en houd je aan de naamgeving
     die er al staat. Is er niets? Maak `script/` aan.
   - **Uitsluitend lezen.** Alleen queries/reads + `puts`. **Nooit** schrijven, updaten,
     verwijderen, aanmaken of jobs enqueuen. Geen `save`, `update`, `destroy`, `create`,
     `delete`, `insert`, `perform`. Zo is het veilig om op productie te draaien.
   - **Op twee manieren bruikbaar:** draaibaar als bestand (`bin/rails runner
     script/sc-<STORY_ID>-validatie.rb`) én in zijn geheel plakbaar in een Rails console. Dus
     één zelfstandig blok dat zichzelf aanroept (bv. `class BugValidation ... end;
     BugValidation.new.run`), zonder afhankelijkheden buiten de app.
   - Print duidelijke, samenvattende output: aantallen, een paar voorbeeldrecords, en in
     gewone taal wat de hypothese bevestigt of ontkracht.
   - **Geen inline comments** in het script (zie de huisstijlregel in de basis) — laat de
     methodenamen en de `puts`-teksten het werk doen.
   - Moet de hypothese worden herzien? **Werk hetzelfde bestand bij**, geen `-v2` ernaast.
   - Het script hoort **niet in de PR-diff** tenzij ik er zelf om vraag: laat het untracked
     staan en `git add` het niet mee bij de fix. Het bewijs dat telt is de output, en die
     landt in Obsidian (stap 14).
3. Vraag de gebruiker het script te draaien en **de output terug te plakken**. Geef daarbij
   allebei de opties, zodat ik kan kiezen: het pad plus het `bin/rails runner`-commando, en
   het script in één codeblok om in de console op de server te plakken.
4. Beoordeel de output: **bevestigt** die de hypothese?
   - **Ja** → ga door naar het plan (basis-stap 3), en bewaar de output voor het
     Obsidian-logboek.
   - **Nee / onduidelijk** → pas de analyse/hypothese aan, herzie het script en herhaal.

**Harde gate:** stel **geen** plan op (basis-stap 3) voordat de teruggeplakte
validatie-output de hypothese bevestigt. Geen validatie = geen plan.
