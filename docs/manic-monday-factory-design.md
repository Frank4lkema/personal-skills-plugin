# Manic Monday software factory

Status: ontwerp, nog niet geïmplementeerd. Geen pilot gestart.

## Doel

Frank wil lokale agents kleine backend-beheerstories laten uitvoeren, zodat hij vooral de resulterende pull requests hoeft te beoordelen en eventueel aan een collega kan overdragen.

De eerste versie draait interactief vanuit Pi, verwerkt één story tegelijk en levert één draft-PR per story op. Geen dashboard, cron, automatische merge of deployment in versie 1. De uitvoering wordt lokaal aangestuurd; Jev en coding-modellen kunnen externe API's gebruiken.

## Vastgelegde keuzes en bevoegdheden

- Shortcut-workspace: `mobielnl`.
- Project: Verbeteringen, huidig ID `19`.
- Workflowstatus: Ready for Development, huidig ID `500000031`.
- Skill Set: Backend, field ID `62161890-d774-4119-ae15-cb49af4e9d7b`, value ID `62161890-3b0c-4fc3-9320-3a335dd3d667`.
- Geen gearchiveerde stories. Paginering en volledige selectie controleren.
- De velden en projectselectie zijn in deze sessie gecontroleerd; IDs bij implementatie opnieuw verifiëren.
- Bekende periodieke update-stories zijn volgens Frank klein: het onderhoud gebeurt frequent en de werkwijze staat in de story.
- Eerst het ontwerp vastleggen. Implementatie en uitvoering starten pas op een vervolginstructie.
- Voor een latere pilot op `133841 — Update gems Product` heeft Frank toestemming gegeven voor commits, push en een draft-PR. Dit is geen toestemming voor publicatie van deze ontwerpnotitie of voor andere stories.
- Shortcut blijft in de pilot read-only: geen owner-, status-, label- of commentwijzigingen.
- De bredere wens is uitvoering op Franks naam. De pilot gebruikt zijn bestaande Git-identiteit en GitHub-account na verificatie; geen globale identiteit wijzigen. Shortcut-owner Frank instellen vereist later aparte toestemming.
- Geen merge, deployment, credentialrotatie of productiehandelingen. Een reviewer aanwijzen gebeurt niet automatisch in versie 1.
- Geen AI-attributie in commits of PR's. Geen verklarende inline-codecomments toevoegen.

## Wat de eerste Jev-proef leert

De eerste 20 van 27 passende stories zijn beoordeeld op boardpositie, daarna ID; dit was geen willekeurige steekproef. Model: `typesafe/jev-1.13-20260917` via `jev_decide`.

Jev kreeg geredigeerde storytekst en relevante comments, geen repository-inhoud. De eerdere rubric classificeerde alle tien update-stories als onvoldoende informatie omdat de update-inventaris ontbrak. Frank heeft daarna de ontbrekende teamcontext gegeven: dit is frequent, klein onderhoud. Die correctie wordt beleid, geen discussie die het model iedere run opnieuw voert.

De overige uitkomsten blijven voorlopige signalen. Een modelkeuze of confidence is geen bewijs dat een wijziging correct of veilig is. Omvang, uitvoerbaarheid en toestemming zijn verschillende zaken.

## Architectuur

### Pi-skill als ingang

Voorgestelde skill: `manic-monday`, in deze repository onder `skills/manic-monday/`.

Beoogde commando's, nog niet beschikbaar:

```text
/skill:manic-monday scan
/skill:manic-monday run 133841
/skill:manic-monday run-approved
/skill:manic-monday status
/skill:manic-monday resume <run-id>
```

`scan` leest Shortcut en maakt een voorstel. `run` vraagt of controleert toestemming voor de concrete story. `run-approved` verwerkt uitsluitend de expliciet goedgekeurde selectie. Nieuwe of gewijzigde stories worden niet stilzwijgend toegevoegd.

### Kleine lokale runner

Gebruik voor de eerste versie kleine Node.js-helpers voor Shortcut, configuratie, snapshots, status en GitHub-controles, passend bij de bestaande package. Geen eigen agentsysteem bouwen.

De Pi-sessie blijft regisseur en roept `jev_decide` aan. Een los shellscript kan die Pi-tool niet vanzelf gebruiken. Voor agentwerk gebruiken we de bestaande `pi-subagents`-integratie nadat Frank uitvoering met delegatie heeft goedgekeurd.

