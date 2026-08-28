---
name: create-demo
description: >
  Use when you want to prepare a sprint review demo: collect the stories one person finished
  in a given sprint that actually landed in this repo, cluster them into a few recognizable
  topics, and build a single demo page (one route + controller on a throwaway demo branch)
  that shows every screen in iframes so nothing has to be clicked together live. Typically
  via a `create-demo <sprint> <gebruiker>` command. Triggers on "demo voor de sprint review",
  "laat zien wat we deze sprint gedaan hebben".
disable-model-invocation: true
argument-hint: "[sprint] [gebruiker]"
---

# Create Demo

Eén demopagina voor de sprint review: alles wat één persoon deze sprint in **deze repo**
heeft opgeleverd, gebundeld op één scherm met iframes, zodat ik tijdens de review niet zit
te klikken en in te loggen op vijf verschillende pagina's.

Het resultaat is wegwerpwerk op een aparte **demo-branch** — geen PR, niet mergen naar de
default branch.

**Geen inline code-comments** in wat je bouwt (huisstijl, zie de story-basis): laat namen en
de teksten op de pagina het werk doen.

## 1. Sprint en gebruiker vragen (verplicht)

Alles achter het command is invoer (`$ARGUMENTS`) — daar kan een sprintnummer en/of een naam
in staan. Wat ontbreekt, vraag je in **één keer**, zodat ik het in één antwoord kan geven:

- **Welke sprint?** (bv. `sprint11`, of "de lopende")
- **Wiens werk?** (naam of mention-name; standaard: ik zelf)

Resolven doe je via de **`shortcut-story-api`-skill** — REST API, géén browser:

```bash
curl -s -H "Shortcut-Token: $SHORTCUT_TOKEN" "https://api.app.shortcut.com/api/v3/iterations" \
  | python3 -c "import json,sys;[print(i['id'], i['status'], i['name']) for i in json.load(sys.stdin)]"

curl -s -H "Shortcut-Token: $SHORTCUT_TOKEN" "https://api.app.shortcut.com/api/v3/members?disabled=false" \
  | python3 -c "import json,sys;[print(m['id'], m['profile']['mention_name'], m['profile']['name']) for m in json.load(sys.stdin)]"
```

Geen token in `$SHORTCUT_TOKEN`? Zeg dat en stop — ga niet via de browser.

## 2. Ophalen wat er af is

Haal de stories uit die iteratie, filter op eigenaar en op **afgerond**:

```bash
ITER=<iteration-id>; MEMBER=<member-uuid>
curl -s -H "Shortcut-Token: $SHORTCUT_TOKEN" \
  "https://api.app.shortcut.com/api/v3/iterations/$ITER/stories" \
  | python3 -c "
import json,sys
for s in json.load(sys.stdin):
    if '$MEMBER' in (s.get('owner_ids') or []) and s.get('completed'):
        print(s['id'], s['story_type'], s['name'])
"
```

## 3. Filteren op déze repo

Een afgeronde story hoeft hier geen code te hebben opgeleverd. Controleer dat per story in de
repo waar je nu staat:

```bash
git log --oneline --all --grep="sc-<ID>"
gh pr list --search "sc-<ID>" --state merged --json number,title,url,files
gh pr diff <nr> --name-only
```

- **Code gevonden?** Story gaat mee. Noteer welke bestanden en vooral welke **routes/schermen**
  geraakt zijn — dat is wat je straks in een iframe zet (`bin/rails routes | grep <controller>`
  helpt om het echte pad te vinden).
