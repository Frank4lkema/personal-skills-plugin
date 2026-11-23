---
name: pulse-pull-request-review
description: >
  Use when you want a pull request reviewed specifically on its Pulse UI: views, partials,
  components, forms, filters, tables and Stimulus wiring checked against the conventions of the
  pulse-ui skill (rails-toolkit) — including its full completion audit, a comparison with the
  legacy screen it replaces, earlier review decisions in the same migration series, and a click
  round through the rendered screens in a separate worktree. Read-only towards the PR: reports
  findings, never comments on GitHub without explicit approval of the exact text. Typically via a
  `pulse-pull-request-review <pr-nummer|pr-url|story-id>` command. Triggers on "review de pulse
  van deze PR", "check de pulse-elementen", "klopt deze PR met de pulse-ui skill".
disable-model-invocation: true
argument-hint: "[pr-nummer | pr-url | story-id]"
---

# Pulse Pull Request Review

Review één pull request op de **Pulse-schermen**: klopt wat er in de views, partials, forms,
filters, tabellen, dialogs en Stimulus-koppelingen staat met de conventies van de
**`pulse-ui`-skill** uit de agent-skills (plugin `rails-toolkit`), en werkt het scherm ook als
je erdoorheen klikt? De `pulse-ui`-skill is de maatstaf, niet mijn smaak, niet de huidige
Pulse-code in de repo en niet andere apps. Vergelijk niet uit jezelf met product, mother5, de
Pulse-docs of de Pulse-bron; alleen als ik daar expliciet om vraag.

Dit is geen algemene code-review. Wel in scope is **schermcorrectheid**: toont, filtert, sorteert
en telt het scherm de juiste records? Kijk buiten de Pulse-bestanden waar dat nodig is om een
Pulse-regel of de schermcorrectheid te toetsen (strong params voor show/edit-pariteit, eager
loading voor tellingen, ransack-scopes, `render_forbidden`, autorisatie in de sidebar). De rest
van de PR (jobs, API-koppelingen, modellogica die niet op het scherm komt) is voor `/code-review`.

## Agentindeling

De hoofdagent doet alles zelf: PR ophalen, de `pulse-ui`-skill lezen, auditen, doorklikken en
rapporteren. Start geen subagents. Alleen als ik om een tweede, onafhankelijke blik vraag
gebruik je één aparte read-only reviewer; die adviseert alleen.

## Niet onderhandelbare regels

- **Read-only richting de PR.** Geen checkout van de PR-branch in mijn werkmap, geen
  codewijzigingen, geen commits of pushes. Lees via `gh` en `git show`. De klikronde draait in
  een **aparte worktree** (stap 6) en verandert daar geen code.
- **Geen muterende kliks.** In de klikronde niets opslaan, verwijderen, archiveren, activeren,
  verwerken, importeren of starten. Formulieren openen en invullen mag, versturen niet.
- **Nooit zelfstandig op GitHub reageren**: geen review, comment, reaction, approve of
  request-changes. Alleen na expliciet akkoord op de **exacte tekst** (zie stap 8).
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
   de standaardbranch van `origin` (dat is `master`, niet `main`) en niet uit de werkmap:

   ```bash
   git -C ~/code/agent-skills fetch -q origin
   git -C ~/code/agent-skills show origin/master:plugins/rails-toolkit/skills/pulse-ui/SKILL.md
   ```

Lees `SKILL.md` **volledig**, inclusief de *Mandatory completion audit*, *Rules*,
*Common Mistakes* en de *Decision table*. Lees daarna de `reference/`-bestanden die de diff
raakt, via die decision table: formulieren → `forms.md`, index/filters/dialogs/controllers →
`rails.md` en `patterns.md`, componentaanroepen → `components.md`, Stimulus → `stimulus.md`,
kleuren en iconen → `theme.md`. Lees bij twijfel `examples.md` mee als referentiescherm.

