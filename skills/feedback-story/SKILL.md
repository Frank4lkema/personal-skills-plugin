---
name: feedback-story
description: >
  Use when you want to pick up a Shortcut *feedback* story — a request, remark or wish from
  a user, customer, PO or support — where you first check whether it fits a small scope
  before building anything, and may conclude that no code change is needed. Typically via a
  `feedback-story <story-id>` command. Triggers on user feedback, a small change request or
  a remark to follow up — not a planned feature and not a defect.
disable-model-invocation: true
argument-hint: "[story-id]"
---

# Feedback Story

Workflow voor één Shortcut **feedback**-story: een melding of wens van een gebruiker, klant,
PO of support. Gelijk aan de gedeelde basis, met **één extra stap (2b)**: eerst vaststellen
of dit binnen een **klein bestek** past, vóórdat er een plan komt.

Anders dan bij feature en bug hoeft dit **niet altijd code op te leveren**. Past het niet in
klein bestek, of is er helemaal geen wijziging nodig, dan eindigt de story hier met een
comment onder de story en een Obsidian-notitie — zie "Afslag" hieronder.

## Story-id

De story-id krijg je mee als argument bij het command (in Claude Code als `$ARGUMENTS`;
in Pi als de tekst die onder deze skill wordt toegevoegd). Gebruik die waarde overal waar
de basis-workflow `<STORY_ID>` schrijft. Ontbreekt de id of is hij niet eenduidig, vraag
er dan om voordat je begint.

## Uitvoeren

Lees de gedeelde workflow en volg die stappen:

**Lees:** `story-base.md` (in deze skill-map, naast dit bestand). Het is een
gegenereerde kopie van `skills/_shared/story-base.md` — wijzigingen horen in die bron.

Volgorde voor een feedback-story:

0. Hervatten-check — ligt er al werk voor deze story? (basis-stap 0)
1. Story ophalen via de **`shortcut-story-api`-skill** (REST API — géén browser)
2. Analyseren en uitleggen (read-only; met subagent indien beschikbaar) — richt de analyse
   op **wat de melder écht vraagt**, niet op de letterlijke formulering. Feedback is vaak
   een voorgestelde oplossing; zoek het onderliggende probleem.
3. **→ STAP 2b hieronder: scope-check (harde gate).** Hier splitst de route:
   - **Past in klein bestek** → door met stap 4 en verder.
   - **Te groot of geen wijziging nodig** → **Afslag** (zie onder): comment + Obsidian, klaar.
4. Plan opstellen via **Plannotator** (annotate → verwerken → akkoord)
5. Branch aanmaken uit Shortcut (moet `sc-<STORY_ID>` bevatten)
6. Plan uitvoeren (subagents indien beschikbaar, anders in de hoofdcontext) — **blijf binnen
   het bestek dat je in 2b hebt vastgesteld**. Loopt het tijdens de uitvoering alsnog uit,
   stop dan en neem de Afslag alsnog; maak het niet stilzwijgend groter.
7. Self-review via **Plannotator Review**
8. Pull request maken
9. Wachten op Greptile
10. Greptile-comments verwerken
11. Nieuwe route? → PO-rechten onder de story
12. Naar staging? → vragen of het gedeployed moet, op welk sprint-kanaal en onder welke naam
13. Testen — eerst vragen met welke gebruiker, daarna mij om een UI-check vragen
14. Vastleggen in Obsidian (type: feedback) — zet bij "Validatie / scope-check" de uitkomst
    van stap 2b, en bij "Uitkomst" `geïmplementeerd`.

---

## Stap 2b — Scope-check (harde gate vóór het plan)

Doel: **voorkomen dat een kleine melding stilletjes een groot project wordt.** Feedback komt
binnen als losse wens; het is niet aan mij om daar zelf een epic van te maken.

Bepaal op basis van stap 2 in welk van de drie bakjes deze story valt. Wees eerlijk — bij
twijfel is het **te groot**, want de PO kan altijd zeggen "doe toch maar".

### A. Geen wijziging nodig

Kies dit als één van deze waar is:

- Het gemelde gedrag **werkt zoals bedoeld** (en de melder verwachtte iets anders).
- Het is **dubbel** met een bestaande story of al opgelost.
- Het is een **productbeslissing**, geen technische kwestie — de PO moet eerst bepalen óf
  dit gewenst is.

→ Neem de **Afslag** hieronder.

### B. Te groot voor klein bestek

Kies dit als één van deze waar is:

- Er is een **schema-/migratiewijziging** of een wijziging in een **API-contract** nodig.
- Er moet een **nieuwe pagina, flow of route** bij, in plaats van iets bestaands aanpassen.
- Er is een **nieuwe dependency** of een **architectuurbeslissing** nodig.
- Het raakt **meerdere onderdelen, teams of lopende stories**.
- De acceptatiecriteria zijn zo onduidelijk dat je ze **zelf zou moeten verzinnen**.
- Je schat het werk op **meer dan ongeveer een dag** of op meer dan een handvol bestanden.

→ Neem de **Afslag** hieronder. Ga niet zelf refinen en ga geen plan schrijven.

### C. Past in klein bestek

Geen van de punten onder A of B is waar: het is een afgebakende aanpassing in bestaande code,
met duidelijke acceptatiecriteria.

→ Vat in twee of drie zinnen samen **wat je precies wel en niet gaat doen** (dat is het
bestek), bevestig dat kort met mij, en ga door naar basis-stap 3 (plan via Plannotator).
Bewaar die samenvatting voor het Obsidian-logboek.

**Harde gate:** ga niet naar het plan (basis-stap 3) zonder een expliciete uitkomst van deze
scope-check. Twijfel je tussen B en C, leg de keuze dan aan mij voor in plaats van hem zelf
te maken.

---

## Afslag — story eindigt zonder code (uitkomst A of B)

1. **Comment onder de story in Shortcut.** Houd het kort: één of twee regels, genoeg voor de
   PO om een beslissing te nemen. Geen implementatiedetails, geen analyse-samenvatting.
   - Uitkomst A: `Geen wijziging nodig: <reden in één zin>.`
   - Uitkomst B: `Past niet binnen klein bestek: <reden in één zin>. Nodig: <beslissing of refinement door de PO>.`
   - Via Shortcut MCP: gebruik de "add comment to story"-tool op story `<STORY_ID>`.
   - Fallback via API:
     ```bash
     curl -s -X POST \
       -H "Content-Type: application/json" \
       -H "Shortcut-Token: $SHORTCUT_API_TOKEN" \
       -d '{"text":"Past niet binnen klein bestek: <reden>. Nodig: <beslissing PO>."}' \
       "https://api.app.shortcut.com/api/v3/stories/<STORY_ID>/comments"
     ```
2. **Leg het vast in Obsidian** volgens basis-stap 13, met:
   - `Type: feedback`
   - `Uitkomst: geen wijziging — <A: werkt zoals bedoeld / dubbel / PO-beslissing, of B: te groot>`
   - `Branch: n.v.t.` en `PR: n.v.t.`
   - Onder "Validatie / scope-check": welke criteria uit 2b de doorslag gaven.
3. **Sla de stappen 4 t/m 13 over.** Geen branch, geen PR, geen staging-deploy, geen test.
4. **Rapporteer** aan mij: de uitkomst, de reden, de geplaatste comment en het pad van de
   Obsidian-notitie.

> Verandert de PO daarna van gedachten ("doe toch maar")? Dan start je de story opnieuw op —
> basis-stap 0 ziet dat er nog geen branch of PR is en je begint gewoon bij het plan.
