---
name: create-story
description: >
  Use when you want to quickly create a Shortcut story from a one-line intent, written in
  Anneke's story style (short `### Context`, checkbox `### Acceptatie`, optional
  `### Technische hints`) with the team fields already filled in. Typically via a
  `create-story <wat er moet gebeuren>` command. Triggers on "maak een story",
  "zet dit in Shortcut" or dictating a task that should land on the board.
disable-model-invocation: true
argument-hint: "[wat er moet gebeuren] [--go]"
---

# Create Story

Maak snel één Shortcut-story van wat ik in één zin roep, **geschreven zoals Anneke haar
stories schrijft**: een korte context, afvinkbare acceptatiecriteria en alleen extra secties
als er echt iets in hoort. De velden staan meteen goed.

## Agentindeling

Voer deze workflow volledig zelf uit als hoofdagent. Start geen subagents voor onderzoek,
schrijven of aanmaken van de story; deze workflow heeft geen aparte reviewstap.

## Wat ik meegeef

Alles achter het command is de intentie (`$ARGUMENTS`). Is die leeg, vraag dan in één regel
wat de story moet worden. Staat `--go` erin, sla dan de bevestiging over en maak hem direct aan.

## 1. Schrijf de story in Annekes stijl

Afgeleid uit Annekes laatste stories (als requester of Eindbaas). Houd het net zo kort als
zij: de meeste stories zijn een paar zinnen context en één tot drie acceptatiecriteria.

### Titel

Eén regel, Nederlands, geen story-id, geen prefix, geen punt aan het eind. Kleine letters
behalve namen (Pulse, DrIndex, Lebara).

| Soort | Vorm | Voorbeelden van Anneke |
|---|---|---|
| Feature / chore | onderwerp + infinitief | `Totaalregel toevoegen aan transacties`, `Delayed job weghalen uit DrIndex`, `Icon toevoegen aan Pulse`, `Patch doorvoeren rails 8.1.4 Pulse` |
| Bug | constatering van wat er misgaat | `Voorraadwaarde verschilt tussen 2 schermen`, `Processable order update niet wanneer AIT datum bereikt is` |
| Onderzoek | `Onderzoek …` / `Uitzoeken …` / `Voorstel …` | `Onderzoek alternatief remove bg`, `Uitzoeken mogelijkheid basement meetellen met voorraadwaarde` |

Geen user-story-vorm (`Als … wil ik …`) in de titel.

### Beschrijving

Vaste opbouw in markdown, secties gescheiden door `---`:

```markdown
### Context
<huidige situatie en waarom het anders moet, 1–3 zinnen>

---
### Acceptatie
- [ ] <gewenste eindtoestand>
    - [ ] <detail of specificatie>

---
### Technische hints
<alleen als ik iets technisch meegeef>
```

**Context**

- Schrijf in de wij-vorm en begin bij de huidige situatie: `Op dit moment …`, `We willen …`,
  `Wanneer een case opgestart wordt, …`, `Er is behoefte aan …`. Eindig met waarom het anders
  moet (`Dit is onnodig handwerk en kan geautomatiseerd worden.`, `Dat is geen gewenst gedrag.`).
- Verwijs naar eerdere stories als `sc-12345` in de zin: `In story sc-136231 hebben we …`.
- Links krijgen een beschrijvende linktekst: `[het voorraadoverzicht](https://…)`,
  `[order 5067986](https://…)`. Alleen links die ik zelf aanlever.
- Laat `### Context` weg als de titel alles al zegt (een Rails-patch, een icon toevoegen);
  begin dan direct met `### Acceptatie`.

**Acceptatie** — altijd aanwezig.

- Elk criterium is een checkbox `- [ ]` en beschrijft de **eindtoestand** in de
  tegenwoordige tijd: `Pulse draait op Rails 8.1.4`, `Bij Verwerking > Wacht op kan de optie
  "Klant" gekozen worden`.