Noem welke bron en versie je gebruikt (bv. `rails-toolkit 1.2.2 (plugin-cache)`). De skill zegt
zelf dat hij leidend is boven de Pulse-code in een repo; volg dat. Wijkt de PR af van de skill
maar sluit hij aan op een oudere Pulse-API in de repo, dan is het nog steeds een bevinding, met
die nuance erbij.

## 3. De PR ophalen

```bash
gh pr view <PR> --json number,title,body,url,author,headRefName,headRefOid,baseRefName,files
gh pr diff <PR>
git fetch -q origin "pull/<PR>/head"
```

Bepaal welke bestanden **Pulse-relevant** zijn:

- views en partials die `ui.*`, `Pulse::FormBuilder` of Pulse-layouts gebruiken;
- controllers met `Pulse::Backend` / `Pulse::BulkEditable` of die `filters`, `paginate`,
  `breadcrumbs`, `frame_id`, `toast`, `render_forbidden` gebruiken;
- routes, de sidebar en de layout van Pulse-pagina's;
- Stimulus-controllers en de importmap-koppeling van Pulse-pagina's;
- helpers, ransack-scopes en locales (inclusief `activerecord.models`) waarvan de uitkomst op
  een Pulse-scherm staat.

Lees die bestanden **volledig op de PR-head** (`git show FETCH_HEAD:<pad>`), niet alleen de
diff-hunks: veel auditpunten gaan over samenhang (header ↔ cel, show ↔ edit, filterformulier ↔
`_results.html.erb`, frame-id's van request en response, pagination ↔ het frame waarin hij
staat). Lees gekoppelde, ongewijzigde partials mee als de wijziging ervan afhangt.

Bevat de PR geen Pulse-relevante bestanden, zeg dat en stop.

## 4. Context: het oude scherm en eerdere reviews

### 4a. Het scherm dat vervangen wordt

Zet de PR een bestaand scherm om naar Pulse (verwijderde of vervangen views, controllers of
menu-items), lees dan de **oude versie op de base branch** (`git show origin/<baseRefName>:<pad>`)
en maak per scherm een korte inventaris:

- kolommen en sorteerbare kolommen;
- filters en hun lege opties;
- rij-, pagina- en bulkacties, en herstelacties (opnieuw proberen, herbevestigen);
- secties en blokken op de show-pagina, met hun knoppen (bv. "aanmaken" in een subtabel);
- velden in het formulier, inclusief of een veld leeg te maken is;
- `authorize`-checks per menu-item, knop of actie.

