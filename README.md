# personal-skills-plugin

Persoonlijke agent-skills voor mijn Shortcut-workflow, verpakt als één plugin die
werkt in **Claude Code** én **Pi**. De skills triggeren via slash-commands en volgen
een gedeelde, stap-voor-stap basis-workflow.

## Wat zit erin

| Skill | Command | Wat het doet |
| --- | --- | --- |
| `feature-story` | `/feature-story <story-id>` | Pakt een Shortcut **feature**-story end-to-end op: ophalen → analyseren → plannen → branch → uitvoeren → PR → review → localhost-test → vastleggen in Obsidian. |
| `bug-story` | `/bug-story <story-id>` | Zelfde workflow, met **één extra harde gate (stap 2b)**: eerst de oorzaak valideren met een read-only Ruby-script tegen echte data, vóórdat er een plan komt. |
| `feedback-story` | `/feedback-story <story-id>` | Zelfde workflow, met als gate 2b een **scope-check**: past de melding in klein bestek? Zo niet (of is er geen wijziging nodig), dan eindigt de story zonder code — comment onder de story + Obsidian-notitie. |

Alle drie de skills volgen dezelfde basis, die begint met een **hervatten-check (stap 0)**:
bestaat er al een branch, PR of plan voor deze story, dan stelt de workflow voor om daar
verder te gaan in plaats van bij stap 1. De **bron** van de basis staat in
[`skills/_shared/story-base.md`](skills/_shared/story-base.md); elke skill-map bevat een
**gegenereerde kopie** (`story-base.md`) zodat elke skill self-contained is en ook los
installeerbaar via tools als `npx skills`. De kopieën houd je bij met `npm run sync`.

De inhoud is **harness-agnostisch** geschreven: waar Claude Code en Pi verschillen
(subagents, hooks, arg-injectie, reviewbot-watcher) kiest de workflow de juiste aanpak op
basis van wat je harness kan. Zo is er één bron voor beide. `allowed-tools` staat bewust
**niet** in de frontmatter — dat veld heeft per harness een ander formaat en zou tools
kunnen uitschakelen; zonder het veld gebruiken beide harnessen hun normale permissies.

```text
skills/
├── _shared/
│   └── story-base.md      ← BRON van de gedeelde workflow (hier bewerken)
├── feature-story/
│   ├── SKILL.md           ← /feature-story <id>
│   └── story-base.md      ← gegenereerde kopie (npm run sync)
├── bug-story/
│   ├── SKILL.md           ← /bug-story <id>
│   └── story-base.md      ← gegenereerde kopie (npm run sync)
└── feedback-story/
    ├── SKILL.md           ← /feedback-story <id>
    └── story-base.md      ← gegenereerde kopie (npm run sync)
```

## Installeren

### Claude Code

De repo is tegelijk een **plugin-marketplace**. Voeg hem toe en installeer de plugin:

```text
/plugin marketplace add Frank4lkema/personal-skills-plugin
/plugin install story-skills@personal-skills-plugin
```

Herstart daarna Claude Code (of `/plugin` → reload). De commands `/feature-story` en
`/bug-story` zijn dan beschikbaar.

> **Alternatief** — de skills zijn self-contained, dus `npx skills` (zie de
> Cursor-sectie hieronder) werkt ook voor Claude Code, of kopieer handmatig:
> ```bash
> git clone https://github.com/Frank4lkema/personal-skills-plugin.git
> cp -R personal-skills-plugin/skills/feature-story personal-skills-plugin/skills/bug-story ~/.claude/skills/
> ```

### Pi

De repo is ook een Pi-package (zie `package.json` → `pi.skills`). Installeer direct vanaf
GitHub:

```bash
pi install git:github.com/Frank4lkema/personal-skills-plugin
```

Voor lokale ontwikkeling kun je de checkout als tijdelijke package laden:

```bash
pi -e /pad/naar/personal-skills-plugin
```

Pi heeft native skills, dus er is geen compatibiliteits-`Skill`-tool nodig — dezelfde
`skills/`-map wordt geladen.

### Cursor (en andere agents) — via `npx skills`

