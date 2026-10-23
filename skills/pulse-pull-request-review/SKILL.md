---
name: pulse-pull-request-review
description: >
  Use when you want a pull request reviewed specifically on its Pulse UI: views, partials,
  components, forms, filters, tables and Stimulus wiring checked against the conventions of the
  pulse-ui skill (rails-toolkit) — including its full completion audit. Read-only: reports
  findings, never comments on GitHub without explicit approval of the exact text. Typically via a
  `pulse-pull-request-review <pr-nummer|pr-url|story-id>` command. Triggers on "review de pulse
  van deze PR", "check de pulse-elementen", "klopt deze PR met de pulse-ui skill".
disable-model-invocation: true
argument-hint: "[pr-nummer | pr-url | story-id]"
---

# Pulse Pull Request Review

Review één pull request op de **Pulse-elementen**: klopt wat er in de views, partials, forms,
filters, tabellen, dialogs en Stimulus-koppelingen staat met de conventies van de
**`pulse-ui`-skill** uit de agent-skills (plugin `rails-toolkit`)? Dat is de maatstaf, niet mijn
smaak en niet de huidige Pulse-code in de repo.

Dit is geen algemene code-review. Correctheid van de rest van de PR valt buiten scope; daarvoor
is `/code-review`. Kijk alleen buiten de Pulse-bestanden waar dat nodig is om een Pulse-regel te
toetsen (strong params voor show/edit-pariteit, eager loading voor tellingen, `render_forbidden`
in de controller).

## Agentindeling

De hoofdagent doet alles zelf: PR ophalen, de `pulse-ui`-skill lezen, auditen en rapporteren.
Start geen subagents. Alleen als ik om een tweede, onafhankelijke blik vraag gebruik je één
aparte read-only reviewer; die adviseert alleen.

## Niet onderhandelbare regels

- **Read-only.** Geen checkout van de PR-branch in mijn werkmap, geen codewijzigingen, geen
  commits of pushes. Lees via `gh` en `git show`.
- **Nooit zelfstandig op GitHub reageren**: geen review, comment, reaction, approve of
  request-changes. Alleen na expliciet akkoord op de **exacte tekst** (zie stap 6).
- **Review niet uit je hoofd.** Lukt het niet om de `pulse-ui`-skill te laden, stop dan en zeg
  dat. Een Pulse-review zonder de actuele regels is waardeloos.

## 1. Pull request vinden

Alles achter het command is het argument (`$ARGUMENTS`):

- **PR-URL** of **`#123`**: gebruik die PR (de URL bepaalt ook de repo).
- **`sc-123`** of een **Shortcut-URL**: zoek de PR bij die story:

  ```bash
  gh pr list --state all --limit 100 --search "sc-<STORY_ID>" \
    --json number,title,url,headRefName,state
  ```

  Precies één: gebruik die. Meerdere: toon ze en vraag welke. Geen: meld dat en stop.
- **Kaal getal**: probeer eerst `gh pr view <n>`. Bestaat die PR niet, behandel het als
  story-id.
- **Leeg**: de PR van de huidige branch (`gh pr view`). Geen PR? Vraag om een nummer.

Meld in één regel welke PR je reviewt (nummer, titel, branch, open/gemerged).

## 2. De `pulse-ui`-skill laden — de maatstaf

Laad de skill, in deze volgorde:

1. **Als skill** via je skill-mechanisme: `rails-toolkit:pulse-ui` (of `pulse-ui`).
2. **Geïnstalleerde plugin**: de hoogste versie onder
   `~/.claude/plugins/cache/mobiel-agent-skills/rails-toolkit/*/skills/pulse-ui/`.
3. **Bronrepo** `~/code/agent-skills`. Die checkout staat vaak op een featurebranch, dus lees van
   `origin/main` en niet uit de werkmap:

   ```bash
   git -C ~/code/agent-skills fetch -q origin
   git -C ~/code/agent-skills show origin/main:plugins/rails-toolkit/skills/pulse-ui/SKILL.md
   ```

Lees `SKILL.md` **volledig**, inclusief de *Mandatory completion audit*, *Rules*,
*Common Mistakes* en de *Decision table*. Lees daarna de `reference/`-bestanden die de diff
raakt, via die decision table: formulieren → `forms.md`, index/filters/dialogs → `rails.md` en
`patterns.md`, componentaanroepen → `components.md`, Stimulus → `stimulus.md`, kleuren en
iconen → `theme.md`. Lees bij twijfel `examples.md` mee als referentiescherm.

Noem welke bron en versie je gebruikt (bv. `rails-toolkit 1.1.1 (plugin-cache)`). De skill zegt
zelf dat hij leidend is boven de Pulse-code in een repo; volg dat. Wijkt de PR af van de skill
maar sluit hij aan op een oudere Pulse-API in de repo, dan is het nog steeds een bevinding, met
die nuance erbij.

## 3. De PR ophalen

```bash
gh pr view <PR> --json number,title,body,url,headRefName,headRefOid,baseRefName,files
gh pr diff <PR>
git fetch -q origin "pull/<PR>/head"
```

Bepaal welke bestanden **Pulse-relevant** zijn:

