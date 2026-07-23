<!-- GEGENEREERD uit skills/_shared/story-base.md — niet handmatig bewerken. Bewerk de bron en draai `npm run sync`. -->

# Story-workflow — gedeelde basis

Dit is de gedeelde spine voor `feature-story` en `bug-story`. Een wrapper-skill leest
dit bestand, geeft de **story-id** mee en geeft aan welke stappen worden ingevoegd of
overgeslagen. Vervang overal `<STORY_ID>` door de door de wrapper meegegeven story-id.

## Pas aan je harness aan

Deze workflow draait in meerdere agents (o.a. Claude Code en Pi). Twee dingen verschillen
per harness — stem je aanpak daarop af:

- **Subagents.** Heeft je harness subagents (bv. Claude Code `Task`/`Explore`)? Delegeer
  read-only verkenning en het lokaal testen daaraan om de hoofdcontext schoon te houden.
  Heeft je harness dat niet (bv. Pi in de standaardconfig)? Doe verkenning en tests dan
  read-only in de hoofdcontext. Een aparte geïsoleerde run (bv. `pi -p`) mag alleen voor
  onafhankelijk, niet-conflicterend werk zoals een losse test-run.
- **Kwaliteitschecks.** Draaien er hooks die automatisch formatten, linten, testen en
  route-detectie doen (typische Claude Code-setup)? Vertrouw daarop. Zo niet (bv. Pi)?
  Draai de stack-specifieke formatter, linter, tests en route-check dan zélf expliciet, en
  zeg pas "klaar" als de relevante checks slagen.

Deze basis is het *recept* en bepaalt de volgorde. Werk met een zichtbare TODO-lijst zodat
geen stap wordt overgeslagen; voeg geen tijdelijk `TODO.md` aan de repository toe.

