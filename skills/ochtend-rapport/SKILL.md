---
name: ochtend-rapport
description: >
  Use when you want a morning check-up of your own work: the status of the Shortcut stories
  you own and the open pull requests you authored, what changed since you stopped working
  yesterday, and a prioritized list of what to do today. Typically via an `ochtend-rapport`
  command. Triggers on "ochtend rapport", "wat moet ik vandaag doen", "status van mijn
  stories en PR's", "dagstart".
disable-model-invocation: true
argument-hint: "[sinds]"
---

# Ochtend Rapport

Mijn dagstart: wat staat er op mijn naam in Shortcut, hoe staan mijn open pull requests
ervoor, wat is er veranderd sinds ik gisteren stopte, en wat pak ik vandaag op — in welke
volgorde.

Deze skill is **read-only**. Geen PR mergen, geen comment plaatsen, geen reviewer pingen,
geen branch aanmaken. Je adviseert; ik voer uit. De enige uitzondering is het verplaatsen van
een story naar een andere state, en dat alleen aan het eind, per story, na mijn expliciete
akkoord (zie stap 6).

## Agentindeling

De hoofdagent haalt alles zelf op en schrijft het rapport. Start geen aparte agents.

## 1. Peilmoment bepalen

Ik stop meestal om **16:00**. "Nieuw" is alles na het vorige werkmoment:

- dinsdag t/m vrijdag: gisteren 16:00;
- maandag: vrijdag 16:00.

Geef ik een argument mee (`$ARGUMENTS`, bv. `gisteren 12:00` of `2026-10-09`), gebruik dat
als peilmoment.

```bash
python3 -c "
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
now = datetime.now(ZoneInfo('Europe/Amsterdam'))
d = now - timedelta(days=3 if now.weekday() == 0 else 1)
print(d.replace(hour=16, minute=0, second=0, microsecond=0).astimezone(ZoneInfo('UTC')).strftime('%Y-%m-%dT%H:%M:%SZ'))
"
```

## 2. Mijn Shortcut-stories

Via de REST API, net als de `shortcut-story-api`-skill — géén browser. Geen token in
`$SHORTCUT_TOKEN`? Zeg dat, sla dit deel over en ga door met de PR's.

```bash
SC="https://api.app.shortcut.com/api/v3"
ME=$(curl -s -H "Shortcut-Token: $SHORTCUT_TOKEN" "$SC/member" \
  | python3 -c "import json,sys;print(json.load(sys.stdin)['mention_name'])")

curl -s -G -H "Shortcut-Token: $SHORTCUT_TOKEN" "$SC/search/stories" \
  --data-urlencode "query=owner:$ME !is:done !is:archived" \
  --data-urlencode "page_size=25" --data-urlencode "detail=full"

curl -s -H "Shortcut-Token: $SHORTCUT_TOKEN" "$SC/workflows"
```

- Volg `next` in de search-response tot alle pagina's binnen zijn.
- Vertaal `workflow_state_id` naar de naam via `/workflows` (bv. *In Development*,
  *Ready for Review*, *Ready for Testing*, *Waiting*).
- Neem per story mee: id, titel, type, state, `blocked`/`blocker`, `deadline`,
  iteratie, gekoppelde `pull_requests` en `branches`, en `updated_at`.
- Zijn er na het peilmoment **comments van anderen** bijgekomen (in `comments`, met
  `author_id` ≠ mijn id)? Noteer die — dat is vaak iets waar ik op moet reageren.

## 3. Mijn open pull requests

Eén GraphQL-call over alle repo's waar ik PR's open heb:

```bash
gh api graphql -f query='
query { search(query: "is:pr is:open author:@me archived:false", type: ISSUE, first: 50) { nodes { ... on PullRequest {
  number title url isDraft createdAt updatedAt headRefName
  repository { nameWithOwner }
  reviewDecision mergeable
  reviewRequests(first: 10) { nodes { requestedReviewer { ... on User { login } ... on Team { name } } } }
  latestReviews(first: 10) { nodes { author { login } state submittedAt } }
  reviewThreads(first: 100) { nodes { isResolved isOutdated comments(last: 1) { nodes { author { login } createdAt } } } }
  commits(last: 1) { nodes { commit { committedDate statusCheckRollup { state } } } }
} } } }'
```

