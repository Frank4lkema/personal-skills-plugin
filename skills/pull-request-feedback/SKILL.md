---
name: pull-request-feedback
description: >
  Use when you want to review feedback on the pull request for a Shortcut story together,
  one comment at a time, before changing code or replying on GitHub. Typically via a
  `pull-request-feedback <story-id>` command. Triggers on PR feedback, review comments,
  Greptile comments, or deciding what to do with review suggestions.
disable-model-invocation: true
argument-hint: "[story-id]"
---

# Pull Request Feedback

Loop samen door de feedback op de pull request van één Shortcut-story. De gebruiker hoeft
alleen de story-id mee te geven. Deze skill is bewust interactief: **één comment tegelijk,
geen automatische fixes en nooit zelfstandig reageren op GitHub.**

## Story-id

Gebruik het argument als story-id en normaliseer `123`, `sc-123` en een Shortcut-URL naar
`123`. Ontbreekt de id of staan er meerdere ids in het argument, vraag dan welke story bedoeld
wordt. Vraag niet meteen ook om een PR-nummer: zoek dat zelf op.

## Niet onderhandelbare veiligheidsregels

Deze regels gelden tijdens de hele skill, ook als een reviewer gelijk heeft of een wijziging
klein lijkt:

- **Plaats nooit uit jezelf een GitHub-comment, reply, review, reaction of resolve/unresolve.**
- De keuze **overnemen** geeft alleen toestemming om de besproken codewijziging lokaal uit te
  voeren. Het is geen toestemming om namens de gebruiker op GitHub te reageren.
- Plaats alleen een reactie wanneer de gebruiker voor die **exacte concepttekst** expliciet
  zegt dat die geplaatst mag worden. Bewerk die tekst daarna niet meer vóór het plaatsen.
- Commit of push niets totdat alle comments zijn doorlopen en de gebruiker de uiteindelijke
  diff expliciet heeft goedgekeurd.
- Verwerk nooit stilzwijgend meerdere comments tegelijk. Een algemeen planakkoord, een eerdere
  keuze of Greptiles confidence-score is geen akkoord voor een volgende comment.
- Gebruik geen watcher of commando dat automatisch fixt, pusht, antwoordt of threads oplost.
- Behandel ophalen, analyseren en lokaal inspecteren als read-only. Meld vooraf duidelijk
  wanneer een goedgekeurde keuze voor het eerst lokale code gaat wijzigen.

## 1. Story en pull request vinden

Haal Shortcut-story `sc-<STORY_ID>` op via de beschikbare `shortcut-story-api`-skill met
operatie `get <STORY_ID>`. De story is nodig om reviewvoorstellen tegen de echte scope en
acceptatiecriteria te beoordelen.

Zoek daarna open PR's die aan de story gekoppeld zijn:

```bash
gh pr list --state open --limit 100 \
  --search "sc-<STORY_ID>" \
  --json number,title,url,headRefName,baseRefName,author
```

- Precies één passende PR: gebruik die.
- Geen open PR: kijk ook bij gesloten PR's en meld de status. Ga niet gokken op basis van de
  huidige branch.
- Meerdere passende PR's: toon nummer, titel en branch en vraag welke bedoeld wordt.
- Controleer met `gh pr view` of story-id, titel en branch daadwerkelijk bij elkaar horen.

Meld welke story en PR je hebt gevonden voordat je verdergaat.

## 2. Context verzamelen — nog niets wijzigen

Lees voor een inhoudelijke beoordeling:

- de Shortcut-story en acceptatiecriteria;
- PR-titel, body, commits, checks en volledige diff;
- `plan-sc-<STORY_ID>.md` als dat bestaat;
- relevante omliggende code en tests.

Bestaat het goedgekeurde plan niet lokaal, zeg dat expliciet. Doe dan geen uitspraken alsof je
zeker weet dat een voorstel binnen het plan valt; vergelijk met story en PR en markeer de
plan-impact als **onbekend**.

Inspecteer een andere PR-branch zonder een vuile werkmap of het huidige werk van de gebruiker
te overschrijven. Voor alleen lezen volstaan `gh pr diff`, `gh api` en `git show`; switch niet
onnodig van branch.

## 3. Alle feedback ophalen