**Geldt voor élke commit in deze workflow (niet alleen de PR-stap):** zet NOOIT een
`Co-authored-by: ... Anthropic`/`Claude`-trailer of andere AI-attributie ("Generated with
Claude" e.d.) in een commit-message. Commit op naam van de gebruiker, zonder co-author.

---

## 1. Story ophalen (Shortcut — via de API-skill)

Haal Shortcut-story `sc-<STORY_ID>` op via de **`shortcut-story-api`-skill** met operatie
`get <STORY_ID>`. Die skill haalt de story via de Shortcut **REST API** op
(`GET /stories/{id}`).

- **Claude Code:** roep de Skill-tool aan (skill `shortcut-toolkit:shortcut-story-api`,
  args `get <STORY_ID>`).
- **Andere harnessen (bv. Pi):** `read` de locatie van die skill zoals je harness die in
  de lijst met beschikbare skills toont, en volg de operatie `get <STORY_ID>`.

**Harde regel — geen browser voor Shortcut.** Gebruik NOOIT browser-automatisering
(navigeren naar app.shortcut.com) om een story te lezen. Alleen de `shortcut-story-api`-skill
of, als terugval, dezelfde API rechtstreeks:

```bash
curl -s -H "Shortcut-Token: $SHORTCUT_TOKEN" \
  "https://api.app.shortcut.com/api/v3/stories/<STORY_ID>"
```

Lukt ook dat niet (geen token / geen netwerk)? Vraag mij dan de storytekst te plakken —
ga niet zelf de browser in.

Bewaar de relevante storydata (waaronder `formatted_vcs_branch_name`) en vat kort samen:
titel, doel, acceptatiecriteria.

## 2. Analyseren en uitleggen

Leg in eigen woorden uit **wat er technisch moet gebeuren**:
- Welke onderdelen/bestanden raakt dit waarschijnlijk?
- Welke aannames of open vragen zijn er?
- Welke risico's / edge cases?

Verken de codebase **read-only**, beknopt, en lees alleen wat relevant is voor de story:
- **Met subagents:** gebruik een read-only Explore-subagent zodat de hoofdcontext niet
  volloopt ("Zoek uit hoe X nu werkt en welke bestanden relevant zijn; geef een beknopte
  kaart terug").
- **Zonder subagents:** verken zelf read-only in de hoofdcontext met `read` en gerichte
  `bash`-commando's zoals `rg` en `find`.

> **Bug-story voegt hier een stap 2b in (read-only validatie-script) — zie de bug-wrapper.**
> Feature-story slaat 2b over en gaat direct door naar stap 3.

## 3. Plan opstellen (via Plannotator)

Stel een concreet, stapsgewijs implementatieplan op en laat mij het annoteren met
**Plannotator**:

1. Schrijf het plan naar een markdown-bestand buiten de repository of in een genegeerde
   scratchpad (bv. `plan-sc-<STORY_ID>.md`).
2. Open het ter annotatie: `plannotator annotate <pad-naar-plan>.md`
3. Verwerk de teruggekomen annotaties in het plan.
4. Herhaal 2–3 tot ik akkoord ben.

**Harde gate:** ga pas naar stap 4 nadat ik het geannoteerde plan heb goedgekeurd.

## 4. Branch aanmaken (uit Shortcut)

Maak een feature-branch met een naam die de **story-id** bevat, zodat de branch bij het
pushen automatisch aan de story wordt gekoppeld. Verzin dus geen losse naam.

Gebruik de branch-naam die Shortcut aanlevert in de storydata uit stap 1 (meestal het veld
`formatted_vcs_branch_name`). Is dat veld er niet, bouw dan zelf een naam van de vorm
`sc-<STORY_ID>/<korte-slug>`. **Geen browser** om dit op te zoeken.

```bash
# BRANCH bevat de story-id; hij MOET sc-<STORY_ID> bevatten
git switch -c "$BRANCH" 2>/dev/null || git switch "$BRANCH"
```

Harde eis: de branch-naam bevat `sc-<STORY_ID>`. Controleer dit; ontbreekt het, stop dan
en vraag mij om de juiste naam — anders linkt Shortcut de branch niet.

## 5. Plan uitvoeren

Voer het goedgekeurde plan uit op deze branch en houd zelf de regie over alle wijzigingen.

- **Met subagents:** verdeel onafhankelijke brokken werk over meerdere subagents zodat ze
  parallel kunnen werken; integreer daarna de resultaten.
- **Zonder subagents:** voer uit in de hoofdcontext. Delegeer geen gelijktijdige edits aan
  losse processen; een aparte, testgerichte run is optioneel als het werk echt onafhankelijk is.

Zorgen hooks in jouw setup automatisch voor formatten/linten van gewijzigde files? Vertrouw
daarop. Zo niet, draai de stack-specifieke formatter/linter en relevante tests dan zelf, en
blijf herstellen tot de relevante checks slagen. Gebruik geen generieke auto-fix over de
hele repo die ongerelateerde bestanden kan wijzigen.

## 6. Self-review (via Plannotator Review)

Doe vóór de PR een self-review van de wijzigingen met **Plannotator Review** op de
huidige worktree:

```bash
plannotator review
```

Verwerk de teruggekomen feedback (of leg kort uit waarom je iets niet overneemt). Draai na
wijzigingen de relevante checks opnieuw voordat je de PR opent.

## 7. Pull request maken

Controleer eerst diff en teststatus. Commit en push daarna op de feature-branch en open de PR:

```bash
git add -A && git commit -m "<type>: <korte omschrijving> [sc-<STORY_ID>]"
git push -u origin HEAD
gh pr create --title "<type>: <korte omschrijving> [sc-<STORY_ID>]" \
  --body "<max 2 zinnen: wat er is aangepast>"
```

**Harde regels voor commit & PR:**
- **Nooit** een `Co-authored-by: ... Anthropic`/`Claude`-trailer of enige AI-attributie in
  de commit-message zetten. Geen "Generated with Claude"-regels. Commit op naam van de
  gebruiker, zonder co-author.
- **PR-beschrijving = maximaal 2 zinnen**, die duidelijk maken **wat er is aangepast**.
  Geen lange opsommingen, geen test-plan-secties, geen boilerplate. Gebruik daarom
  `--body` (hierboven), niet `--fill` (die plakt de volledige commit-body erin).
- Zet `[sc-<STORY_ID>]` in de commit/PR zodat Shortcut alles aan de story koppelt.

> Draait er een `verify-done` Stop-hook (Claude Code-setup)? Die laat je pas "klaar" zijn als
> build + tests slagen. Zonder zo'n hook: zeg zelf pas dat het werk klaar is als de relevante
> build, lint en tests slagen.

## 8. Wachten op reviewbot-comments (Greptile)

Reviewbots reageren asynchroon. Kies één aanpak op basis van je harness:

**Optie A (indien beschikbaar, hands-off):** heb je een ingebouwde watcher (bv. `/autofix-pr`
in Claude Code)? Vertel mij dat ik die op deze branch kan draaien; die bewaakt de PR en pusht
fixes zodra CI faalt of een reviewer comment plaatst. Ga daarna door naar stap 10.

**Optie B (pollen):** wacht tot Greptile comments heeft geplaatst en meld het expliciet als
de timeout verloopt zonder reactie (behandel dat niet als "review afgerond").

```bash
PR=$(gh pr view --json number -q .number)
FOUND=""
for i in $(seq 1 20); do            # ~10 min bij 30s interval — pas aan
  COMMENTS=$(gh pr view "$PR" --json comments -q '.comments[].author.login' 2>/dev/null | grep -i greptile || true)
  REVIEWS=$(gh pr view "$PR" --json reviews  -q '.reviews[].author.login'  2>/dev/null | grep -i greptile || true)
  if [ -n "$COMMENTS$REVIEWS" ]; then FOUND=1; echo "Greptile heeft gereageerd"; break; fi
  sleep 30
done
[ -n "$FOUND" ] || echo "Timeout: nog geen Greptile-reactie"
```

> Vervang de `greptile`-filter door de exacte bot-naam die in jullie repo comment, of
> poll Greptile's eigen API/webhook i.p.v. `gh`.

## 9. Comments verwerken (conditioneel)

- **Greptile heeft gereageerd?** Lees de comments/reviews, beoordeel elk voorstel tegen de
  code, verwerk de terechte fixes en push. Bij twijfel: leg kort uit waarom je iets niet
  overneemt. Draai na fixes de relevante checks opnieuw.
- **Timeout of geen comments?** Meld dit expliciet en doe niet alsof de review afgerond is;
  vraag of je langer moet wachten of later moet terugkomen.

## 10. Nieuwe route? → rechten voor de PO

Controleer of er in deze wijziging een **nieuwe route** is toegevoegd.

> Een `detect-route` hook geeft hier al een automatische reminder als een routebestand
> gewijzigd is (Claude Code-setup). Verifieer het altijd ook zelf:
> ```bash
> git diff main...HEAD -- <routes-pad>   # bv. routes/ of src/app/api/ of config/routes.rb
> ```

Is er een nieuwe route én zijn daar nieuwe **rechten/permissies** voor nodig die een
**PO** moet instellen?

- **Zo ja:** zet een comment **onder de story** in Shortcut. **Houd die comment kort:**
  alleen de route + dat er een rol/recht aangepast moet worden. Eén regel, geen uitleg,
  geen samenvatting van de wijziging, geen context over de implementatie.
  - Format: `Nieuwe route: <route> — rol/recht aanpassen.`
  - Voorbeeld: `Nieuwe route: /admin/exports — rol/recht aanpassen.`
  - Weet je de benodigde permissie zeker? Dan mag die er nog achter, maximaal een paar
    woorden: `Nieuwe route: /admin/exports — rol/recht aanpassen (admin.exports.view).`
  - Via Shortcut MCP: gebruik de "add comment to story"-tool op story `<STORY_ID>`.
  - Fallback via API:
    ```bash
    curl -s -X POST \
      -H "Content-Type: application/json" \
      -H "Shortcut-Token: $SHORTCUT_API_TOKEN" \
      -d '{"text":"Nieuwe route: <route> — rol/recht aanpassen."}' \
      "https://api.app.shortcut.com/api/v3/stories/<STORY_ID>/comments"
    ```
- **Zo nee:** niets doen.

## 11. Testen op localhost

Start de app lokaal volgens de repository-instructies en verifieer de acceptatiecriteria
van story `<STORY_ID>` end-to-end. Rapporteer pass/fail met concreet bewijs en sluit alle
gestarte servers/processen na afloop af. Bij een failure: herstel, draai de relevante checks
opnieuw en herhaal de localhost-test.

- **Met subagents:** laat een subagent de app draaien en de scenario's testen ("Start de app
  lokaal, test de acceptatiecriteria van story `<STORY_ID>` end-to-end, rapporteer pass/fail
  met bewijs, sluit de server daarna af"). Een `SubagentStop`-hook checkt daarna of het testen
  echt is uitgevoerd.
- **Zonder subagents:** doe het in de hoofdcontext of in een geïsoleerde, testgerichte run
  (bv. `pi -p "... test uitsluitend de acceptatiecriteria van story <STORY_ID> ... wijzig geen
  code en sluit de server na afloop af"`).

> Vul je eigen start-commando in, bv. `bin/rails server`, `npm run dev`, `docker compose up -d`.

## 12. Vastleggen in Obsidian

Leg de afgeronde story vast in je Obsidian-vault via de **Obsidian MCP**. Maak een nieuwe
notitie aan (of werk een bestaande bij) met een korte samenvatting, zodat je een
doorzoekbaar dev-logboek opbouwt.

> Pad-voorbeeld: `Dev Log/sc-<STORY_ID>.md`. Gebruik de create/append/update-note-tool van je
> Obsidian MCP. Is de MCP niet beschikbaar? Meld dat en schrijf alleen rechtstreeks naar de
> vault nadat het vaultpad bekend of door mij bevestigd is — raad het pad niet.

Notitie-inhoud (template):

```markdown
# sc-<STORY_ID> — <story-titel>

- **Datum:** <vandaag>
- **Type:** <feature | bug>
- **Branch:** <branch-naam>
- **PR:** <pr-link>

## Wat is gebouwd / gefixt
<korte samenvatting van de wijzigingen>

## Validatie (alleen bug)
<read-only script-output die de oorzaak bevestigde / n.v.t. bij feature>

## Greptile
<verwerkt: welke fixes / geen comments / timeout>

## PO-actie
<ja: welke route + rechten / nee>

## Test (localhost)
<pass/fail + bewijs>

## Geleerd / aandachtspunten
<optioneel>
```

## Afronden

Rapporteer beknopt: branch-naam, wat is gebouwd/gefixt, PR-link, Greptile-status, eventuele
PO-actie onder de story, de testuitkomst, en het pad van de aangemaakte Obsidian-notitie.
