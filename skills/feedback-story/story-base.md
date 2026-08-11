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

**Geldt voor élke regel code die je schrijft: geen inline code-comments.** Zet geen
uitleg-comments in de code (`#`, `//`, `/* */`, `<!-- -->`) — ook niet "even voor de
duidelijkheid", ook niet boven een methode, en ook niet in tests, migrations, views of
config. Dat is niet onze huisstijl en ik wil het niet terugzien in de diff. Laat de code
zichzelf uitleggen met duidelijke namen en kleine methodes. Moet er echt iets toegelicht
worden, dan hoort dat in de PR-beschrijving, onder de story of in de review-thread — niet
in het bestand.

- **Enige uitzondering:** comments die functioneel iets dóén, geen uitleg zijn. Denk aan
  `# frozen_string_literal: true`, `rubocop:disable`/`eslint-disable`, `@ts-expect-error`,
  annotaties die tooling leest, licentieheaders en comments die een generator zelf plaatst.
- **Bestaande comments laat je staan.** Ruim ze niet op als bijvangst van deze story; dat
  maakt de diff groter dan de wijziging.

---

## 0. Hervatten? — eerst kijken of er al werk ligt

Deze workflow loopt vaak over meerdere sessies: ik moet een plan goedkeuren, Greptile
reageert asynchroon, ik moet zeggen met welke gebruiker je mag testen en het daarna zelf in
de UI nalopen, en soms plak jij output terug. Begin daarom **nooit blind bij stap 1** —
controleer eerst of er al werk voor `sc-<STORY_ID>` bestaat.

```bash
git fetch --quiet origin 2>/dev/null || true
git branch --all --list "*sc-<STORY_ID>*"                     # bestaande branch?
gh pr list --search "sc-<STORY_ID>" --state all \
  --json number,state,url,headRefName 2>/dev/null             # bestaande PR?
ls -1 plan-sc-<STORY_ID>.md 2>/dev/null                       # bestaand plan?
```

Bepaal op basis van wat je vindt waar je verder gaat:

| Gevonden | Verder bij |
| --- | --- |
| Niets | Stap 1 — normaal beginnen |
| Alleen een plan-bestand | Stap 3 — plan afmaken en laten annoteren |
| Branch, geen PR | Stap 5 — uitvoeren; kijk eerst met `git log` en `git diff main...HEAD` wat er al staat |
| Open PR, nog geen Greptile-reactie | Stap 8 — wachten op review |
| Open PR mét Greptile-comments | Stap 9 — comments verwerken |
| PR gemerged of gesloten | Stap 10–13 — route/PO-check, staging, test, Obsidian |

**Harde regels bij hervatten:**
- Meld wat je gevonden hebt en welk instappunt je voorstelt, en **wacht op mijn bevestiging**
  voordat je stappen overslaat. Ga nooit stilzwijgend halverwege verder.
- Een gevonden plan-bestand betekent **niet** dat ik het heb goedgekeurd. De goedkeuringsgate
  van stap 3 sla je nooit over op basis van het bestaan van dat bestand — vraag expliciet of
  het plan al akkoord is.
- Haal de story (stap 1) **altijd** op, ook bij hervatten: je hebt de titel, de
  acceptatiecriteria en de branch-naam nodig.
- Bestaat er al een branch? Gebruik díe, maak geen tweede.

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
- Raakt dit een **interface**? Stel dan nu al vast of het een **Pulse-interface** is
  (zie stap 5) en verwerk dat in je plan.

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

### Het plan bevat de concrete code — niet alleen een beschrijving

Ik wil in het plan **zien hoe de code eruit komt te zien**, zodat ik op de code zelf kan
annoteren in plaats van op een samenvatting. Een plan dat alleen beschrijft *wat* er gaat
gebeuren ("we voegen validatie toe aan het formulier") is niet genoeg.

Geef daarom per stap:

- Het **bestandspad**, en of het bestand nieuw is of wordt gewijzigd.
- De **daadwerkelijke code** in een codeblok:
  - **Nieuw bestand** → de volledige inhoud zoals die eruit komt te zien.
  - **Bestaand bestand** → een diff-achtig fragment met genoeg omliggende regels om te zien
    waar het landt, en wat er precies weg gaat en bij komt.
- Bij een keuze tussen aanpakken: laat het verschil in code zien, niet alleen in woorden.

