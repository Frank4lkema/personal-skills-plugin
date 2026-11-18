---
name: review-analyse
description: >
  Use when you want to analyse what the independent reviewer (and Greptile) found across
  finished stories and discuss the findings one at a time to extract learnings, typically via
  a `review-analyse [periode | story-ids]` command. Reads the `## Reviewer` and `## Greptile`
  sections of the Obsidian Dev Log notes written by the story workflows, clusters recurring
  findings, compares reviewer providers (Codex vs Claude) and records agreed learnings.
  Triggers on "wat vond de reviewer", "review-learnings", "analyseer de reviews". Read-only
  on code; never changes skills or repos without explicit approval.
disable-model-invocation: true
argument-hint: "[periode | story-ids]"
---

# Review-analyse

Ga door wat de onafhankelijke reviewer (en Greptile) bij afgeronde stories heeft gevonden, en
bespreek de punten **één voor één** met mij om te bepalen welke learning we eruit halen. Het
doel is niet om oude stories opnieuw te fixen, maar om te zien wat er structureel anders moet:
in de skills, in de projectafspraken of in hoe de hoofdagent werkt.

## Pas aan je harness aan

- **Hoofdagent:** doe het lezen, clusteren, analyseren en bespreken zelf in de hoofdcontext.
  Start geen subagents of reviewers; deze workflow heeft geen eigen reviewstap.
- **Vault-toegang:** gebruik de Obsidian MCP of de `obsidian-cli`-skill. Weet je het vaultpad
  niet, vraag het dan. Raad het niet.

## Niet onderhandelbare regels

- **Read-only op code en repo's.** Lees gerust de huidige code of git-historie om een
  bevinding te begrijpen, maar wijzig niets in een project-repo.
- **Eén punt tegelijk.** Ga pas naar het volgende punt als ik een besluit heb genomen. Een
  besluit over het ene punt geldt niet voor een volgend punt.
- **Geen wijziging aan skills of projectafspraken zonder expliciet akkoord** op de exacte
  tekst. Een besluit "learning overnemen" betekent: vastleggen in de learnings-notitie, nog
  niet de skill aanpassen.
- **Projectspecifiek blijft projectspecifiek.** Maak van één reviewvoorkeur in één repo geen
  universele regel in de gedeelde story-basis, tenzij het patroon in meerdere repo's terugkomt
  of ik dat expliciet kies.
- Commit of push niets zonder aparte expliciete toestemming.

## 1. Bereik bepalen

Het argument bepaalt welke stories meedoen:

| Argument | Bereik |
| --- | --- |
| leeg | alle Dev Log-notities met een `## Reviewer`-sectie die nog niet in een eerdere analyse zijn besproken |
| periode (`2w`, `sinds 2026-11-01`, `sprint11`) | notities waarvan de datum in die periode valt |
| story-ids (`123 sc-456`) | precies die stories |

Welke stories al besproken zijn, lees je uit eerdere notities in `Review Learnings/` (de
regel **Besproken stories** bovenaan elke notitie). Meld kort welk bereik je kiest en hoeveel
notities erin vallen.

## 2. Bevindingen ophalen

Zoek in de vault naar `Dev Log/sc-*.md` en lees per notitie:

- de sectie `## Reviewer`: per ronde provider/model, terugval, bevindingen, besluit, fix;
- de sectie `## Greptile`: per comment het besluit en de fix;
- de kopvelden (type, repo/branch, PR) en `## Geleerd / aandachtspunten`.

Notities zonder `## Reviewer`-sectie (van vóór de reviewlog) tel je mee als "geen reviewlog"
en sla je verder over. Raad niet wat de reviewer daar gevonden zou hebben.

## 3. Overzicht geven (nog geen besluiten)

Laat eerst één compact overzicht zien:

1. **Per story:** story, repo, reviewer (provider/model, terugval ja/nee), aantal bevindingen,
   hoeveel overgenomen / niet overgenomen / voorgelegd.
2. **Per reviewer-provider:** aantal rondes, bevindingen per ronde, percentage overgenomen,
   en hoe vaak er is teruggevallen op Claude en waarom. Trek hier geen harde conclusies uit
   bij kleine aantallen; zeg dat erbij.