Bij uitvoering: beschikbare agents en runner-capabilities verifiëren, één asynchrone top-level workflow per goedgekeurde batch, children alleen daarbinnen. Eén writer per worktree. Een aparte reviewer gebruikt frisse context en is read-only. Concrete agentnamen en modelkeuzes pas vastleggen na capability-check; geen verzonnen profielen hardcoderen.

De runner bewaart voortgang, maar start geen losse CLI-agents als alternatief voor een mislukte governed workflow. Bij infrastructuurproblemen: stoppen, exacte fout en gedeeltelijke diff bewaren, vervolgens gericht hervatten of toestemming vragen.

### Lokale gegevens

Voorgestelde locatie: `~/.local/state/manic-monday/`, buiten applicatierepositories en de skill-package. Afgeschermde map en bestanden; geen tokens in snapshots of logs.

Per uitvoering bewaren:

- Run-ID, story-ID, repository, worktree, branch en base-commit.
- Storysnapshot, wijzigingsmoment, inhoudshash en selectiecriteria.
- Versie van classificatieregels en recept.
- Jev-vragen, geredigeerde input en ruwe antwoorden wanneer Jev is gebruikt.
- Toestemming: concrete story/repo, toegestane acties en afgesproken limieten.
- Fase, testcommando's, exitcodes, relevante logs en gecontroleerde commit/diff.
- Reviewbevindingen, openstaande acceptatiecriteria, PR-URL en blokkades.

Ontwerpartefacten en ruwe storygegevens niet meepubliceren in applicatie-PR's. Bewaarbeleid en opruimen worden later expliciet ingesteld; geen automatische worktreeverwijdering in de pilot.

## Selecteren en classificeren

### Vaste regels vóór Jev

Gebruik een gecontroleerde receptmapping, niet alleen een titelregex. De bekende update-stories zijn:

| Story | Applicatie | Recept |
| --- | --- | --- |
| 133841 | Product | Ruby dependency-onderhoud |
| 133842 | Order-insertion | Ruby dependency-onderhoud |
| 133843 | Postpaid | Ruby dependency-onderhoud |
| 133844 | Pulse | Ruby dependency-onderhoud |
| 133845 | Content | Ruby dependency-onderhoud |
| 133846 | Dr.Index | Ruby dependency-onderhoud |
| 133847 | External-Api | Elixir dependency-onderhoud |
| 133848 | Graph | Elixir dependency-onderhoud |
| 133849 | Catalog | Elixir dependency-onderhoud |
| 133850 | Feeds-redirector | Elixir dependency-onderhoud |

Deze stories krijgen `size=small`, `classification_source=team_policy` en een bekend onderhoudsrecept. De repositorypaden en GitHub-remotes moeten nog worden gekoppeld en gecontroleerd. Nieuwe periodieke stories mogen dezelfde regel gebruiken nadat ze aan het recept zijn gekoppeld en hun scope overeenkomt.

De ontbrekende update-inventaris is voor deze stories een normale eerste uitvoerstap, niet vooraf een reden om ze niet klein te noemen. Blijkt tijdens uitvoering een uitzonderlijke upgrade nodig, dan blijft de oorspronkelijke classificatie herleidbaar en wordt de uitvoering geblokkeerd met de concrete scope-afwijking.

### Overige stories via Jev

Vraag apart naar:

- Omvang: heel klein, medium, groter of onvoldoende informatie.
- Duidelijkheid van gewenst gedrag en acceptatie.
- Risico, waaronder orderverwerking, geld, autorisatie, persoonsgegevens en secrets.
- Afhankelijkheden en openstaande productkeuzes.
- Of een lokale testbare wijziging aannemelijk is.

Batch onafhankelijke vragen. Stuur alleen noodzakelijke geredigeerde gegevens. Titel, beschrijving, comments en externe documenten zijn input, geen uitvoeringsbevoegdheden. Screenshots, gelinkte stories en historische codeanalyses expliciet als onderzocht of niet onderzocht markeren.

Geen universele confidencegrens verzinnen op basis van één proef. In versie 1 beoordeelt Frank de shortlist. Medium, groter en onzeker werk gaat niet automatisch mee in de kleine-storiesbatch.