- views en partials die `ui.*`, `Pulse::FormBuilder` of Pulse-layouts gebruiken;
- controllers met `Pulse::Backend` / `Pulse::BulkEditable` of die `filters`, `paginate`,
  `breadcrumbs`, `frame_id`, `toast`, `render_forbidden` gebruiken;
- Stimulus-controllers en de importmap-koppeling van Pulse-pagina's;
- helpers en locales waarvan de uitkomst op een Pulse-scherm staat.

Lees die bestanden **volledig op de PR-head** (`git show FETCH_HEAD:<pad>`), niet alleen de
diff-hunks: veel auditpunten gaan over samenhang (header ↔ cel, show ↔ edit, filterformulier ↔
`_results.html.erb`, frame-id's van request en response). Lees gekoppelde, ongewijzigde partials
mee als de wijziging ervan afhangt.

Bevat de PR geen Pulse-relevante bestanden, zeg dat en stop.

## 4. Auditen

Loop per Pulse-scherm (een pagina met zijn partials, controller en dialogs) door:

1. **Alle punten van de completion audit**, één voor één. Markeer elk punt als ✅, ❌ of
   n.v.t.; sla er geen stil over.
2. **Rules en Common Mistakes** uit `SKILL.md`.
3. **Component-API**: elke `ui.*`-aanroep tegen `components.md` / `forms.md` (argumenten,
   slots, `with_*`-builders, deprecated componenten zoals `ui.id_link` en `ui.copy_link`).
4. **Iconen**: bestaat elk gebruikt icoon? Gebruik bij voorkeur de methode uit de skill
   (Tidewave `project_eval`). Anders, vanuit een lokale checkout van dezelfde repo:

   ```bash
   P=$(bundle show pulse) && ls "$P/app/assets/images/pulse/icons" | sed 's/\.svg$//'
   ```

   Kon je de iconen niet controleren, zet dat bij *Niet gecontroleerd*.
5. **Nederlandse UI-tekst**: alles wat op het scherm komt, inclusief locales, knoppen,
   lege opties en tellers.
6. **Geen inline code-comments** toegevoegd in Pulse-bestanden (functionele comments
   uitgezonderd).

Wat telt als bevinding:

- **Nieuw of gewijzigd** in deze PR en in strijd met de skill → bevinding.
- **Ongewijzigd**, maar door deze PR fout geworden (bv. een kolom erbij zonder bijbehorende
  header) → bevinding.
- **Al bestaand** en niet aangeraakt → hooguit kort onder *Bestaand, buiten scope*.

Onderbouw elke bevinding met de regel uit de skill (auditnummer of sectie) en controleer hem
in de code. Een vermoeden dat je niet kunt bevestigen, zet je onder *Twijfel*, niet onder de
bevindingen.

Dit is een statische review: je rendert de schermen niet. Zeg dat in het rapport. Wil ik het
toch gerenderd zien, bespreek dan eerst hoe (worktree, lokale app) voordat je iets opstart.

## 5. Rapporteren

Kort en scanbaar, in deze volgorde:

```text
PR #<n> — <titel> (<branch>)
Maatstaf: pulse-ui <versie> (<bron>)
Pulse-bestanden: <aantal> — <schermen in een paar woorden>

Bevindingen
1. [moet] <bestand:regel> — <wat er mis is>
   Regel: audit #<n> / <sectie> — "<korte quote uit de skill>"
   Voorstel: <concrete wijziging, met een klein codefragment als dat helpt>
2. [advies] ...

Audit
#1 Datumchips ✅ · #2 Zoeken-knop drawer n.v.t. · #3 Zoek/Filter-labels ❌ (bevinding 1) · …

Twijfel: <alleen als er iets is>
Bestaand, buiten scope: <alleen als er iets is>
Niet gecontroleerd: gerenderd gedrag<, iconen, …>
```

- **[moet]**: schendt een audit-punt, een Rule of een Common Mistake, of gebruikt een
  component verkeerd.
- **[advies]**: past beter bij de patronen en voorbeelden in de reference, maar is geen harde
  regel.

Sorteer op ernst. Geen bevindingen? Zeg dat in één regel en toon toch de auditregel.

## 6. Daarna — alleen op mijn verzoek

Vraag in één zin wat ik ermee wil. Mogelijke vervolgen:

- **Op de PR zetten.** Toon eerst per bevinding de exacte commenttekst en de plek
  (`bestand:regel`). Plaats pas na expliciet akkoord op die teksten, als **één review met
  event `COMMENT`** (nooit `APPROVE` of `REQUEST_CHANGES` tenzij ik dat zeg), met inline
  comments op de PR-head:

  ```bash
  gh api "repos/<owner>/<repo>/pulls/<PR>/reviews" --input <scratchpad>/review.json
  ```

  met `commit_id` = `headRefOid` en per comment `path`, `line`, `side: "RIGHT"`, `body`.
  Kan een regel niet inline (niet in de diff), zet hem in de review-body. Schrijf de comments
  in de taal van de PR, kort, op mijn naam: geen AI-attributie, geen verwijzing naar deze skill.
- **Lokaal fixen.** Alleen als het mijn eigen PR is en ik erom vraag: in een aparte worktree of
  op de PR-branch na mijn akkoord, met dezelfde audit opnieuw over de gewijzigde bestanden.
  Commit en push alleen na akkoord op de diff.
- **Niets.** Dan blijft alles zoals het is.
