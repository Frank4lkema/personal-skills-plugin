---
name: patch-repo
description: >
  Use when you want to patch a repository for security updates — read its open Dependabot
  alerts, pick the lowest safe target version per package, bump it, verify, and open one PR
  per package. Typically via a `patch-repo [owner/repo …] [--auto]` command. Triggers on
  security patching, vulnerability alerts, CVE/GHSA follow-up or dependency bumps for
  security.
disable-model-invocation: true
argument-hint: "[owner/repo …] [--auto]"
---

# Patch Repo

Patch één of meer repositories voor **security-updates**: alerts ophalen → doelversies
bepalen → mij laten kiezen → per package bumpen, verifiëren en een PR openen.

Dit is bewust **geen** algemene dependency-update. Je bumpt alleen wat nodig is om een
advisory te dichten, en niets meer.

## Welke repo

De repo's krijg je mee als argument (`owner/repo`, meerdere mag). Ontbreken ze, gebruik dan
de repo waar we in staan:

```bash
gh repo view --json nameWithOwner -q .nameWithOwner
```

Is dat er ook niet, vraag er dan om — raad geen repo. Meerdere repo's? Werk ze **één voor
één** volledig af en zet ze niet door elkaar; sluit af met één gecombineerd rapport.

## Onbewaakt draaien (`--auto`)

Staat `--auto` in het argument, of draai je vanuit een scheduled/cron-run waar niemand
antwoord kan geven? Dan sla je de keuzegate in stap 3 over en volg je deze vaste regel:

- Patch elk package naar de doelversie uit stap 2, en **niets anders**.
- **Kruist de doelversie een major → niet patchen.** Zet hem in het eindrapport als "vraagt
  een major, eigen story nodig".
- **Haalt `--conservative` de doelversie niet → niet patchen.** Nooit `--force`, nooit een
  handmatige `Gemfile`-pin, nooit een kale `bundle update`. Zet in het rapport wát het blokkeert.
- Bestaat er al een open PR met dezelfde branchnaam → overslaan en melden.
- Zijn de tests rood? **Open de PR toch**, met `Tests: rood: <wat faalt>` in de body — dan
  ziet een mens het. Verzin geen fixes voor falende tests die niets met de bump te maken hebben.
- Kun je de suite in deze omgeving helemaal niet draaien (geen database, geen services, geen
  bundler)? Zet dan `Tests: niet gedraaid — verificatie via CI op de PR` in de body. **Schrijf
  nooit "groen" voor een suite die je niet gedraaid hebt.**
- Geen alerts of niets te doen? Zeg dat in één regel per repo en stop.

De rest van de workflow (branchnaam, één PR per package, PR-beschrijving van één zin,
breaking-changes-regel, geen AI-attributie) blijft **exact hetzelfde** als bij een
interactieve run.

## 1. Alerts ophalen

```bash
REPO="<owner/repo>"
gh api "repos/$REPO/dependabot/alerts?state=open" --paginate \
  --jq '.[] | "\(.security_advisory.severity)\t\(.security_vulnerability.package.ecosystem)\t\(.security_vulnerability.package.name)\t\(.security_vulnerability.vulnerable_version_range) -> \(.security_vulnerability.first_patched_version.identifier // "geen fix")\t\(.security_advisory.ghsa_id)"' \
  | sort
```

- **403 of een lege lijst?** Dan heeft je token geen toegang tot Dependabot-alerts, of ze
  staan uit voor deze repo. Meld dat en gok niet: `gh api repos/$REPO/dependabot/alerts` geeft
  de echte fout terug.
- **Geen GitHub-toegang, wel een Gemfile.lock?** Terugval op de lokale advisory-db. Zeg er
  wel bij dat die iets kan achterlopen op GitHub:
  ```bash
  gem install bundler-audit && bundle-audit check --update
  ```
- Snel zelf kijken kan ook: `https://github.com/<owner>/<repo>/security/dependabot`.

## 2. Doelversie per package bepalen

Meerdere alerts kunnen hetzelfde package raken. Bepaal per package **één** doelversie:

- Neem de **hoogste** `first_patched_version` over álle open alerts van dat package — een
  lagere versie dicht niet elke advisory.
- **Alerts zonder `first_patched_version` sla je over.** Daar bestaat nog geen fix voor; noem
  ze apart in je overzicht zodat ik weet dat ze blijven staan.
- Groepeer per ecosystem (`rubygems`, `npm`, …); de bump-commando's verschillen.

Kruist die doelversie een **major**? Dan is het geen patch maar een upgrade: **stop en vraag
het mij**. Een major-bump hoort een eigen story te zijn, niet de bijvangst van een security-run.

## 3. Laat mij kiezen (harde gate)

Zet de kandidaten in één compact overzicht — severity, package, van → naar, GHSA — en vraag
wat je mag doen:

- alles, of alleen `high` + `critical`?
- of één specifiek package?

**Begin niet met bumpen voordat ik geantwoord heb.** Is er niets te doen, zeg dat in één regel
en stop. (Bij `--auto` sla je deze gate over — zie boven.)