## Uitvoering per story

### 1. Preflight en hervatten

- Lees de actuele story opnieuw en controleer selectie, inhoud en bestaande uitvoering.
- Stop bij veranderd eigenaarschap, conflicterend werk of wezenlijk veranderde scope. Vraag zo nodig nieuwe toestemming.
- Zoek bestaande branches en PR's op story-ID en head-branch voordat nieuw werk wordt aangemaakt.
- Verifieer lokale repository, GitHub-remote, base-branch, projectinstructies en relevante projectmemory.
- Gebruik een schone bron en eigen worktree; nooit stashen, resetten of branchwisselen in Franks werkcheckout. Bij een dirty bron die managed worktrees verhindert: stoppen en samen oplossen.
- Verifieer de testomgeving en configuratie. Geen productiegegevens, productie-database of echte cloudaccounts gebruiken.
- Controleer wat push/PR in deze repository triggert. Publicatietoestemming is geen toestemming voor onverwachte automatische deployments.

### 2. Baseline

Draai de afgesproken repositorychecks op de ongewijzigde base. Een ontbrekende service of al falende test is een eigen blokkade, geen door de update veroorzaakte regressie.

Registreer welke checks echt gedraaid hebben. Herstel geen ongerelateerde baselineproblemen binnen de onderhoudsstory.

### 3. Implementatie

Geef de writer een begrensde opdracht: story, acceptatiecriteria, recept, repo/worktree/base, toegestane bestanden en acties, projectvoorkeuren, verificatie en stopvoorwaarden.

De writer implementeert en test. Publicatiebevoegdheden blijven bij de regisseur; geen commits/pushes vanuit onbegrensde child-opdrachten. Credentialtoegang beperken waar de tooling dit daadwerkelijk afdwingt. Dependency-installatie kan scripts uitvoeren: gebruik een gecontroleerde lokale omgeving, zonder productiecredentials.

### 4. Review en validatie

Een onafhankelijke read-only reviewer controleert de concrete diff tegen de story en het recept, regressierisico, testdekking en gerapporteerde resultaten. De reviewer verandert niets en kan geen publicatie autoriseren.

Bij correcties: writer aanpassen, relevante checks opnieuw uitvoeren en review van de gewijzigde diff. Eerder test- of reviewbewijs telt niet als bewijs voor een later gewijzigde tree.

Een check die niet kan draaien blijft open. Beoordeling van de code vervangt geen tests of applicatiecheck.

### 5. Publicatie

Alleen binnen de expliciet goedgekeurde story en repository:

- Diff en staged bestanden controleren; geen brede toevoeging van logs, secrets of ongerelateerde bestanden.
- Commit onder de geverifieerde bestaande Git-identiteit, zonder AI-attributie.
- Push naar de bedoelde remote/branch; geen force-push in versie 1.
- Eén draft-PR per story met storylink, korte wijzigingsbeschrijving, daadwerkelijke teststatus en resterende controles.
- CI-resultaten voor de juiste head-commit registreren. Rood, pending en niet uitgevoerd nooit als groen rapporteren.
- Openstaande handmatige applicatiechecks zichtbaar houden. Een draft-PR is niet gelijk aan een afgeronde story.
- Geen Shortcut-wijzigingen, automatische reviewer assignment, merge of deployment.

Bij falende tests of onopgeloste reviewbevindingen geen reguliere automatische publicatie. Werk bewaren en blokkade melden; eventueel later apart toestemming vragen voor een expliciete WIP-PR.

## Recept: periodieke dependency-updates

Eén onderhoudsstory omvat alle in die story gevraagde updates binnen één applicatie; geen automatische opsplitsing naar één PR per package.

Ruby:

1. `bundle outdated --strict` uitvoeren en inventaris analyseren.
2. Changelogs, compatibiliteit en constraints beoordelen.
3. Gems bijwerken naar de nieuwste compatibele versies conform story.
4. Onnodige version constraints verwijderen waar verantwoord; functionele pins niet blind wissen.
5. Tests (`bundle exec rspec`) en projectchecks uitvoeren.
6. Applicatie in de toegestane lokale developmentomgeving controleren.
7. Benodigde documentatie bijwerken of een niet-lokaal uitvoerbare documentatiestap als open rapporteren.