3. **Greptile ná de reviewer:** welke Greptile-comments een probleem raakten dat de reviewer
   al had moeten zien. Dat zijn gemiste bevindingen en een belangrijke bron van learnings.
4. **Gebundelde punten:** cluster de bevindingen tot bespreekpunten. Eén punt is een
   terugkerend patroon (bijv. "ontbrekende test voor de lege-staat", "N+1 in index-views",
   "guard zonder foutscenario") of één opvallende losse bevinding. Sorteer op impact en
   frequentie. Nummer de punten.

Vraag of ik de volgorde wil aanpassen of punten wil overslaan, en begin pas daarna aan punt 1.

## 4. Punten één voor één bespreken

Geef per punt:

- **Wat er gevonden is:** de bevindingen zo letterlijk mogelijk uit de Dev Log, met story-id,
  reviewer-provider en `bestand:regel`.
- **Wat ermee gebeurde:** overgenomen of niet, en de reden die toen is vastgelegd.
- **Jouw analyse:**
  - had de reviewer gelijk, en was het besluit van de hoofdagent terecht?
  - waarom maakte de hoofdagent dit, of waarom zag hij het niet zelf: ontbrak een afspraak in
    de skill, stond het niet in het plan, of is het een projectconventie die niet vastligt?
  - is het een patroon of eenmalig?
- **Voorgestelde learning** met een concrete plek waar die moet landen:
  - de gedeelde story-basis (`skills/_shared/story-base.md`, bijv. bij "Ontwerp- en
    testafspraken uit collegiale reviews");
  - de projectafspraken van die repo (`CLAUDE.md`/`AGENTS.md` in de project-repo);
  - de reviewer-instructie in stap 6 (iets wat de reviewer extra moet toetsen);
  - geen actie: ruis, eenmalig of al opgelost.
  Geef de voorgestelde tekst letterlijk, kort en toetsbaar.

Vraag dan om mijn besluit: **overnemen**, **aanpassen** (met mijn formulering), **niet
overnemen** of **later**. Wacht op dat besluit.

## 5. Direct vastleggen in Obsidian

Leg elk besluit vast **zodra ik het heb genomen**, niet pas aan het eind. Gebruik één notitie
per analyse: `Review Learnings/<YYYY-MM-DD>.md`.

```markdown
# Review-analyse <YYYY-MM-DD>

- **Bereik:** <argument of "alles sinds vorige analyse">
- **Besproken stories:** sc-123, sc-456, …
- **Reviewers:** <bijv. codex/gpt-5.6-sol: 5 rondes, claude: 1 ronde (terugval: usage limit)>

## Punt 1 — <korte titel>
- **Gevonden in:** sc-123 (codex/gpt-5.6-sol), sc-456 (claude)
- **Bevinding(en):** <kort, met bestand:regel>
- **Analyse:** <waarom het gebeurde>
- **Learning:** <de letterlijke regel>
- **Plek:** <story-base | <repo>/CLAUDE.md | reviewer-instructie | geen>
- **Besluit:** <overnemen | aangepast | niet overnemen | later> — <reden>
- **Doorgevoerd:** <nee | ja — commit/pad>
```

Zet bovenaan **Besproken stories** pas op de definitieve lijst als alle punten zijn besproken;
stop ik halverwege, zet er dan `(onderbroken bij punt N)` achter, zodat een volgende analyse
weet waar hij verder moet.

## 6. Afronden en doorvoeren

Na het laatste punt:

1. Geef een korte samenvatting: welke learnings zijn overgenomen, per plek gegroepeerd.
2. Stel voor de overgenomen learnings per plek de concrete wijziging voor als diff of exacte
   tekst. Voer niets door voordat ik die tekst expliciet goedkeur.
3. Goedgekeurde wijzigingen in deze skills-repo: bewerk de bron (`skills/_shared/story-base.md`
   of de betreffende `SKILL.md`), draai `npm run sync`, bump de versie op alle drie de plekken
   en vraag apart of je mag committen en pushen.
4. Goedgekeurde wijzigingen in een project-repo: alleen op mijn expliciete verzoek, op een
   eigen branch, en nooit direct op `main`.
5. Werk in de learnings-notitie per punt **Doorgevoerd** bij.
