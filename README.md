# personal-skills-plugin

Persoonlijke agent-skills voor mijn Shortcut-workflow, verpakt als één plugin die
werkt in **Claude Code** én **Pi**. De skills triggeren via slash-commands en volgen
een gedeelde, stap-voor-stap basis-workflow.

## Wat zit erin

| Skill | Command | Wat het doet |
| --- | --- | --- |
| `feature-story` | `/feature-story <story-id>` | Pakt een Shortcut **feature**-story end-to-end op: ophalen → analyseren → plannen → branch → uitvoeren → PR → review → localhost-test → vastleggen in Obsidian. |
| `bug-story` | `/bug-story <story-id>` | Zelfde workflow als hierboven, met **één extra harde gate (stap 2b)**: eerst de oorzaak valideren met een read-only Ruby-script tegen echte data, vóórdat er een plan komt. |

Beide skills lezen dezelfde 12-staps basis in
[`skills/_shared/story-base.md`](skills/_shared/story-base.md). `_shared` is geen losse
skill (geen `SKILL.md`), dus het verschijnt niet als command — het is alleen de gedeelde
spine die de twee wrappers inlezen.

De inhoud is **harness-agnostisch** geschreven: waar Claude Code en Pi verschillen
(subagents, hooks, arg-injectie, reviewbot-watcher) kiest de workflow de juiste aanpak op
basis van wat je harness kan. Zo is er één bron voor beide. `allowed-tools` staat bewust
**niet** in de frontmatter — dat veld heeft per harness een ander formaat en zou tools
kunnen uitschakelen; zonder het veld gebruiken beide harnessen hun normale permissies.

```text
skills/
├── _shared/
│   └── story-base.md      ← gedeelde 12-staps workflow (geen SKILL.md → geen los command)
├── feature-story/
│   └── SKILL.md           ← /feature-story <id>
└── bug-story/
    └── SKILL.md           ← /bug-story <id>
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

> **Alternatief — direct in `~/.claude/skills/`** (zonder plugin-mechanisme):
> ```bash
> git clone https://github.com/Frank4lkema/personal-skills-plugin.git
> cp -R personal-skills-plugin/skills/* ~/.claude/skills/
> ```
> Kopieer daarbij óók de map `_shared/` mee — de wrappers verwijzen ernaar via het
> relatieve pad `../_shared/story-base.md`.

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
  `skills/_shared/story-base.md` aan; beide commands nemen de wijziging over.
- **Alleen feature** of **alleen bug** → pas de betreffende `SKILL.md` aan (de bug-wrapper
  bevat de extra validatie-gate 2b).

Vervang overal `<STORY_ID>` mentaal door het meegegeven argument (`$ARGUMENTS`).
