---
name: uitleg
description: >
  Use when you want to understand how something in this codebase actually works and want that
  explained in plain language, typically via a `uitleg <onderwerp>` command. Researches the
  current repo plus sibling repos one directory up (read-only, including git history) and
  writes a lasting explanation note to `Codebase/` in Obsidian. Triggers on "leg uit hoe X
  werkt", "hoe zit X in elkaar", "zoek uit waarom X zo is". Not for implementing changes.
disable-model-invocation: true
argument-hint: "[onderwerp]"
---

# Uitleg

Uitzoeken hoe iets in deze codebase écht werkt, en dat uitleggen in taal die ik snap —
niet in jargon en niet als code-dump. Het resultaat is een blijvende notitie in mijn
Obsidian-vault onder `Codebase/`, bedoeld als naslag. **Dit is geen dev-logboek** zoals bij
de story-skills: hier staat niet wat er die dag is gebouwd, maar hoe het systeem in elkaar zit.

**Deze skill wijzigt niets.** Geen code, geen commits, geen branches, geen migraties, geen
servers starten. Alles wat je in de repo's doet is lezen. Het enige dat je aanmaakt of
bijwerkt is de notitie in de vault.

## Pas aan je harness aan

- **Subagents** (bv. Claude Code `Task`/`Explore`)? Laat die het zoekwerk doen — één per
  deelvraag of per repo — en houd de hoofdcontext voor het begrijpen en schrijven. Geen
  subagents (bv. Pi standaard)? Doe het read-only in de hoofdcontext.
- **Vault-toegang:** gebruik de Obsidian MCP of de `obsidian-cli`-skill. Weet je het vaultpad
  niet? Vraag het — raad het niet en schrijf niet zomaar ergens een bestand neer.

## 1. Onderwerp scherpstellen

Alles achter het command is het onderwerp (`$ARGUMENTS`). Is het leeg, vraag dan in één regel
wat ik uitgelegd wil hebben.

Is het onderwerp breed ("de orderflow", "hoe werkt facturatie"), begin dan tóch — maar zeg in
één regel welke afbakening je kiest en waar je stopt, zodat ik kan bijsturen voordat je een
uur zoekt. Wacht daar niet op: ga na die regel gewoon door.

## 2. Uitzoeken — deze repo én één map hoger

Zoek net zo lang tot je het **mechanisme** kunt navertellen, niet alleen de namen van klassen
en bestanden. Volg de flow end-to-end: waar komt het binnen, wat gebeurt er onderweg, waar
landt het, wie roept het aan, wat gebeurt er bij een fout.

- **Deze repo eerst.** Entry points (routes, jobs, commands, events), de modellen/services
  eromheen, de tests die het gedrag vastleggen, en de config/feature-flags die het aan- of
  uitzetten.
- **Dan één map hoger.** De repo's die naast deze staan (`ls ..`) horen vaak bij hetzelfde
  systeem — frontend, API, worker, scripts. Kijk daar of het onderwerp verder loopt: wie roept
  ons aan, wat verwachten zij van ons, welk contract zit ertussen. Lezen mag overal; wijzigen
  nergens.
- **Git-historie gebruik je om het *waarom* te vinden.** Code vertelt wat er gebeurt, de
  historie waarom het zo geworden is. Zoek de commit die het introduceerde en lees de
  boodschap en de PR erbij:

  ```bash
  git log --oneline -- <pad>                    # wanneer en waarom is dit ontstaan
  git log -S"<functienaam of string>" --oneline  # welke commit voerde dit gedrag in
  git blame -L <van>,<tot> <bestand>             # wie schreef juist deze regels
  git log --oneline --merges -- <pad>            # de PR-merges eromheen
  ```

  Doe dat ook in de zusterrepo's als het onderwerp daar doorloopt.

**Verifieer je aannames in de code.** Vind je geen bewijs voor iets, dan is het geen conclusie
maar een open vraag — die hoort in de notitie onder "Wat ik niet zeker weet". Verzin geen
werking die je niet hebt kunnen aanwijzen, en presenteer een vermoeden nooit als feit.

## 3. Uitleggen in gewone taal

Schrijf voor mij op een moment dat ik dit stuk niet meer vers in mijn hoofd heb — dus:

- **Begin bij wat het doet voor de business,** niet bij de klassenaam. "Als een klant een order
  plaatst, wordt eerst gecontroleerd of…" leest beter dan "OrderService#call roept…".
- **Jargon leg je uit of vermijd je.** Gebruik je een term uit de code (`claimline`, `preset`,
  `expected funding`), zeg dan één keer in gewone woorden wat het is.
- **Geen code-dump.** Verwijs met `pad/naar/bestand.rb:42` en plak alleen een fragment als dat
  fragment zelf het punt bewijst — een paar regels, geen hele methode.
- **Wees concreet:** noem een echt voorbeeld (een status, een route, een veld) in plaats van
  "diverse gevallen".
- **Helpt een plaatje?** Zet er een klein Mermaid-diagram in (Obsidian rendert dat) — alleen
  als het de flow duidelijker maakt dan drie zinnen tekst.

## 4. Vastleggen in Obsidian (`Codebase/`)

Eén notitie per onderwerp: `Codebase/<onderwerp-in-kebab-case>.md`. **Bestaat de notitie al?
Werk hem bij** in plaats van een tweede versie ernaast te zetten — dit is naslag die
meegroeit, geen logboek per datum. Is er wezenlijk iets veranderd sinds de vorige versie,
noem dat kort onder "Wat er is veranderd".

Link naar bestaande notities met wikilinks (`[[...]]`) waar het onderwerp raakt aan wat er al
staat, zodat de vault aan elkaar hangt.

```markdown
---
onderwerp: <onderwerp>
repo: <repo-naam>
bijgewerkt: <datum>
tags: [codebase, uitleg]
---

# <Onderwerp> — hoe het werkt

## In het kort
<Drie tot vijf zinnen die het hele verhaal vertellen. Wie dit leest en verder niets, snapt
waar het over gaat en wanneer het aan de orde is.>

## Hoe het loopt
<De flow van begin tot eind, genummerd. Per stap: wat er gebeurt, in gewone taal, met de
plek in de code erachter — `pad/bestand.rb:42`.>

## De onderdelen

| Onderdeel | Waar | Wat het doet |
| --- | --- | --- |
| <naam> | `pad/bestand.rb` | <in gewone taal> |

## Waarom het zo is
<Wat de git-historie vertelt: wanneer het is ontstaan, welk probleem het oploste, welke
keuzes bewust zijn gemaakt. Met commit-hash of PR-link waar je het vond.>

## Hoe het samenhangt met de andere repo's
<Wat er één map hoger gebeurt: wie roept dit aan, wat verwachten zij, welk contract zit
ertussen. Laat weg als het onderwerp binnen deze repo blijft.>

## Valkuilen
<Waar het in de praktijk misgaat, wat verrassend is, wat je stukmaakt als je het aanpast.>

## Wat ik niet zeker weet
<Open vragen en dingen die je niet met code kon staven. Liever hier dan verkeerd hierboven.>

## Waar je verder kijkt
<Bestanden, tests, dashboards, links, en `[[andere notities]]`.>
```

## 5. Rapporteren

Sluit af in de chat met maximaal vijf regels: het antwoord in twee zinnen, het pad van de
notitie, en de open vragen uit stap 2 als die er zijn. Zet de uitleg niet nog een keer
helemaal in de chat — daar is de notitie voor.