Wat je **niet** hoeft uit te schrijven: puur mechanisch werk waar niets aan te beslissen valt
(imports bijwerken, een string op tien plekken hernoemen, gegenereerde bestanden). Benoem dat
in één regel. Alles wat het ontwerp bepaalt — namen, signatures, datamodel, componentkeuze,
control flow, queries — hoort er wél als code in.

Deze code is een **voorstel**, geen uitvoering: schrijf in deze stap nog niets naar de
repository en maak nog geen branch. Dat gebeurt pas in stap 4 en 5.

> Raakt het een Pulse-interface (zie stap 5)? Laat de code dan al met Pulse-componenten zien
> (`ui.<naam>`, `Pulse::FormBuilder`), niet met losse HTML/Tailwind die je later nog omzet.

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

Bouw de code zoals die **in het goedgekeurde plan staat** — dat is waar ik akkoord op heb
gegeven. Blijkt tijdens het bouwen dat het anders moet (de code werkt niet, een aanname klopt
niet, er is een betere aanpak)? Meld dat expliciet met de reden en het verschil, in plaats van
stilzwijgend iets anders te bouwen dan ik heb goedgekeurd.

- **Met subagents:** verdeel onafhankelijke brokken werk over meerdere subagents zodat ze
  parallel kunnen werken; integreer daarna de resultaten.
- **Zonder subagents:** voer uit in de hoofdcontext. Delegeer geen gelijktijdige edits aan
  losse processen; een aparte, testgerichte run is optioneel als het werk echt onafhankelijk is.

### Werk je aan een interface? → check op Pulse

Raakt het werk een **interface** (view, pagina, form, component, layout, modal, tabel)?
Bepaal dan **eerst** of deze app **Pulse UI** gebruikt:

```bash
grep -rn "pulse" Gemfile package.json 2>/dev/null
rg -l "pulse_head|Pulse::|Pulse::Backend" app 2>/dev/null | head
```

- **Is het een Pulse-interface?** Dan **moet** je de **`pulse-ui`-skill** gebruiken en met
  Pulse-componenten bouwen (`ui.<naam>`, `Pulse::FormBuilder`), niet met losse
  HTML/Tailwind-markup of zelfgemaakte componenten.
  - **Claude Code:** roep de Skill-tool aan (skill `rails-toolkit:pulse-ui`).
  - **Andere harnessen (bv. Pi):** `read` de locatie van die skill zoals je harness die in
    de lijst met beschikbare skills toont, en volg hem.
  - Twijfel je of een component bestaat? Zoek het op in de skill; verzin geen eigen variant.
- **Geen Pulse?** Volg de bestaande UI-conventies van de repo.

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

Loop hierbij zelf ook nog even de diff na op **inline comments** die je hebt toegevoegd, en
haal ze weg (op de functionele uitzonderingen bovenaan na):

```bash
git diff main...HEAD | grep -nE '^\+\s*(#|//|/\*|<!--)'
```

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

### 9a. Hoe een reactie op GitHub eruitziet

Reacties onder een PR staan **op mijn naam**. Schrijf ze dus zoals ik ze schrijf, niet zoals
een agent ze zou schrijven. Dit is de belangrijkste regel van deze stap: liever te kort dan
te compleet.

**Vorm**
- **Nederlands**, tenzij de thread of de repo Engels is — dan Engels. Spiegel de taal van
  degene op wie je reageert.
- **Eén tot drie zinnen.** Meestal één. Loopt het langer, dan is het geen comment maar een
  discussie: plaats de conclusie in één zin en geef de volledige redenering aan **mij** in
  de chat.