- **Niets gevonden?** Zet hem apart. Noem die stories één regel in je samenvatting ("zit in
  een andere repo / geen UI") en bouw er geen demo voor.

Kun je van een story geen zichtbaar scherm vinden (migratie, job, refactor)? Ook apart zetten:
in een demo laat je iets zien, geen diff.

## 4. Clusteren tot onderwerpen

Vertel het verhaal niet per story — vijf losse stories zijn geen demo. Groepeer ze tot **twee
tot vijf onderwerpen** die het team in één zin herkent, in de taal van de business, niet in
klassenamen. Meestal valt het samen per scherm, per flow of per rol.

Presenteer die clusters compact en **vraag daarna pas of ik er een demopagina van wil** — en
welke onderwerpen erin moeten:

```text
Sprint <NN> — <gebruiker>: <n> stories afgerond, <m> daarvan zichtbaar in deze repo.

1. <Onderwerp in gewone taal>
   Stories: sc-1234, sc-1240 · Scherm: /pulse/…
   In één zin: <wat het team hier ziet>
2. …

Buiten de demo: sc-1250 (andere repo), sc-1251 (geen UI).

Zal ik hier een demopagina van maken? Welke onderwerpen wil je erin?
```

Wacht op mijn akkoord. Zonder go geen branch en geen code.

## 5. Demo-branch aanmaken

Bouw dit **nooit** op de default branch of op een story-branch. Ga uit van een schone
checkout — staat er ongecommit werk, zeg dat dan en stop.

```bash
BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)   # master of main
git switch "$BASE" && git pull --ff-only
git switch -c "demo/sprint<NN>" 2>/dev/null || git switch "demo/sprint<NN>"
```

**Ga nooit uit van `main`** — meerdere repo's draaien op `master`. Deze branch is wegwerpwerk:
geen PR, niet mergen, en na de review mag hij weg.

## 6. De pagina bouwen

Eén route, één controller, één view. Volg de conventies van de repo (naamgeving, layout,
authenticatie) en raak **geen bestaande app-code** aan; alles wat je toevoegt staat los.

```ruby
get "/demo/sprint<NN>", to: "demo#sprint<NN>", as: :demo_sprint<NN>
```

De controller houdt de onderwerpen op één plek, zodat ik ze zelf kan bijschaven:

```ruby
class DemoController < ApplicationController
  ONDERWERPEN = [
    { slug: "expected-fundings", titel: "…", uitleg: "…", pad: "/pulse/…", stories: %w[sc-1234] }
  ].freeze

  def sprint<NN>
    @onderwerpen = ONDERWERPEN
  end
end
```

De view is één pagina met per onderwerp een blok: titel, één zin uitleg, de story-ids, en het
echte scherm in een iframe. Zo hoef ik tijdens de review nergens heen te navigeren.

```erb
<% @onderwerpen.each do |o| %>
  <section id="<%= o[:slug] %>">
    <h2><%= o[:titel] %></h2>
    <p><%= o[:uitleg] %></p>
    <p><%= o[:stories].join(", ") %> — <%= link_to "los openen", o[:pad], target: "_blank" %></p>
    <iframe src="<%= o[:pad] %>" loading="lazy" width="100%" height="700"></iframe>
  </section>
<% end %>
```

Aandachtspunten die een demo anders ter plekke laten stranden:

- **Navigatie bovenaan:** ankerlinks naar de secties, zodat ik in één klik bij het volgende
  onderwerp ben. Tabs mogen ook, als de iframes dan pas laden.
- **Iframes zijn same-origin**, dus de sessie waarmee ik ben ingelogd geldt ook daarbinnen.
  Blijft een iframe leeg? Kijk naar `X-Frame-Options`/CSP `frame-ancestors`. Ruim dat op
  **alleen voor deze demo-route**, en zet nooit authenticatie uit.
- **Nieuwe route = rechten.** Volg de conventie van de repo; kan ik er als presentator niet
  bij, dan is de demo waardeloos. Meld welke rol de route nodig heeft.
- **`loading="lazy"`** en niet meer dan een handvol iframes — anders duurt het laden langer
  dan mijn demo.
- **Geen nieuwe dependencies**, geen JS-framework. Wat inline CSS is prima.

## 7. Zelf nalopen

Start de app lokaal, open `/demo/sprint<NN>` en controleer **per onderwerp** of het iframe
echt het scherm toont — niet leeg, geen loginscherm, geen 403. Log daarvoor in met het
e-mailadres dat ik je geef (op dev is alleen het adres genoeg; vraag welk).

Werkt er iets niet, herstel het en kijk opnieuw. Rapporteer pass/fail per onderwerp met bewijs
(screenshot of wat je zag) en sluit gestarte processen af. Heb je browserautomatisering? Klik
de pagina dan echt door.

Ontbreekt de data om iets te tonen (leeg scherm, geen records in die status)? Zeg dat erbij —
dan weet ik dat ik voor de review nog data moet regelen of dat onderwerp moet overslaan.

## 8. Naar staging voor de review? (vragen)

Doe ik de review niet op localhost, vraag dan of ik het gedeployed wil hebben en op welk
sprint-kanaal, precies zoals stap 11 van de story-basis. Push eerst de demo-branch, anders
deploy je een oude stand.

`staging` is een shellfunctie uit `~/.zshrc`. Voer de deploy altijd uit met
`zsh -lic 'staging deploy <kanaal> <naam>'`. Gebruik geen `command -v staging` in een
niet-interactieve shell; die vindt de functie ten onrechte niet.

## 9. Afronden — geef me het spiekbriefje

Sluit af met wat ik tijdens de review voor me heb: de URL, en per onderwerp één regel in de
volgorde waarin ik het laat zien.

```text
Demo: <url> (branch demo/sprint<NN>)
1. <Onderwerp> — "<wat je zegt in één zin>" (sc-1234, sc-1240)
2. …
Niet in de demo: <stories + reden>
Let op: <wat niet werkt / welke data ontbreekt / met welke gebruiker inloggen>
```