- Gedrag schrijf je als `Wanneer <situatie>, <resultaat>`: `Wanneer er geen IMEI meer op de
  order staat, wordt … gekeken naar de meest recente waarde uit de IMEI monitor`.
- Details en specificaties nest je met vier spaties eronder (`    - [ ]`), bijvoorbeeld de
  exacte tekst, icon, kleur of tijdstip.
- Wat níet mag veranderen is ook een criterium: `Sim-only orders blijven werken zoals nu`.
- Bug zonder bekende oorzaak: `Oorzaak gevonden en verholpen`, of het gewenste gedrag als
  dat duidelijk is.
- Onderzoek: in de gebiedende wijs, eindigend met een vervolgstap:
  `Kom met een voorstel …` → `Bespreek die met het team` → `Maak een story voor de gekozen
  oplossingsrichting`.
- Technische waarden, statussen en UI-namen in backticks: `waiting_on_case_items`,
  `alert-triangle`, `use_verification_plan`.
- Nuances tussen haakjes of als losse regel: `(geen blokkade)`, `is nice to have`,
  `Let op: …`.

**Optionele secties** — alleen als ik er inhoud voor geef, nooit leeg of verzonnen:

- `### Technische hints` — bestand en methode in backticks, een link naar PR, docs of
  Slack-thread; een vermoeden mag als vraag (`Als @order_status_text leeg is, dan geen mail
  versturen?`).
- `### Design` — als ik screenshots of een ontwerp aanlever.
- Een eigen kopje voor vaste inhoud zoals exacte teksten of opties (`### Plain text`,
  `### Opties per type case`).

**Toon** — zakelijk maar los, zoals Anneke praat. Afkortingen als `obv`, `o.a.`, `ipv` zijn
prima. Geen kopjes als `Doel`, `Probleemstelling` of `User Story`, geen inleiding, geen
samenvatting van wat ik net zei.

**Weet je iets niet** (welk scherm, welke rol, welk gedrag)? **Verzin het niet.** Schrijf de
story met wat ik gaf en noem de open vraag apart aan mij — niet in de story.

### Voorbeelden

```markdown
### Context
Een aftersales case kan gearchiveerd worden, maar er wordt nu niet getoond door wie dat is gedaan wat soms tot verwarring leidt.

---
### Acceptatie
- [ ] Wanneer een case wordt gearchiveerd, wordt de gebruiker die dit heeft gedaan getoond boven "type" in het blokje case
    - [ ] Als de case nog niet gearchiveerd is, wordt dit veld nog verborgen
```

```markdown
### Context
In de security sessie van 27/10, is aangekaart dat we Graph iets te weinig beveiligd hebben.

---
### Acceptatie
- [ ] Kom met ~3 voorstellen om de security van de Graph API key te verbeteren
- [ ] Bespreek die met het team + devops
- [ ] Maak een story voor de gekozen oplossingsrichting

---
### Technische hint
- Als het voorstel is dat we de key gewoon rouleren, kijk dan naar infisical
```

## 2. Zet de velden

Deze staan vast en hoef je niet te vragen:

| Veld | Waarde |
|---|---|
| `workflow_state_id` | `500023269` (New) |
| Skill Set | Backend — `{"field_id":"62161890-d774-4119-ae15-cb49af4e9d7b","value_id":"62161890-3b0c-4fc3-9320-3a335dd3d667"}` |
| Eindbaas | Anneke — `{"field_id":"6aad28b2-632b-4cc1-bb38-238dbcf637e1","value_id":"6aad28b2-d285-44a7-9eab-ddb4158882fa"}` |

**Story type** — leid af uit de intentie: iets werkt niet → `bug`; onderhoud, opruimen,
dependencies, verplaatsen → `chore`; al het andere → `feature`.

**Waar hoort hij thuis** — dit is de enige echte keuze:

- **Standaard: project Verbeteringen** → `"project_id": 19`, géén `group_id`. Dat is waar
  het meeste van mijn eigen werk landt.
