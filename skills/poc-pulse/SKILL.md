---
name: poc-pulse
description: >
  Use when you want a quick, throwaway proof of concept of a screen in Pulse that can be shown
  via screen sharing: one sentence of intent in, a working Pulse page on a poc branch out —
  built only from Pulse components, checked against real local data, optionally deployed to a
  staging channel. No tests, no PR. Typically via a `poc-pulse <zin>` command. Triggers on
  "maak snel een poc", "kan je even een poc in pulse maken", "zodat we snel kunnen spelen".
disable-model-invocation: true
argument-hint: "[wat de poc moet laten zien]"
---

# POC in Pulse

We zetten oude schermen om naar Pulse. Soms wil ik niet de hele story-workflow, maar binnen een
paar minuten een **werkende pagina** die ik via window sharing kan laten zien en waar we samen
op kunnen schieten. Dat is deze skill: één zin erin, een klikbare Pulse-pagina eruit.

Het resultaat is wegwerpwerk op een **poc-branch**: geen tests, geen PR, niet mergen. Snelheid
gaat boven perfectie, maar wat je laat zien moet wél kloppen met de echte data.

**Geen inline code-comments** in wat je bouwt: laat namen en teksten op de pagina het werk doen.

## Agentindeling

De hoofdagent doet alles zelf: verkennen, bouwen, nalopen. Start geen subagents; dat kost meer
tijd dan het oplevert bij een POC.

## 1. De zin lezen (geen vragenronde)

Alles achter het command is de opdracht (`$ARGUMENTS`). Is die leeg, vraag dan in één zin wat de
POC moet laten zien en stop.

Stel daarna **geen verduidelijkende vragen** als je zelf een redelijke keuze kunt maken. Kies
zelf een voorbeeldrecord (bv. een concreet product), een naam voor de route en een indeling, en
noem die keuzes aan het eind. Vraag alleen als je echt vastzit: twee totaal verschillende
interpretaties van de zin, of geen data om iets mee te tonen.

## 2. Branch

Ga uit van de default branch (`master` of `main`, check met
`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`).

- **Ongecommit werk** (gewijzigde of gestagede bestanden; losse untracked scripts tellen niet)?
  Zeg dat en vraag of ik een worktree wil of dat je het werk mag meenemen. Gooi nooit iets weg.
- Anders: `git switch <base> && git pull --ff-only && git switch -c poc/<kort-onderwerp>`.

Draait het verzoek door op een eerdere POC in deze sessie (bv. "zet er nog een icoon bij")?
Blijf dan op die branch en sla deze stap over.

## 3. Verkennen — kort

Maximaal een handvol zoekacties, daarna bouwen:

1. **Het oude scherm** (als dat er is): welk model, welke data, welke velden. Dat is je bron.
2. **Een vergelijkbare Pulse-pagina** in de repo om te spiegelen: layout, breadcrumbs,
   `ui.page` vs `ui.section.page`, waar controllers en views in de Pulse-namespace staan.
3. **De echte data**: draai een read-only script tegen de lokale database om te zien hoe het
   voorbeeldrecord eruitziet. Zet het script in je scratchpad, niet in de repo:

   ```bash
   bin/rails runner <scratchpad>/probe.rb
   ```

   Dit bepaalt vaak het ontwerp. Zie je bijvoorbeeld dat media alleen aan kleur hangen en niet
   aan opslag, dan groepeer je op "dezelfde media" in plaats van op een hardcoded lijst
   eigenschappen.

## 4. Bouwen — alleen Pulse-blokken

Eén route, één controller, één view (plus partials). Raak bestaande schermen hooguit aan met
één knop of link naar de POC.

- **UI alleen via Pulse** (`ui.*`). Geen eigen componenten, geen Bootstrap. Tailwind-klassen
  alleen voor layout (grid, flex, gap, afmetingen) en met de design-tokens van Pulse
  (`bg-bg-*`, `border-bd-*`, `text-fg-*`).
- **Controleer signatures** voordat je een component gebruikt; de API wijkt soms af van wat je
  verwacht (`ui.empty_state` neemt bv. alleen `text:`):

  ```bash
  P=$(bundle show pulse)
  ls $P/app/components/pulse
  cat $P/../../docs/components/<component>.md
  ```

  Vaak bruikbaar: `ui.page`, `ui.card`, `ui.tabs` (`with_tab(id, text:, icon_left:)` +
  `tab.with_panel`), `ui.badge`, `ui.button` (ook icon-only met `icon_left:`),
  `ui.description_list`, `ui.divider`, `ui.link`, `ui.empty_state`, `ui.dropdown`,
  `ui.action_bar`.
