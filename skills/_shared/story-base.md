# Story-workflow — gedeelde basis

Dit is de gedeelde spine voor `feature-story` en `bug-story`. Een wrapper-skill leest
dit bestand, geeft de **story-id** mee en geeft aan welke stappen worden ingevoegd of
overgeslagen. Vervang overal `<STORY_ID>` door de door de wrapper meegegeven story-id.

Rolverdeling:
- Deze basis is het *recept* en bepaalt de volgorde.
- Zwaar/variabel werk (uitvoeren, testen) delegeer je naar **subagents** via de Task-tool.
- Kwaliteits-garanties (formatten, linten, "niet klaar tot tests slagen", route-detectie)
  draaien automatisch via **hooks** — die vuren vanzelf.

Werk met een TODO-lijst zodat geen stap wordt overgeslagen.

**Geldt voor élke commit in deze workflow (niet alleen de PR-stap):** zet NOOIT een
`Co-authored-by: ... Anthropic`/`Claude`-trailer of andere AI-attributie ("Generated with
Claude" e.d.) in een commit-message. Commit op naam van de gebruiker, zonder co-author.

---

## 1. Story ophalen (Shortcut — via de API-skill)

Haal Shortcut-story `sc-<STORY_ID>` op door de **`shortcut-story-api`-skill** aan te
roepen (Skill-tool, skill `shortcut-toolkit:shortcut-story-api`, args `get <STORY_ID>`).
Die skill haalt de story via de Shortcut **REST API** op (`GET /stories/{id}`).

**Harde regel — geen browser voor Shortcut.** Gebruik NOOIT browser-automatisering
(claude-in-chrome, navigeren naar app.shortcut.com) om een story te lezen. Alleen de
`shortcut-story-api`-skill of, als terugval, dezelfde API rechtstreeks:

```bash
curl -s -H "Shortcut-Token: $SHORTCUT_TOKEN" \
  "https://api.app.shortcut.com/api/v3/stories/<STORY_ID>"
```

Lukt ook dat niet (geen token / geen netwerk)? Vraag mij dan de storytekst te plakken —
ga niet zelf de browser in.

Vat daarna kort samen: titel, doel, acceptatiecriteria.

## 2. Analyseren en uitleggen

Leg in eigen woorden uit **wat er technisch moet gebeuren**:
- Welke onderdelen/bestanden raakt dit waarschijnlijk?
- Welke aannames of open vragen zijn er?
- Welke risico's / edge cases?

Gebruik zo nodig de **Explore-subagent** (read-only) om de codebase te scannen zonder
de hoofdcontext vol te maken:

> Spawn een Task met agent-type `Explore`: "Zoek uit hoe X nu werkt en welke bestanden
> relevant zijn voor deze story. Geef een beknopte kaart terug."

> **Bug-story voegt hier een stap 2b in (read-only validatie-script) — zie de bug-wrapper.**
> Feature-story slaat 2b over en gaat direct door naar stap 3.

## 3. Plan opstellen (via Plannotator)

Stel een concreet, stapsgewijs implementatieplan op en laat mij het annoteren met
**Plannotator**:

1. Schrijf het plan naar een markdown-bestand (bv. in de scratchpad: `plan-sc-<STORY_ID>.md`).
2. Open het ter annotatie: `plannotator annotate <pad-naar-plan>.md`
3. Verwerk de teruggekomen annotaties in het plan.
4. Herhaal 2–3 tot ik akkoord ben.

**Harde gate:** ga pas naar stap 4 nadat ik het geannoteerde plan heb goedgekeurd.

## 4. Branch aanmaken (uit Shortcut)

Maak een feature-branch met een naam die de **story-id** bevat, zodat de branch bij het
pushen automatisch aan de story wordt gekoppeld. Verzin dus geen losse naam.

Gebruik de branch-naam die Shortcut aanlevert — haal die uit de story-data die je in
stap 1 via de `shortcut-story-api`-skill ophaalde (bv. het veld `formatted_vcs_branch_name`
in de API-respons). Is dat veld er niet, bouw dan zelf een naam van de vorm
`<STORY_ID>/<korte-slug>`. **Geen browser** om dit op te zoeken.

```bash
# BRANCH bevat de story-id; hij MOET /sc-<STORY_ID>/ of sc-<STORY_ID> bevatten
git switch -c "$BRANCH" 2>/dev/null || git switch "$BRANCH"
```

Harde eis: de branch-naam bevat `sc-<STORY_ID>`. Controleer dit; ontbreekt het, stop dan
en vraag mij om de juiste naam — anders linkt Shortcut de branch niet.

## 5. Plan uitvoeren (multi-agent)

Voer het goedgekeurde plan uit op deze branch. Verdeel onafhankelijke brokken werk over
**meerdere subagents** (Task-tool) zodat ze parallel kunnen werken; houd zelf de regie
en integreer de resultaten.

De hooks zorgen ondertussen automatisch dat elke gewijzigde file geformatteerd/gelint
wordt. Jij hoeft dat niet expliciet te doen.

## 6. Self-review (via Plannotator Review)

Doe vóór de PR een self-review van de wijzigingen met **Plannotator Review** op de
huidige worktree:

```bash
plannotator review
```

Verwerk de teruggekomen feedback (of leg kort uit waarom je iets niet overneemt) voordat
je de PR opent.

## 7. Pull request maken

Commit en push op de feature-branch en open de PR:

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

> Zet `[sc-<STORY_ID>]` in de commit/PR zodat Shortcut alles aan de story koppelt.
> De `verify-done` Stop-hook laat je pas "klaar" zijn als build + tests slagen.

## 8. Wachten op reviewbot-comments (Greptile)

Reviewbots reageren asynchroon — dat kan een hook niet afvangen. Kies één aanpak:

**Optie A (aanbevolen, hands-off):** gebruik de ingebouwde watcher. Vertel mij dat ik
`/autofix-pr` kan draaien op deze branch; die bewaakt de PR en pusht fixes zodra CI faalt
of een reviewer comment plaatst. Ga daarna door naar stap 10.

**Optie B (pollen binnen deze skill):** wacht tot Greptile comments heeft geplaatst.

```bash
PR=$(gh pr view --json number -q .number)
for i in $(seq 1 20); do            # ~10 min bij 30s interval — pas aan
  COMMENTS=$(gh pr view "$PR" --json comments -q '.comments[].author.login' 2>/dev/null | grep -i greptile || true)
  REVIEWS=$(gh pr view "$PR" --json reviews  -q '.reviews[].author.login'  2>/dev/null | grep -i greptile || true)
  if [ -n "$COMMENTS$REVIEWS" ]; then echo "Greptile heeft gereageerd"; break; fi
  sleep 30
done
```

> Vervang de `greptile`-filter door de exacte bot-naam die in jullie repo comment, of
> poll Greptile's eigen API/webhook i.p.v. `gh`.

## 9. Comments verwerken (conditioneel)

- **Zijn er comments van Greptile?** Lees ze, beoordeel elk voorstel tegen de code,
  verwerk de terechte fixes en push. Bij twijfel: leg kort uit waarom je iets niet
  overneemt.
- **Geen comments?** Doe niets en ga door.

## 10. Nieuwe route? → rechten voor de PO

Controleer of er in deze wijziging een **nieuwe route** is toegevoegd.

> De `detect-route` hook geeft hier al een automatische reminder als een routebestand
> gewijzigd is. Verifieer het zelf ook:
> ```bash
> git diff main...HEAD -- <routes-pad>   # bv. routes/ of src/app/api/ of config/routes.rb
> ```

Is er een nieuwe route én zijn daar nieuwe **rechten/permissies** voor nodig die een
**PO** moet instellen?

- **Zo ja:** zet een duidelijke comment **onder de story** in Shortcut met: welke route,
  welke rechten, en dat de PO die moet aanmaken/toewijzen (@-mention de PO indien mogelijk).
  - Shortcut MCP: gebruik de "add comment to story"-tool op story `<STORY_ID>`.
  - Fallback via API:
    ```bash
    curl -s -X POST \
      -H "Content-Type: application/json" \
      -H "Shortcut-Token: $SHORTCUT_API_TOKEN" \
      -d '{"text":"⚠️ Nieuwe route toegevoegd — PO-actie nodig: rechten instellen. Route: <route>. Benodigde permissie(s): <permissie>."}' \
      "https://api.app.shortcut.com/api/v3/stories/<STORY_ID>/comments"
    ```
- **Zo nee:** niets doen.

## 11. Testen op localhost (subagent)

Laat een **subagent** de app lokaal draaien en de story-scenario's verifiëren:

> Spawn een Task: "Start de app lokaal (zie commando hieronder), test de acceptatiecriteria
> van story <STORY_ID> end-to-end, en rapporteer pass/fail met bewijs. Sluit de server weer
> af na afloop."

> Vul je eigen start-commando in, bv. `bin/rails server`, `npm run dev`, `docker compose up -d`.

De `SubagentStop`-hook checkt daarna of het testen echt is uitgevoerd en geslaagd.

## 12. Vastleggen in Obsidian

Leg de afgeronde story vast in je Obsidian-vault via de **Obsidian MCP**. Maak een nieuwe
notitie aan (of werk een bestaande bij) met een korte samenvatting, zodat je een
doorzoekbaar dev-logboek opbouwt.

> Pad-voorbeeld: `Dev Log/sc-<STORY_ID>.md`. Gebruik de create/append-note-tool van je
> Obsidian MCP.

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
<verwerkt: welke fixes / of: geen comments>

## PO-actie
<ja: welke route + rechten / nee>

## Test (localhost)
<pass/fail + bewijs>

## Geleerd / aandachtspunten
<optioneel>
```

## Afronden

Rapporteer beknopt: branch-naam, wat is gebouwd/gefixt, PR-link, of Greptile-comments zijn
verwerkt, of er een PO-actie onder de story staat, de testuitkomst, en het pad van de
aangemaakte Obsidian-notitie.