Koppel PR's en stories aan elkaar via `sc-<id>` in titel of branch, of via de
`pull_requests` van de story. Een PR zonder story en een story zonder PR zijn allebei
gewoon geldig — noem ze wel.

Bepaal per PR één **volgende actie**, in deze volgorde (de eerste die geldt wint):

| Situatie | Volgende actie |
| --- | --- |
| Checks `FAILURE`/`ERROR` | CI repareren |
| `mergeable: CONFLICTING` | Rebasen op de base branch |
| `CHANGES_REQUESTED` of onopgeloste, niet-outdated threads | Feedback doorlopen: `/pull-request-feedback <story-id>` |
| `isDraft` | Afmaken en ready for review zetten |
| `APPROVED`, checks groen, geen open threads | Klaar om te mergen / naar staging |
| Review gevraagd, nog geen review | Wachten — noem reviewer en hoe lang al; na > 1 werkdag: pingen |
| Checks `PENDING` | Even afwachten |

Laatste comment in een open thread van mezelf? Dan wacht die thread op de ander, niet op mij
— tel hem niet mee als werk voor mij.

## 4. Per story bepalen wat ik moet doen

De state in Shortcut loopt vaak achter op de werkelijkheid. Vergelijk daarom per story de
state met de **live** status van de gekoppelde PR's en deploys, en leid daaruit de volgende
actie af.

### Live PR-status

De `pull_requests` op de story geven een snapshot (`merged`, `closed`, `draft`). Vertrouw
daar niet blind op: haal voor elke gekoppelde PR de actuele status op.

```bash
gh pr view <pr-url> --json state,isDraft,mergedAt,mergeCommit,baseRefName \
  --jq '{state, isDraft, mergedAt, sha: .mergeCommit.oid, base: .baseRefName}'
```

Open PR's heb je in stap 3 al; hergebruik die en vraag alleen de gemergde/gesloten PR's los op.

### Live deploy-status

Is een gemergde PR al live? Kijk of de repo GitHub-deployments heeft voor `production` (en
`staging`) en of de merge-commit in de laatste deploy zit:

```bash
REPO=<owner/repo>; SHA=<merge-commit>
DEPLOY=$(gh api "repos/$REPO/deployments?environment=production&per_page=1" --jq '.[0].sha // empty')
[ -n "$DEPLOY" ] && gh api "repos/$REPO/compare/$SHA...$DEPLOY" --jq .status
```

- `identical` of `ahead` → de wijziging staat live.
- `behind` of `diverged` → nog niet live.
- Geen `production`-deployments in die repo → live-status **onbekend**. Zeg dat; ga niet
  gokken op basis van tags of tijdstippen.

Doe hetzelfde met `environment=staging` voor stories in *Ready for Testing*. Let op: staging
kan per branch deployen; een deploy van de PR-branch zelf telt dan ook.

### Story-state tegen werkelijkheid

Bepaal per story één volgende actie (de eerste die geldt wint). Heeft een story PR's in
meerdere repo's, kijk dan naar allemaal en noem welke nog openstaan.