Check daarna eerst of het werk al loopt — meerdere repo's draaien een wekelijkse
`auto-fix-vulnerabilities`-workflow die dezelfde branchnaam gebruikt:

```bash
gh pr list --repo "$REPO" --state open --limit 200 --json headRefName -q '.[].headRefName' \
  | grep '^security/auto-fix-' || true
```

Staat er al een PR voor dat package en die doelversie? Sla het over en meld het.

## 4. Per package: bumpen

Eén package per branch, één PR per package. Houd de branchnaam gelijk aan die van de
auto-fix-workflow, dan slaat die workflow jouw package over in plaats van er een tweede PR
naast te zetten:

```bash
BASE=$(gh repo view "$REPO" --json defaultBranchRef -q .defaultBranchRef.name)   # master of main
git switch "$BASE" && git pull --ff-only
git switch -c "security/auto-fix-<package>-<doelversie>"
```

**Ga nooit uit van `main`** — meerdere repo's draaien op `master`. En werk nooit in een
checkout waar ik zelf in zit: staat er ongecommit werk of sta je op een feature-branch, dan
stop je en zeg je dat. Bij een onbewaakte run gebruik je een eigen, aparte kloon.

**Ruby (`rubygems`)** — conservatief, zodat alleen dit gem beweegt:

```bash
bundle update <package> --conservative
git diff --stat Gemfile.lock
grep -E "^    <package> \(" Gemfile.lock            # check: is de doelversie gehaald?
```

**JavaScript (`npm`)**:

```bash
npm update <package>          # of: npm audit fix   (zonder --force)
git diff --stat package-lock.json
```

Regels bij het bumpen:

- Haalt de conservatieve bump de doelversie **niet** (een andere dependency pint het gem
  vast)? **Ga niet zelf lopen forceren** met `--force`, `bundle update` zonder gem, of een
  handmatige `Gemfile`-pin. Meld wat het blokkeert en vraag hoe ik het wil.
- Beweegt er meer in de lockfile dan dit ene package? Noem dat expliciet in de PR-body — dat
  is precies wat een reviewer wil weten.
- Raak `Gemfile`/`package.json` alleen aan als het echt moet (een versie-pin die de fix
  blokkeert), en zeg het er dan bij.

## 5. Verifiëren

Draai de checks van de repo voordat je een PR opent — een lockfile-wijziging is geen
"veilige" wijziging:

- de testsuite (of minimaal de suite die deze dependency raakt)
- de linter, als die in deze repo bij CI hoort

Falen ze? Herstel of, als het niet lukt, open de PR **wel** maar zet in de body expliciet
dat de suite rood is en wat er faalt. Verzwijg dat nooit.

## 6. PR openen

Volg de conventie die de auto-fix-workflow ook gebruikt:

```bash
git add -A
git commit -m "Security: bump <package> to <doelversie> (<severity>)"
git push -u origin HEAD
gh pr create --repo "$REPO" \
  --title "Security: bump <package> to <doelversie> (<severity>)" \
  --label security --label dependencies \
  --body "<zie hieronder>"
```

**De PR-beschrijving is maximaal één zin.** Daarna alleen de twee regels die een reviewer
echt nodig heeft: breaking changes en teststatus. Geen samenvatting van de advisory, geen
opsomming van wat je gedaan hebt, geen test-plan, geen boilerplate.

```markdown
`<package>` <huidige versie> → <doelversie> voor [<GHSA>](<advisory-url>) (<severity>).

**Breaking changes:** <nee — patch-release | ja: <wat> | onbekend: <waarom>>
**Tests:** <groen | rood: <wat faalt>>
```

Bepaal die breaking-changes-regel op basis van de release notes of het changelog tussen de
huidige en de doelversie:

- Alleen een patch-versie omhoog en niets in het changelog? → `nee — patch-release`.
- Kruist het een **minor** of staan er gedragswijzigingen, deprecations of verwijderde API's
  in? → `ja` met in een paar woorden wát er verandert.
- Kun je het changelog niet vinden of niet beoordelen? → `onbekend` met de reden. **Schrijf
  nooit "nee" omdat je het niet gecontroleerd hebt** — dat is precies de regel waarop een
  reviewer afgaat.
- Zijn er naast dit package nog andere regels in de lockfile bewogen, noem dat hier ook in
  een halve zin.

**Harde regel voor de commit:** zet NOOIT een `Co-authored-by`-trailer of andere
AI-attributie in de commit-message — niet van Claude Code, niet van Codex, Cursor of welke
tool dan ook. Geen "Generated with"-regels, geen 🤖-footer, ook niet in de PR-body. De commit
staat op mijn naam.

Meerdere packages? Herhaal stap 4 t/m 6 per package, telkens vanaf een verse `main`.

## 7. Afronden

Rapporteer in één blok: welke packages gepatcht zijn (van → naar) met PR-link, welke alerts
zijn blijven staan en waarom (geen fix beschikbaar, major nodig, al een open PR), en per PR
de teststatus plus of er breaking changes verwacht worden.