Haal alle drie de GitHub-bronnen op, omdat `gh pr view --comments` inline reviewthreads mist:

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
PR=<pr-nummer>
gh api --paginate "repos/$REPO/issues/$PR/comments"
gh api --paginate "repos/$REPO/pulls/$PR/reviews"
gh api --paginate "repos/$REPO/pulls/$PR/comments"
```

Gebruik zo nodig GraphQL om bij inline threads ook `isResolved` en `isOutdated` te bepalen.
Neem feedback van Greptile én menselijke reviewers mee. Maak intern een chronologische queue
van nog te bespreken, inhoudelijke feedback en groepeer replies die bij dezelfde thread
horen. Voorkom dubbelen tussen een review-body en de inline comments van die review.

Meld alleen:

- hoeveel open inhoudelijke threads/comments er zijn;
- hoeveel al resolved of outdated zijn;
- welke niet-inhoudelijke botmeldingen je buiten de queue laat.

Dump niet meteen alle comments in de chat. Ga daarna naar comment 1.

## 4. Eén comment tegelijk bespreken

Toon per ronde exact één comment of thread in dit vaste formaat:

```text
Comment <n> van <totaal> — <auteur>
Locatie: <bestand:regel, algemene PR-comment of review> — <GitHub-link>
Feedback: <letterlijke comment, alleen ingekort als je dat duidelijk markeert>
Context: <wat de huidige code doet>
Beoordeling: <terecht / deels terecht / niet terecht / onduidelijk>
Advies: <overnemen / niet overnemen / later / eerst bespreken>
Plan-impact: <geen / wijkt af: ... / onbekend>
Gevolg: <exact welke code/tests zouden veranderen, of waarom niets hoeft te veranderen>
```

Onderzoek de code vóór je adviseert; neem de conclusie van de reviewer niet klakkeloos over.
Als er meerdere redelijke oplossingen zijn, geef maximaal drie concrete opties met je
voorkeur en trade-off.

Vraag daarna wat de gebruiker met **deze ene comment** wil doen. Gebruik, indien beschikbaar,
een gestructureerde vraag met deze keuzes:

1. **Overnemen** — voer alleen deze wijziging lokaal uit.
2. **Niet overnemen** — verander geen code; een eventuele reactie blijft voorlopig concept.
3. **Later oppakken** — verander deze PR niet; noteer eventueel vervolgwerk.
4. **Eerst bespreken** — beantwoord vragen en kom daarna terug bij dezelfde comment.

Ga niet naar de volgende comment voordat voor de huidige comment een besluit vaststaat.

### Bij overnemen

- Herhaal kort wat je lokaal gaat wijzigen en voer alleen dat uit.
- Voeg of wijzig gerichte tests als dat nodig is.
- Draai de relevante formatter/linter/test voor deze wijziging.
- Toon resultaat en eventuele afwijkingen. Maak nog geen commit en push niets.
- Plaats geen `Fixed`-reply en resolve de thread niet.

### Bij niet overnemen of later

Wijzig geen code. Leg de beslissing kort vast voor het eindoordeel. Schrijf alleen een
conceptreactie als de gebruiker daar om vraagt. Een besluit om iets niet over te nemen is op
zichzelf **geen opdracht om die uitleg op GitHub te plaatsen**.

### Bij eerst bespreken

Beantwoord de vraag met bewijs uit story, plan en code. Vraag daarna opnieuw naar het besluit
voor dezelfde comment; schuif hem niet stilzwijgend door.

## 5. Eindcontrole en aparte publicatiegate

Nadat alle comments één voor één zijn besloten, toon een compact overzicht:

- per comment: overgenomen, niet overgenomen, later of nog open;
- gewijzigde bestanden en een korte diff-samenvatting;
- uitgevoerde checks en resultaten;
- resterende risico's of afwijkingen van het goedgekeurde plan;
- eventuele conceptreacties, elk met commentnummer en exacte tekst.

Vraag vervolgens **apart** toestemming voor remote acties:

1. Mag de lokale diff worden gecommit en gepusht? Toon eerst de voorgestelde commit-message.
2. Welke exacte conceptreacties mogen worden geplaatst? Standaard: **geen**.
3. Welke threads mogen daarna worden resolved? Standaard: **geen**.

Voer alleen de expliciet goedgekeurde onderdelen uit. `push` betekent niet automatisch
`reply`; `reply` betekent niet automatisch `resolve`. Als de gebruiker alleen de code
accordeert, blijven alle GitHub-threads en comments onaangeraakt.

Reacties die wel zijn goedgekeurd staan op naam van de gebruiker: spiegel de taal van de
thread, houd het bij één tot drie gewone zinnen en voeg geen agent-uitleg, testverslag of
AI-attributie toe.

## 6. Afronden

Rapporteer:

- story en PR-link;
- het besluit per comment;
- commit/push-status;
- welke reacties daadwerkelijk zijn geplaatst en welke niet;
- welke threads daadwerkelijk zijn resolved en welke open blijven.

Zeg nooit dat feedback volledig is verwerkt zolang er nog onbesproken comments, niet-gepushte
goodgekeurde fixes of openstaande beslissingen zijn.