Cursor ondersteunt de [Agent Skills-standaard](https://cursor.com/docs/skills) native.
De makkelijkste route is de open [`skills`-CLI](https://github.com/vercel-labs/skills):
die detecteert automatisch welke agents je hebt (Cursor, Claude Code, Codex, …), zet één
canonieke kopie neer en symlinkt die naar de skills-map van elke agent:

```bash
npx skills add Frank4lkema/personal-skills-plugin -g
```

Herstart daarna Cursor. De skills zijn op te roepen via `/` in de Agent-chat (zoek op
`feature-story` of `bug-story`).

**Bijwerken** kan met één command; alle geïnstalleerde skills worden dan op de nieuwste
versie uit hun bron-repo gebracht:

```bash
npx skills update
```

> **Noten**
> - Dit werkt omdat elke skill-map self-contained is: de basis-workflow zit als
>   gegenereerde kopie ín de skill-map. Installers zoals `npx skills` nemen namelijk
>   alleen mappen mét een `SKILL.md` mee.
> - Heb je de skills al via Claude Code in `~/.claude/skills/` staan? Cursor leest die
>   map ook (backwards-compatibiliteit) — dubbel installeren is dan niet nodig.

## Updates ontvangen

Hoe nieuwe versies van de skills bij de gebruiker terechtkomen verschilt per harness:

| Harness | Ziet nieuwe versies zelf? | Hoe update je |
| --- | --- | --- |
| **Claude Code** (plugin) | ✅ Ja, na eenmalige toggle | Zet auto-update één keer aan via `/plugin` → `personal-skills-plugin` → **auto-update** (staat voor third-party marketplaces standaard uit). Claude Code checkt daarna na elke sessiestart op de achtergrond en meldt `/reload-plugins` als er iets is bijgewerkt. |
| **Pi** | ❌ Nee | `pi update --all` (of `--extensions`) trekt alle git-packages naar de laatste versie. Werkt zolang je zonder vaste `@ref` installeerde. |
| **Cursor e.a.** (`npx skills`) | ❌ Nee | `npx skills update`. Volledig automatisch? Zet het in een cron-regel (`crontab -e`), bv. dagelijks om 9:00: `0 9 * * * npx -y skills update`. |

Voor maintainers: het versienummer staat op **drie** plekken en die moeten gelijk blijven —
`.claude-plugin/marketplace.json` (hierop detecteert Claude Code updates),
`.claude-plugin/plugin.json` en `package.json` (Pi/npm). **Bump alle drie bij elke
wijziging**, anders zien gebruikers de update niet. `npm run sync` controleert dit en
faalt als ze uiteenlopen.

## Afhankelijkheden

De skills verwijzen naar mijn eigen omgeving. Zonder deze werkt de workflow deels, maar
niet volledig:

- **Shortcut** — API-token in `$SHORTCUT_TOKEN` / `$SHORTCUT_API_TOKEN`; en de
  `shortcut-toolkit:shortcut-story-api`-skill voor het ophalen van stories.
- **Plannotator** — CLI (`plannotator annotate` / `plannotator review`) voor plan-annotatie
  en self-review.
- **Greptile** — reviewbot op de PR's.
- **Obsidian MCP** — voor het dev-logboek aan het eind.
- Hooks (formatteren/linten/`verify-done`/route-detectie) draaien in mijn eigen setup en
  zijn geen onderdeel van deze repo.

## Skills aanpassen

- **Gedeelde stappen** (ophalen, plannen, PR, testen, vastleggen) → pas
  `skills/_shared/story-base.md` aan en draai daarna **`npm run sync`** om de kopieën in
  de skill-mappen bij te werken (commit de kopieën mee). Bewerk de kopieën nooit direct —
  ze worden overschreven.
- **Eén skill apart** → pas de betreffende `SKILL.md` aan. De bug-wrapper bevat de
  validatie-gate 2b, de feedback-wrapper de scope-check 2b plus de afslag zonder code.
- **Nieuwe skill erbij** → maak `skills/<naam>/SKILL.md` en voeg `<naam>` toe aan de lijst in
  `scripts/sync-shared.sh`, anders krijgt die map geen kopie van de basis.

Vervang overal `<STORY_ID>` mentaal door het meegegeven argument (`$ARGUMENTS`).