| State in Shortcut | Werkelijkheid | Volgende actie |
| --- | --- | --- |
| elke | `blocked` | Wacht op een ander — noem de blocker |
| *Waiting* | — | Lees de laatste comment: waarop wordt gewacht, en is dat er inmiddels? |
| *Ready for Development* | geen branch/PR | Oppakken met `/feature-story`, `/bug-story` of `/feedback-story <id>` (op basis van `story_type`) |
| *In Development* | geen PR | Doorwerken — hervatten met hetzelfde command |
| *In Development* | open PR, niet draft | **State loopt achter** → naar *Ready for Review* |
| *Ready for Review* | nog open PR's | Volgende actie van die PR (stap 3) |
| *Ready for Review* | alle PR's gemerged | **State loopt achter** → naar *Ready for Testing*, en testen op staging |
| *Ready for Review* | alle PR's gesloten zonder merge | Uitzoeken: nieuwe PR nodig, of story terug/afsluiten? |
| *Ready for Testing* | nog open PR | **Klopt niet**: eerst reviewen/mergen, of story terug naar *Ready for Review* |
| *Ready for Testing* | gemerged, op staging | Testen op staging; daarna naar *Ready for Release* |
| *Ready for Testing* | gemerged, staging onbekend | Testen — controleer eerst zelf of het op staging staat |
| *Ready for Release* | live | **Kan dicht** → naar *Done* |
| *Ready for Release* | niet live | Wacht op release, of zelf releasen als dat bij mij ligt |
| *Ready for Release* | live-status onbekend | Controleren of het live staat; daarna naar *Done* |

Elke regel met een vetgedrukte state-wissel is een **voorstel** voor stap 6, geen actie.

## 5. Prioriteren

Maak één geordende lijst voor vandaag. Grofweg:

1. **Anderen wachten op mij** — gevraagde wijzigingen, nieuwe review-comments, vragen in
   Shortcut, falende CI op een PR die al in review stond.
2. **Bijna klaar** — goedgekeurde PR's om te mergen, stories om te testen op staging,
   stories die live staan en dicht kunnen, en stories waarvan de state achterloopt.
3. **Lopend werk** — stories *In Development* (hervatten met `/feature-story <id>`,
   `/bug-story <id>` of `/feedback-story <id>`, passend bij het story-type).
4. **Nieuw werk** — *Ready for Development*, met deadline of in de lopende iteratie eerst.

Blocked stories en PR's die op een ander wachten horen niet in de doe-lijst, maar wel in een
apart blokje zodat ik zie wat stilstaat.

## 6. Rapport

Schrijf het rapport in de chat, compact en scanbaar. Links altijd als markdown-link.

```text
# Ochtendrapport — <weekdag> <datum>
Sinds <peilmoment>: <n> nieuwe review(s), <n> nieuwe comment(s), <n> PR('s) van status veranderd.

## Vandaag doen
1. <actie> — [sc-1234](…) / [product#3392](…) — <waarom, in één zin>
2. …

## Pull requests (<n> open)
| PR | Story | Status | Volgende actie |
| [product#3392](…) | sc-136249 | ✅ approved · CI groen · 3 open threads | Feedback doorlopen |

## Stories (<n> op mijn naam)
| Story | State | Werkelijkheid | Volgende actie |
| [sc-130608](…) Pulse conventie… | Ready for Review | 4/4 PR's gemerged · live in pulse | → *Done* voorstellen |
| [sc-136504](…) Huidige einddatum… | Ready for Testing | [mother5#10512](…) nog open | Eerst mergen, of terug naar review |
| [sc-136969](…) Pulse input: foutstatus… | Ready for Development | geen PR | Oppakken met `/bug-story 136969` |

## State bijwerken?
- sc-130608: Ready for Review → Done (alle PR's gemerged en live)
- sc-…: …

## Wacht op een ander
- [product#3393](…) — review gevraagd aan @valerius, sinds <datum>
- [sc-…](…) — blocked door …
```

Laat lege secties weg. Is er niets nieuws sinds het peilmoment, zeg dat in één zin.

Sluit af met twee vragen:

1. **Welke state-wissels mag ik doorvoeren?** Standaard: **geen**. Voer alleen de
   wissels uit die ik expliciet noem, via de `shortcut-story-api`-skill, en meld daarna
   per story het resultaat.
2. **Waar wil ik mee beginnen?** Noem het command waarmee dat kan als er een skill voor
   is. Start niets tot ik kies.