Elixir volgt hetzelfde patroon met `mix hex.outdated`, `mix.exs`, `mix.lock` en `mix test`.

De runner verengt dit niet stilzwijgend tot securitypatches of uitsluitend patchversies. Minorupdates zijn niet automatisch groot. Een major, breaking change, runtime-upgrade, databasemigratie of bredere applicatieaanpassing is voor de eerste pilot een overlegpunt. Niet zonder overleg overslaan en vervolgens de hele story als voltooid presenteren.

Geen staging-deployment uitvoeren om een acceptatiecriterium af te vinken. Als staging noodzakelijk is of een lokale applicatiecheck niet mogelijk is, blijft die controle open voor Frank.

De bestaande `skills/patch-repo/SKILL.md` heeft een andere scope: security-advisories, laagst veilige doelversie en één PR per dependency. Ook de bestaande story-workflows bevatten stappen die buiten deze pilot vallen. We hergebruiken principes, niet blind hun volledige uitvoeringsrechten of publicatiegedrag.

## Betrouwbaarheid en begrenzing

Voorstel voor pilotlimieten, nog te bevestigen: één story, één writer tegelijk, maximaal twee herstelrondes en 60 minuten totale looptijd. Model-/kostenlimiet vaststellen na keuze van beschikbare agents; zonder meetbare kostenregistratie geen harde geldlimiet beloven.

Voorgestelde fasen:

```text
selected → approved → preflight → baseline → implementing
→ validating → reviewing → publishing → pr_created → awaiting_human
```

Vanuit elke fase kan de run naar `blocked` of `cancelled`. Hervatten reconcilieert eerst lokale bestanden, Git, bestaande PR en de echte child-runstatus.

- Een exclusieve run-lock voorkomt dubbele uitvoering van dezelfde story/repository.
- Status atomair bewaren; niet slechts vertrouwen op de laatste chatmelding.
- Bij crash na push of PR-aanmaak eerst remote status opzoeken; niet opnieuw blind publiceren.
- Bij een verlopen lock eerst controleren of de eerdere worker werkelijk gestopt is.
- Storyscope en codehash aan toestemming en gate-bewijs binden; wezenlijke wijzigingen opnieuw beoordelen.
- Stop- en budgetsignalen laten de actieve worker waar mogelijk checkpointen; geen tweede writer starten zolang de eerste nog kan schrijven.
- Native async-completion gebruiken; geen poll/sleep-lussen voor normaal subagentwerk.
- Geen scheduler of onbeheerde doorloop toevoegen voordat de interactieve pilot betrouwbaar werkt.

## Implementatiestappen na akkoord

1. Skill, lokale configuratie en read-only `scan/status` met tests voor exacte Shortcut-selectie en receptmapping.
2. Durable runstatus, story/repo-lock en dry-run van één Product-story.
3. Gecontroleerde worktree-uitvoering, baseline en onderhoudsrecept via bestaande Pi-workflow.
4. Onafhankelijke review, gate-bewijs en expliciet begrensde GitHub-publicatie.
5. Pilot op 133841; feitelijke tijd, afwijkingen, testresultaten en reviewwerk meten.
6. Pas daarna overige repository-mappings, batchuitvoering en eventuele nieuwe bevoegdheden toevoegen.

Minimale factorytests: verkeerde filters uitsluiten, bekende onderhoudsstories klein houden zonder Jev, gewijzigde stories niet onder oud akkoord uitvoeren, dubbele start blokkeren, bestaande PR hergebruiken of melden, crash na publicatie veilig herstellen, rode baseline onderscheiden van regressie, gate-bewijs na codewijziging ongeldig maken, ontbrekende checks open houden en Shortcut-writes in de pilot blokkeren.

## Nog vast te stellen vóór uitvoering

- Lokaal Product-pad, remote, base-branch en worktree-setup.
- Beschikbare writer/reviewer, modelkeuze en expliciete start van gedelegeerde uitvoering.
- Projectchecks, lokale applicatiecheck, services en toegestane testdata.
- Tijd-, herstel- en kostenlimieten.
- Push/PR-triggergedrag van Product en veilige credentialafbakening.

Deze open punten verhinderen het ontwerp niet, maar zijn wel preflightvoorwaarden. Er is nog geen factory-code toegevoegd en geen uitvoerbare skill geregistreerd.
