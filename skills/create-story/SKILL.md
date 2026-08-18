---
name: create-story
description: >
  Use when you want to quickly create a Shortcut story from a one-line intent — short title,
  a description of at most three sentences, and the team fields already filled in. Typically
  via a `create-story <wat er moet gebeuren>` command. Triggers on "maak een story",
  "zet dit in Shortcut" or dictating a task that should land on the board.
disable-model-invocation: true
argument-hint: "[wat er moet gebeuren] [--go]"
---

# Create Story

Maak snel één Shortcut-story van wat ik in één zin roep. **Kort houden is het punt van deze
skill:** een titel en maximaal drie zinnen, met de velden meteen goed gezet.

## Wat ik meegeef

Alles achter het command is de intentie (`$ARGUMENTS`). Is die leeg, vraag dan in één regel
wat de story moet worden. Staat `--go` erin, sla dan de bevestiging over en maak hem direct aan.

## 1. Schrijf de story

**Titel** — één regel, Nederlands, concreet en in de gebiedende wijs of als constatering.
Zoals ik ze zelf schrijf: `Presets op claimlines`, `Filterpill factuurstatus mist op
/purchase_order_lines`, `Valideer product-slugs in ProductAdmin`. Geen story-id, geen prefix
als "Story:" of "Taak:", geen punt aan het eind.

**Beschrijving** — **maximaal drie zinnen.** Wat er moet gebeuren en waarom, klaar.

- Geen kopjes (`### Doel`, `### Achtergrond`), geen inleiding, geen samenvatting van wat ik
  net zei in andere woorden.
- Geen acceptatiecriteria-lijst tenzij ik er zelf om vraag; is er echt een randvoorwaarde,
  zet die in de derde zin.
- Weet je iets niet (welk scherm, welke rol, welk gedrag)? **Verzin het niet.** Schrijf de
  story met wat ik gaf en noem de open vraag apart aan mij — niet in de story.

## 2. Zet de velden

Deze staan vast en hoef je niet te vragen:

| Veld | Waarde |
|---|---|
| `workflow_state_id` | `500023269` (New) |
| Skill Set | Backend — `{"field_id":"62161890-d774-4119-ae15-cb49af4e9d7b","value_id":"62161890-3b0c-4fc3-9320-3a335dd3d667"}` |
| Eindbaas | Anneke — `{"field_id":"69662730-1660-4da2-a165-0c7ee4af9bb4","value_id":"69662730-a2b1-4b08-a817-2731bbaa71b0"}` |

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
| Bestellen & afronden (checkout) | `62161890-98eb-4300-a302-35720ff7c3d4` |
| Shop-ervaring | `62161890-6251-4227-89ea-e2520fe1ec48` |

Past er geen enkele echt? Laat het veld dan weg — liever leeg dan verkeerd.

**Laat weg tenzij ik erom vraag:** priority, reviewer, labels, estimate, owner. Die zet ik
zelf wel als ze nodig zijn.

## 3. Laat het zien, maak het aan

Toon in één compact blok wat je gaat aanmaken — titel, de drie zinnen, en op één regel de
velden (type, project of team+sprint, product area). Wacht op mijn "ja" en maak hem dan aan.
Staat `--go` in het command, sla het wachten over.

```bash
curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Shortcut-Token: $SHORTCUT_TOKEN" \
  -d '{
    "name": "<titel>",
    "description": "<max 3 zinnen>",
    "story_type": "<feature|bug|chore>",
    "workflow_state_id": 500023269,
    "project_id": 19,
    "custom_fields": [
      {"field_id":"62161890-d774-4119-ae15-cb49af4e9d7b","value_id":"62161890-3b0c-4fc3-9320-3a335dd3d667"},
      {"field_id":"69662730-1660-4da2-a165-0c7ee4af9bb4","value_id":"69662730-a2b1-4b08-a817-2731bbaa71b0"},
      {"field_id":"62161890-cae9-4413-9b0c-5a028220894f","value_id":"<product-area>"}
    ]
  }' \
  https://api.app.shortcut.com/api/v3/stories
```

Geen token in `$SHORTCUT_TOKEN`? Zeg dat en stop — ga niet via de browser.

## 4. Rapporteer

Eén regel: `✅ sc-<id> — <titel>` met de link
`https://app.shortcut.com/mobielnl/story/<id>`. Waren er open vragen uit stap 1, noem ze
daaronder in maximaal twee regels.

> Meer nodig dan dit (een story bijwerken, een veld dat hier niet in staat, leden opzoeken)?
> Gebruik dan de `shortcut-story-api`-skill; die heeft de volledige veldtabellen.