Alles wat in de nieuwe versie ontbreekt, is een bevinding (audit #30), tenzij de
PR-beschrijving of een eerdere reviewreactie uitlegt waarom het bewust weg is. Staat het
nergens, vraag dan in de bevinding om het in de PR-beschrijving te zetten.

### 4b. Eerdere beslissingen in dezelfde reeks

Migraties komen in reeksen van PR's van dezelfde auteur. Haal de reviewcontext op van de
vorige Pulse-PR's van die auteur in deze repo (de laatste ~10, gemerged of open):

```bash
gh pr list --state all --author <login> --limit 30 --json number,title,state,createdAt
gh api "repos/<owner>/<repo>/pulls/<n>/comments" --paginate
gh api "repos/<owner>/<repo>/pulls/<n>/reviews" --paginate
```

Lees de inline comments van mij en de reacties van de auteur, en haal daaruit:

- **Afgewezen of bewust anders gekozen** (bv. "besproken met het team, blijft zo", "dit is
  bewust 1-op-1 gelaten"): breng dat punt niet opnieuw als bevinding; noem het hooguit onder
  *Eerder besloten*.
- **Overgenomen fixes** (bv. "opgelost in …", "ook doorgevoerd in …"): controleer of de nieuwe
  schermen in deze PR die fix ook hebben. Ontbreekt hij, dan is het een bevinding met een link
  naar het eerdere comment.

Lees ook de **Greptile-comments op deze PR**. Wat Greptile al heeft gemeld en nog open staat,
neem je niet op als eigen bevinding; zet het onder *Al gemeld door Greptile*, zodat ik het niet
dubbel zeg.

## 5. Statisch auditen

Loop per Pulse-scherm (een pagina met zijn partials, controller, sections en dialogs) door:

1. **Alle punten van de completion audit**, één voor één. Markeer elk punt als ✅, ❌ of
   n.v.t.; sla er geen stil over. Punten die je alleen in de klikronde kunt bevestigen (bv.
   #6 Nederlandse gerenderde tekst, #19 leegmaakbare Tom Select), markeer je voorlopig en
   bevestig je in stap 6.
2. **Rules en Common Mistakes** uit `SKILL.md`.
3. **Het recept in `reference/rails.md` en `examples.md`**. Wat daar als standaard staat, is
   geen smaak maar de afspraak; wijkt de PR ervan af, dan is dat minimaal [advies]. Let in elk
   geval op:
   - breadcrumbs opgebouwd in de controller (`add_breadcrumb` in een `before_action`) en in de
     view `breadcrumbs: breadcrumbs`, niet een letterlijke array in de view;
   - standaardfilters in `filters.initial(...)` in de controller, niet in `direct`-routes,
     links of constants, zodat de kale index-URL de standaardweergave is;
   - filters heten naar de entiteit (`@order_filters`, `@product_filters`), niet `@filters`;
   - acties via Turbo (`data: { turbo_method: :post }`, `turbo_confirm:`), niet via rails-ujs
     (`data: { method: …, confirm: … }` of `turbo: false, method: :post`);
   - page actions: één primaire knop, meerdere acties achter een `ui.dropdown`; rij-acties in
     het dots-menu, geen losse knop in een rij;
   - dialogs via een `Dialog::…Controller` in `namespace :dialog`; sections als
     `Section…Controller` genest onder de resource, `index` voor een lijst en `show` voor het
     record zelf.
4. **Component-API**: elke `ui.*`-aanroep tegen `components.md` / `forms.md` (argumenten,
   slots, `with_*`-builders, deprecated componenten zoals `ui.id_link` en `ui.copy_link`).
5. **Frames**: elk formulier, elke pagination en elke link binnen een sectie of dialog blijft
   in het juiste frame. Let speciaal op `ui.pagination` in een sectieframe (de limit-select
   navigeert anders de hele pagina weg) en op een filterformulier dat binnen het frame staat
   dat bij elke auto-submit ververst (het zoekveld verliest dan de focus).
6. **Iconen**: bestaat elk gebruikt icoon en past het bij de actie (bv. `archive` voor
   Archiveren)? Gebruik bij voorkeur de methode uit de skill (Tidewave `project_eval`). Anders,
   vanuit de worktree of een lokale checkout van dezelfde repo:

   ```bash
   P=$(bundle show pulse) && ls "$P/app/assets/images/pulse/icons" | sed 's/\.svg$//'
   ```

   Kon je de iconen niet controleren, zet dat bij *Niet gecontroleerd*.
7. **Nederlandse UI-tekst**: alles wat op het scherm komt, inclusief locales, modelnamen
   (`human_plural_name` zonder vertaling in `activerecord.models` geeft Engelse meervouden),
   knoppen, lege opties, tellers en menulabels. Gebruik binnen een scherm en tussen
   gerelateerde schermen dezelfde term voor hetzelfde ding (niet "aanvragen" en "requests" door
   elkaar). Een placeholder noemt alles waarop het veld echt zoekt (kijk naar de
   ransack-alias).
8. **Schermcorrectheid**:
   - sorteren met paginering heeft een vaste tweede sortering (bv. `.order(:name)` of `:id`
     achter de gekozen kolom), anders verschijnen records dubbel of vallen ze weg;
   - tellingen en badges tellen wat de kolomkop belooft (bv. alleen actieve providers die het
     product ook voeren);
   - filteropties matchen de opgeslagen waarden (enum-waarden per subklasse, STI);
   - een `data-params` of verborgen veld neemt geen filter mee dat bij de nieuwe keuze niet
     meer hoort;
   - een select met heel veel opties (honderden of meer) maakt de pagina zwaar; beperk de
     lijst of laad de opties via een zoekendpoint;
   - `password_field` en andere velden zonder value bij edit maken de waarde niet leeg bij
     opslaan.
9. **Geen inline code-comments** toegevoegd in Pulse-bestanden (functionele comments
   uitgezonderd).

Wat telt als bevinding:

- **Nieuw of gewijzigd** in deze PR en in strijd met de skill of het recept → bevinding.
- **Ongewijzigd**, maar door deze PR fout geworden (bv. een kolom erbij zonder bijbehorende
  header) → bevinding.
- **Functionaliteit van het oude scherm die verdwijnt** zonder uitleg → bevinding (stap 4a).
- **Al bestaand** en niet aangeraakt → hooguit kort onder *Bestaand, buiten scope*.

Onderbouw elke bevinding met de regel uit de skill (auditnummer, sectie of recept), met het
oude scherm, of met wat je in de klikronde zag. Een vermoeden dat je niet kunt bevestigen,
zet je onder *Twijfel*, niet onder de bevindingen.

## 6. Klikronde

Veel fouten zie je pas als je door het scherm klikt. Doe deze ronde standaard, tenzij ik zeg
dat het statisch mag blijven.

### Worktree en app

1. **Worktree**: gebruik `~/code/<repo>-pr<PR>` als die al bestaat (zet hem dan op de
   PR-head: `git -C <pad> fetch -q origin "pull/<PR>/head" && git -C <pad> checkout -q --detach FETCH_HEAD`).
   Bestaat hij niet, maak hem vanuit de primaire checkout:

   ```bash
   git fetch -q origin "pull/<PR>/head"
   git worktree add --detach ~/code/<repo>-pr<PR> FETCH_HEAD
   ```

   Heeft de worktree lokale wijzigingen, stop dan en vraag wat ik wil.
2. **Migraties**: bevat de PR een migratie (`db/migrate/`), vraag dan eerst of je hem op de
   gedeelde development-database mag draaien. Zonder akkoord: geen klikronde, wel melden.
3. **Starten** op een vrije poort (niet 3000, daar draait vaak de hoofdcheckout), met open
   stdin zodat de watchers blijven draaien:

   ```bash
   cd ~/code/<repo>-pr<PR>
   bundle install --quiet && yarn install --frozen-lockfile --silent
   tail -f /dev/null | PORT=<poort> bin/dev     # run_in_background
   ```

   Wacht tot `curl -s -o /dev/null -w "%{http_code}" localhost:<poort>/` antwoordt.
4. **Inloggen**: kom je op een loginpagina, vraag dan of ik in de Paseo-browser inlog. Lukt
   het niet, dan geen klikronde: zet het onder *Niet gecontroleerd*.

Meld in één regel worktree, poort en welke schermen je gaat doorlopen.

### Wat je per scherm doorloopt

Gebruik de Paseo-browser (`browser_*`). Per scherm uit de PR, met echte data:

- **Index**: elk primair filter en elk drawer-filter zetten; chip weghalen; drawer sluiten met
  × en met **Zoeken** (komen select, chip en tabel overeen?); typen in een zoekveld (blijft de
  focus?); sorteren op elke sorteerbare kolom en naar pagina 2; "Bekijk 25" naar 50; een
  filtercombinatie zonder resultaat (lege staat zonder lege tabelkop?); terug naar de index via
  breadcrumb na een show (blijven de filters staan?).
- **Show**: elke sectie laadt (geen "Content missing"); pagination, filters en limit-select
  binnen een sectie blijven in de sectie; dialogs en drawers openen en sluiten; browser-back na
  een dialog.
- **Formulier**: elk veld met een bestaande waarde laden; selects leegmaken (kan de lege optie
  terug?); grootte van de HTML bij selects met veel opties
  (`browser_evaluate`: `document.documentElement.outerHTML.length`).
- **Tekst**: lees de gerenderde tekst na op Engels, ruwe enum-keys en inconsistente termen.
- **Menu**: het juiste menu-item licht op op index, show en sections.

Een bevinding uit de klikronde krijgt de URL en wat je zag (een screenshot alleen als die iets
toevoegt). Stop na afloop alle processen die je hebt gestart. Laat de worktree staan; die
ruim ik zelf op.

## 7. Rapporteren

Kort en scanbaar, in deze volgorde:

```text
PR #<n> — <titel> (<branch>)
Maatstaf: pulse-ui <versie> (<bron>)
Pulse-bestanden: <aantal> — <schermen in een paar woorden>
Klikronde: <worktree, poort> | niet gedaan — <reden>

Bevindingen
1. [moet] <bestand:regel> — <wat er mis is>
   Bron: audit #<n> / <sectie of recept> — "<korte quote>" | oud scherm | klikronde: <URL, wat je zag>
   Voorstel: <concrete wijziging, met een klein codefragment als dat helpt>
2. [advies] ...

Audit
#1 Datumchips ✅ · #2 Zoeken-knop drawer n.v.t. · #3 Zoek/Filter-labels ❌ (bevinding 1) · …

Oud scherm: <wat behouden is, wat bewust weg is, of n.v.t.>
Eerder besloten: <punten die bewust niet opnieuw zijn gemeld, met link>
Al gemeld door Greptile: <alleen als er iets is>
Twijfel: <alleen als er iets is>
Bestaand, buiten scope: <alleen als er iets is>
Niet gecontroleerd: <wat niet lukte, bv. klikronde, iconen>

Kandidaat-lessen voor pulse-ui
- <bevinding die niet uit een regel van pulse-ui kwam, als voorstel voor een regel>
```

- **[moet]**: schendt een audit-punt, een Rule of een Common Mistake, gebruikt een component
  verkeerd, laat functionaliteit van het oude scherm zonder uitleg weg, of toont/filtert de
  verkeerde data.
- **[advies]**: wijkt af van het recept of de voorbeelden in de reference, maar is geen harde
  regel.

Sorteer op ernst. Geen bevindingen? Zeg dat in één regel en toon toch de auditregel.

*Kandidaat-lessen* zijn bevindingen uit het oude scherm, de klikronde of de schermcorrectheid
waarvoor `pulse-ui` nog geen regel heeft. Wijzig `pulse-ui` niet zelf; dat is een gedeelde repo.

## 8. Daarna — alleen op mijn verzoek

Vraag in één zin wat ik ermee wil. Mogelijke vervolgen:

- **Op de PR zetten.** Toon eerst per bevinding de exacte commenttekst en de plek
  (`bestand:regel`). Plaats pas na expliciet akkoord op die teksten, als **één review met
  event `COMMENT`** (nooit `APPROVE` of `REQUEST_CHANGES` tenzij ik dat zeg), met inline
  comments op de PR-head:

  ```bash
  gh api "repos/<owner>/<repo>/pulls/<PR>/reviews" --input <scratchpad>/review.json
  ```

  met `commit_id` = `headRefOid` en per comment `path`, `line`, `side: "RIGHT"`, `body`.
  Is het voorstel een directe vervanging van de regel(s) in de diff, gebruik dan een
  ```` ```suggestion ```` -blok (bij meerdere regels met `start_line`). Kan een regel niet inline
  (niet in de diff), zet hem in de review-body. Verwijs naar een eerder comment in de reeks met
  een link in plaats van het te herhalen. Schrijf de comments in de taal van de PR, kort, op
  mijn naam: geen AI-attributie, geen verwijzing naar deze skill.
- **Lessen voor pulse-ui.** Werk de *Kandidaat-lessen* uit tot concrete tekst voor
  `pulse-ui` (regel, Common Mistake of reference) en laat die eerst zien. Een branch of PR in
  `agent-skills` alleen na mijn akkoord.
- **Lokaal fixen.** Alleen als het mijn eigen PR is en ik erom vraag: in een aparte worktree of
  op de PR-branch na mijn akkoord, met dezelfde audit opnieuw over de gewijzigde bestanden.
  Commit en push alleen na akkoord op de diff.
- **Niets.** Dan blijft alles zoals het is.