- **Platte tekst.** Geen kopjes, geen bullets, geen **bold**/*cursief*, geen em-dash-ketens.
  Backticks alleen om een echte methode-, kolom- of klassenaam, niet om elk woord.
- Een codeblok, een link naar de patterns/docs of een verwijzing naar een andere PR mag —
  dat vervangt vaak drie zinnen uitleg.
- Zet `@greptile` aan het eind als de bot opnieuw moet kijken; `@naam` als je een collega
  iets vraagt.

**Per soort reactie**
- **Overgenomen:** `Fixed` of `Opgelost in <sha>: <in één regel wat er nu gebeurt>.` Verder
  niets — geen bewijsvoering, geen testverslag, geen uitleg waarom de fix klopt.
- **Niet overgenomen:** één zin met de reden, zonder pleidooi. "Bewuste keuze",
  "This will never happen", "Nope, want de limit kan 10 zijn en dan …". Eventueel één zin
  context erachter, meer niet.
- **Later:** zeg dat het bewust niet in deze PR zit en waarom in een halve zin.
  "Bewust niet in deze PR — die opruimstory staat later in de sprint."
- **Zelf een vraag:** stel hem gewoon. "Waarom heb je hier een aparte controller? In de
  story staat alleen een section op de afspraak."

**Niet doen** (dit zijn de tells van een agent-comment): openen met "Klopt deels, maar…",
meerdere alinea's om één afwijzing te onderbouwen, elke aanname staven met specs, regels en
commit-hashes, jargon als "blast radius", of afsluiten met "dat is een eigen story waard".
Als het argument echt zo groot is, hoort het in een story of in een gesprek — niet in een
review-thread.

**Voorbeelden zoals ik ze plaats**

```text
Bewuste keuze
Fixed
Opgelost in a7d8a80: de endpoint zoekt nu alleen actieve orders met status failed/rejected.
Dit kan alleen in een race condition gebeuren. De redirect werkt dan prima, dus laten we het zo. @greptile
Nee, dit is niet meer volgens de huidige conventies van Pulse: https://pulse.mobiel.io/docs/patterns/5-fields
Wil je dit niet gewoon in een method op het model zetten? Zoals in #8578.
```

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

## 11. Naar staging deployen? (vragen)

Vraag mij of deze branch naar **staging** moet. **Deploy nooit ongevraagd:** staging-omgevingen
zijn gedeeld, dus je zet er zo het werk van een collega mee overheen.

Het commando is altijd hetzelfde:

```bash
staging deploy <kanaal> <naam>
# voorbeeld: staging deploy sprint11 master
```

- **`<kanaal>`** = de sprint waar we nu in zitten, als één woord: `sprint<nummer>`. Leid dat
  af uit de iteration/sprint van story `<STORY_ID>` die je in stap 1 hebt opgehaald. Noem het
  nummer dat je gevonden hebt bij je vraag, zodat ik het kan corrigeren. Kun je de sprint niet
  vinden? Vraag het dan — gok geen sprintnummer.
- **`<naam>`** = de naam van de omgeving. Houd het op **één woord**, kort en makkelijk te
  onthouden (`master`, `msisdn`, `whitelist`). Geen story-id, geen branch-naam vol streepjes,
  geen datum.

Stel de vraag in één keer, zodat ik hem in één antwoord kan beantwoorden:

- Zal ik dit naar staging zetten?
- Kanaal `sprint<NN>` — dat is de sprint van deze story; klopt dat?
- Naam `<jouw voorstel van één woord>` — of wil je een andere?

Draai het commando **pas ná een expliciet akkoord**. Zorg dat je werk gepusht is (`git push
origin HEAD`) voordat je deployt, anders zet je een oude stand neer. Meld daarna het kanaal
en de naam terug, zodat ik weet waar ik moet kijken.

- Staat er al iets anders op die omgeving? **Beslis niet zelf dat je het overschrijft** —
  meld wat je ziet en vraag of ik een andere naam wil.
- Bestaat het `staging`-commando niet in deze omgeving? Meld dat in één regel en sla de stap
  over; ga niet zelf een deploy in elkaar knutselen met tags of workflows.

## 12. Testen

### 12a. Vraag eerst met welke gebruiker (verplicht)

Groene tests en een schone diff zeggen weinig over wat er in het scherm gebeurt. **Vraag mij
daarom, vóórdat je gaat testen, met welke gebruiker ik het getest wil hebben.** Raad geen
account, verzin geen inloggegevens en pak niet zomaar de eerste user uit de seeds — het
gedrag hangt vaak af van rol en rechten, en met de verkeerde gebruiker test je de
acceptatiecriteria niet.

Stel de vraag concreet en in één keer, zodat ik hem in één antwoord kan beantwoorden:

- **Welke gebruiker/rol?** (bv. e-mailadres of rol — backoffice, PO, klant, admin)
- Zijn er **meerdere rollen** die dit raken? Dan: welke moet ik zeker zien werken?
- Klopt de **URL/het scherm** waar ik moet zijn (bv. `/pulse/procurement/expected_fundings`)?
- Is er iets nodig om bij de situatie te komen — een specifieke **order/record**, een
  feature-flag, of een status waarin het record moet staan?

Antwoord ik niet of weet ik het niet? Ga dan niet alsnog gokken: test wat je zonder login
kunt testen, en meld expliciet dat de UI-check op een gebruiker wacht.

### 12b. Zelf testen

Start de app lokaal volgens de repository-instructies, log in als de gebruiker uit 12a en
verifieer de acceptatiecriteria van story `<STORY_ID>` end-to-end **via de UI** — dus echt
door het scherm heen klikken, niet alleen via console of specs. Rapporteer pass/fail met
concreet bewijs (screenshot, URL, wat je zag) en sluit alle gestarte servers/processen na
afloop af. Bij een failure: herstel, draai de relevante checks opnieuw en herhaal de test.

- **Met subagents:** laat een subagent de app draaien en de scenario's testen ("Start de app
  lokaal, log in als `<gebruiker uit 12a>`, test de acceptatiecriteria van story `<STORY_ID>`
  end-to-end via de UI, rapporteer pass/fail met bewijs, sluit de server daarna af"). Een
  `SubagentStop`-hook checkt daarna of het testen echt is uitgevoerd.
- **Zonder subagents:** doe het in de hoofdcontext of in een geïsoleerde, testgerichte run
  (bv. `pi -p "... test uitsluitend de acceptatiecriteria van story <STORY_ID> ... wijzig geen
  code en sluit de server na afloop af"`).
- **Met browserautomatisering** (bv. Claude in Chrome/Playwright): gebruik die om de flow
  echt door te klikken in plaats van alleen de pagina op te halen.

> Vul je eigen start-commando in, bv. `bin/rails server`, `npm run dev`, `docker compose up -d`.

### 12c. Vraag mij om het na te lopen in de UI

Je eigen test is niet de laatste stap. **Vraag mij daarna om het zelf in de UI te
controleren** en zeg er expliciet bij met welke gebruiker. Zeg niet dat de story klaar is
voordat ik dat bevestigd heb.

Houd die vraag kort en klikbaar — geen samenvatting van de implementatie:

```text
Kun je dit even nalopen op <localhost of staging-kanaal> als <gebruiker/rol>?
1. Ga naar <URL>
2. <handeling>
3. Verwacht: <resultaat>

Zelf getest als <gebruiker>: <wat wel/niet werkte>. Nog niet gecontroleerd: <wat je niet kon testen>.
```

Staat het na stap 11 op staging? Noem dan het kanaal en de naam erbij, zodat ik kan kiezen of
ik het daar of op localhost nakijk.

Vertel er eerlijk bij wat je **niet** hebt kunnen testen (geen account, geen data, flow niet
te bereiken). Meld ik een probleem? Herstel het, draai de relevante checks opnieuw en vraag
opnieuw om een UI-check.

## 13. Vastleggen in Obsidian

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
- **Type:** <feature | bug | feedback>
- **Uitkomst:** <geïmplementeerd | geen wijziging — reden>
- **Branch:** <branch-naam of n.v.t.>
- **PR:** <pr-link of n.v.t.>
- **Staging:** <kanaal + naam, bv. `sprint11 master` — of niet gedeployed>

## Wat is gebouwd / gefixt
<korte samenvatting van de wijzigingen>

## Validatie / scope-check
<bug: de read-only script-output die de oorzaak bevestigde — feedback: de uitkomst van de
scope-check — feature: n.v.t.>

## Greptile
<verwerkt: welke fixes / geen comments / timeout>

## PO-actie
<ja: welke route + rechten / nee>

## Test (localhost)
<met welke gebruiker/rol getest + pass/fail + bewijs — en of ik het zelf in de UI bevestigd heb>

## Geleerd / aandachtspunten
<optioneel>
```

## Afronden

Rapporteer beknopt: branch-naam, wat is gebouwd/gefixt, PR-link, Greptile-status, eventuele
PO-actie onder de story, het staging-kanaal + de naam (of dat er niet gedeployed is), de
testuitkomst (met welke gebruiker getest, en wat je niet hebt kunnen testen), en het pad van
de aangemaakte Obsidian-notitie. Noem de story pas klaar als
ik de UI-check uit stap 12c bevestigd heb.