- **Zeg ik dat het voor het team / de sprint is?** Dan het Backend-team plus de lopende
  sprint, geen project:
  ```bash
  BACKEND=60daea0f-f808-4cbb-b614-bd9edd713929
  curl -s -H "Shortcut-Token: $SHORTCUT_TOKEN" "https://api.app.shortcut.com/api/v3/iterations" \
    | python3 -c "import json,sys;print([i['id'] for i in json.load(sys.stdin) if i['status']=='started' and '$BACKEND' in (i.get('group_ids') or [])])"
  ```
  Gebruik die id als `iteration_id` en `"group_id": "$BACKEND"`.
- **Zeg ik "urgent"?** → `"project_id": 25992`, geen team.

**Product Area** (`field_id: 62161890-cae9-4413-9b0c-5a028220894f`) — kies op onderwerp:

| Onderwerp | value_id |
|---|---|
| Orderverwerking, orders, leveringen | `62161890-f346-40b5-a2f5-941cd705e0ea` |
| Producten, proposities, productbeheer | `62161890-dbd7-43f3-88af-0bd59e6489e7` |
| Platform, integraties, dependencies, techniek | `68259aed-ffe7-45a4-8213-c227867242d3` |
| Finance, facturen, vergoedingen | `68259aed-cbad-4b8e-86cf-8bbf2ccdacab` |
| Aftersales, cases, magic fields | `6ac39761-a392-4dd3-bab9-a38a1c1abad0` |
| Bestellen & afronden (checkout) | `62161890-98eb-4300-a302-35720ff7c3d4` |
| Shop-ervaring | `62161890-6251-4227-89ea-e2520fe1ec48` |

Past er geen enkele echt? Laat het veld dan weg — liever leeg dan verkeerd.

**Laat weg tenzij ik erom vraag:** priority, reviewer, labels, estimate, owner. Die zet ik
zelf wel als ze nodig zijn.

## 3. Laat het zien, maak het aan

Toon wat je gaat aanmaken — de titel, de volledige beschrijving zoals hij in Shortcut komt,
en op één regel de velden (type, project of team+sprint, product area). Wacht op mijn "ja"
en maak hem dan aan. Staat `--go` in het command, sla het wachten over.

De beschrijving is meerregelige markdown; bouw de payload daarom met `jq` zodat newlines en
quotes goed ge-escaped worden:

```bash
jq -n \
  --arg name "<titel>" \
  --arg description "<beschrijving in Annekes stijl>" \
  --arg story_type "<feature|bug|chore>" \
  --arg product_area "<product-area value_id>" \
  '{
    name: $name,
    description: $description,
    story_type: $story_type,
    workflow_state_id: 500023269,
    project_id: 19,
    custom_fields: [
      {field_id: "62161890-d774-4119-ae15-cb49af4e9d7b", value_id: "62161890-3b0c-4fc3-9320-3a335dd3d667"},
      {field_id: "6aad28b2-632b-4cc1-bb38-238dbcf637e1", value_id: "6aad28b2-d285-44a7-9eab-ddb4158882fa"},
      {field_id: "62161890-cae9-4413-9b0c-5a028220894f", value_id: $product_area}
    ]
  }' \
| curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Shortcut-Token: $SHORTCUT_TOKEN" \
    -d @- \
    https://api.app.shortcut.com/api/v3/stories
```

Pas `project_id` / `group_id` / `iteration_id` aan volgens stap 2 en laat de product-area
regel weg als je geen passende hebt gekozen.

Geen token in `$SHORTCUT_TOKEN`? Zeg dat en stop — ga niet via de browser.

## 4. Rapporteer

Eén regel: `✅ sc-<id> — <titel>` met de link
`https://app.shortcut.com/mobielnl/story/<id>`. Waren er open vragen uit stap 1, noem ze
daaronder in maximaal twee regels.

> Meer nodig dan dit (een story bijwerken, een veld dat hier niet in staat, leden opzoeken)?
> Gebruik dan de `shortcut-story-api`-skill; die heeft de volledige veldtabellen.