- **Interactie** via een kleine Stimulus-controller in de Stimulus-app die de Pulse-pagina's
  laden (in deze repo's: `app/javascript/importmap/`, niet `app/javascript/controllers/`).
- **Logica** die meer is dan een query (groeperen, vergelijken) in een kleine service of PORO,
  zodat de view dom blijft.
- **Read-only.** Geen migraties, geen schrijfacties op data, geen nieuwe gems.
- **Geen tests** schrijven die in de repo blijven.

## 5. Nalopen

Een POC die op het scherm crasht is erger dan geen POC. Controleer daarom altijd:

1. **Rendert de pagina?** De route zit achter een login, dus curl helpt niet. Kopieer een
   wegwerp-request-spec tijdelijk naar `spec/requests/`, draai hem en **verwijder hem direct**:

   ```ruby
   require "rails_helper"

   RSpec.describe "POC smoke" do
     let!(:record) { create(:<factory>) }

     it "renders" do
       get "<pad>"
       expect(response).to have_http_status(:ok)
     end
   end
   ```

2. **Klopt de inhoud met de echte data?** Draai de service of query met `bin/rails runner`
   op het voorbeeldrecord en vat de uitkomst in een paar regels samen.
3. **Draait de app?** Check `curl -s -o /dev/null -w "%{http_code}" localhost:<poort>/`. Start
   hem zo nodig op de achtergrond **met open stdin**, anders stopt de esbuild-watcher meteen en
   neemt foreman alles mee:

   ```bash
   tail -f /dev/null | bin/dev     # run_in_background
   ```

   Heb je browserautomatisering? Klik de pagina dan ook echt door. Zo niet, zeg dat het
   klikgedrag niet in een browser is gecontroleerd.

## 6. Laten zien

Geef de lokale URL en in een paar bullets wat ik zie, welke keuzes je zelf hebt gemaakt en wat
niet is gecontroleerd. Kort — ik ga het delen, niet lezen.

Daarna itereren we. Elke vervolgvraag ("zet er een icoon bij als …") pas je direct aan op
dezelfde branch, met dezelfde smoke-check uit stap 5.

## 7. Naar staging? (alleen op verzoek)

Deploy alleen als ik erom vraag. Staging-kanalen zijn gedeeld.

1. **Committen** met een korte message volgens de conventie van de repo. Een pre-commit hook
   kan RuboCop laten autocorrigeren zonder de bestanden opnieuw te stagen: kijk na elke commit
   naar `git status` en commit achtergebleven correcties apart (`style: apply rubocop corrections`).
2. **Pushen**: `git push -u origin HEAD`. Zonder push deploy je een oude stand.
3. **Deployen** met mijn vaste commando:

   ```bash
   zsh -lic 'staging deploy <kanaal> <naam>'
   ```

   `<kanaal>` is wat ik noem (bv. `sprint-14`). `<naam>` is één kort woord voor deze POC
   (`mediacarousel`). Een naam is verplicht: zonder naam overschrijf je de basisomgeving van het
   kanaal en dus mogelijk het werk van een collega. Ontbreekt het kanaal, vraag dan alleen dat.
   Stel de naam zelf voor.
4. **Wachten tot het echt live is.** Na een geslaagde deploy draaien de oude pods soms nog even.
   Poll de route tot hij geen 404 meer geeft (een 302 naar de login betekent: nieuwe code draait):

   ```bash
   curl -s -o /dev/null -w "%{http_code}" https://<naam>.<app>.<kanaal>.stg.mobiel.io/<pad>
   ```

   Vergelijk bij twijfel met een bestaande route op dezelfde host.

Een vervolgwijziging opnieuw naar staging? Commit, push en draai hetzelfde commando met dezelfde
naam.

## 8. Afronden — het spiekbriefje

```text
POC: <lokale url>
Staging: <staging url>        (alleen als gedeployed)
Branch: poc/<onderwerp>       (wegwerp, geen PR)
Wat je ziet: <1–3 regels>
Zelf gekozen: <voorbeeldrecord, indeling, aannames>
Niet gecontroleerd: <bv. klikgedrag in de browser, data op staging>
```
