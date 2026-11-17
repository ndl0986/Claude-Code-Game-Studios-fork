# Vietnamese History Mobile Game — Project Plan

As of 2026-11-14 · Luan Nguyen

> Shared, commentable version: https://claude.ai/artifact/7s8ww63BC5EFXhKJ4xXqLx
> This file is the repo copy. Update both when the plan changes.

## Overview

We will build a mobile game for Android and iOS about Vietnamese historical figures. We'll use Claude Code Game Studios as our AI studio for design, coding, testing and release. The figures, events and source material come from the team later; this plan fills in once they arrive.

The repo's quick path (`/prototype`) only makes browser games. Native Android and iOS apps come from the game engine, so the plan is:

1. **Find the fun in the browser.** Make quick prototypes with `/prototype` and play them.
2. **Build the real game in an engine.** Make it in Godot 4 (or Unity) using the repo's studio mode: design docs, architecture decisions, epics, stories and sprints.
3. **Ship from the engine.** Build for Android (Google Play) and iOS (App Store), then run `/release-checklist mobile`.

The README says the engine route is less proven than the browser route, so we test Android and iOS builds in week one.

## Key decisions

| Decision | Recommendation | Alternative | Why |
| --- | --- | --- | --- |
| Engine | Godot 4 | Unity | Godot is free, builds Android and iOS from one project, has dedicated agents in the repo, and suits a 2D story or strategy game. Unity is stronger if we plan ads, in-app purchases or many third-party services. |
| Rigor (`modes.rigor`) | `standard` | `full` | A balanced amount of process for a team project. Use `system_overrides` to hold history and narrative content to `full`. |
| Languages | Vietnamese first, English second | Vietnamese only | Fonts must cover all Vietnamese diacritics (e.g. Hưng Đạo Đại Vương). English text runs longer in the UI. |
| Platforms | Android + iOS, phones first | Add tablets later | Touch-first design; test on a low-end Android phone from the vertical slice onward. |

## Setup

Each developer needs these tools and the team needs two store accounts before phase 0 ends.

| Item | Needed for | Status (Luan's Mac, 2026-11-14) |
| --- | --- | --- |
| Git, Python 3, jq, Claude Code | Repo hooks and skills | Installed |
| Chrome or Edge | Browser prototype checks | Installed |
| Node.js 22+ | Growing a browser prototype into a web project | v20 installed; fine unless Claude Code is installed via npm |
| Xcode | iOS builds | Installed; `xcodebuild` errors, so open Xcode once and accept the license |
| Android Studio + SDK | Android builds | Not installed |
| Godot 4 (or Unity) with export templates | The game itself | Not installed |
| Apple Developer Program, $99/year | TestFlight and the App Store | Not started |
| Google Play Console, $25 one-time | Play testing tracks and the store | Not started |

**Start the repo correctly.** Open Claude Code from the repo root, or the hooks, safety rules and ask-first mode will not load:

```bash
cd ~/self-projects/Claude-Code-Game-Studios-fork && claude
```

Then run `/start`, `/setup-engine godot 4.x`, and `/project-settings modes.rigor=standard`. Use `/next-step` whenever you are unsure what comes next.

**Git.** `origin` is our fork (`ndl0986/Claude-Code-Game-Studios-fork`) and `upstream` is the original template. Pull template updates with `git fetch upstream && git merge upstream/main`, then follow `UPGRADING.md`.

## Phases

The phases follow the repo's built-in pipeline. Durations are rough and get fixed once the team material arrives. History and narrative work runs alongside systems design. Full production starts only after the vertical slice plays well on real phones.

```
0 Setup (1 wk)
  └─> 1 Concept (2–3 wk)
        ├─> 2 Systems design (3–4 wk) ─┐
        └─> 3 History & narrative ─────┤  (run in parallel)
                                       └─> 4 Technical setup (1–2 wk)
                                             └─> 5 Pre-production (3–4 wk)  ◆ GATE: vertical slice on real phones
                                                   └─> 6 Production (sprints)
                                                         └─> 7 Polish
                                                               └─> 8 Release
```

| Phase | Goal | Main commands | Output |
| --- | --- | --- | --- |
| 0 Setup | Tools, accounts, empty project running on Android and iOS phones | `/start`, `/setup-engine godot`, `/project-settings` | `project.yaml`, engine reference docs, empty Android and iOS builds |
| 1 Concept | Find the fun before investing | `/brainstorm`, `/prototype` | Playable browser concepts, game concept doc |
| 2 Systems design | Design each system | `/map-systems`, `/design-system`, `/review-all-gdds`, `/art-bible` | Systems map, design docs, art bible |
| 3 History & narrative | Turn source material into accurate content | `/team-narrative` | Character bios, timeline, accuracy labels, source list in `design/narrative/` |
| 4 Technical setup | Architecture for mobile | `/create-architecture`, `/architecture-decision`, `/test-setup` | Architecture doc and decision records |
| 5 Pre-production | One polished playable section | `/vertical-slice`, `/ux-design`, `/create-epics`, `/create-stories` | Vertical slice on real phones, epics and stories |
| 6 Production | Build the content | `/sprint-plan`, `/dev-story`, `/story-done`, `/team-ui`, `/team-audio`, `/team-level` | Content built sprint by sprint |
| 7 Polish | Performance, accessibility, translations | `/team-polish`, `/perf-profile`, `/localize`, `/team-qa`, `/playtest-report` | Performance, accessibility and translations done |
| 8 Release | Store submission | `/release-checklist mobile`, `/launch-checklist`, `/patch-notes` | Store submissions and launch |

## Risks

| Risk | Impact | How we handle it |
| --- | --- | --- |
| Historical inaccuracy or a sensitive portrayal | Public backlash, store or publisher rejection | A named history reviewer signs off every character and chapter. Each claim is labelled fact, interpretation or invented. Sources are recorded in `design/narrative/`. |
| Vietnam publishing licence for games (G1) | Cannot launch commercially in Vietnam | Check the licence rules in phase 0 and plan content and timing around them. |
| iOS build problems found late | Launch slips | Build an empty project for both iOS and Android in phase 0, and keep both building every sprint. |
| Touch controls not checked automatically | Bugs reach players | The repo's checks play with keys, so test on real phones every sprint and record each check in `production/qa/evidence/`. |
| Too much content per figure (art, writing, fact-checking) | Scope and budget overrun | Launch with 1–2 figures and add more after launch. Use `/scope-check` and `/cut` at each milestone. |
| Engine route less proven in this template | Tooling gaps | Note gaps as they appear and adjust the repo's skills, since the template is meant to be edited. |

## Material we need from the team

The plan's scope, schedule and budget stay open until these arrive.

- [ ] Historical figures and their eras, ranked by priority
- [ ] Key events, battles or stories for each figure
- [ ] Sources (books, archives) and the named accuracy reviewer
- [ ] Target audience (students or general players, age range) and whether the game is for education or entertainment
- [ ] Game style ideas and reference games
- [ ] Art direction (e.g. Đông Hồ paintings, lacquer art, or modern)
- [ ] Business model: paid, free with ads, in-app purchases, or school or government funded
- [ ] Team: size, roles, and who does art, audio and code
- [ ] Target launch date and budget

## Next steps

- [ ] Install Android Studio and Godot 4, and fix the Xcode license prompt
- [ ] Register the Apple Developer and Google Play Console accounts
- [ ] Start Claude Code in the repo root and run `/start` and `/setup-engine`
- [ ] Build an empty project for Android and iOS and run it on a real phone
- [ ] Collect the team material above, then update this plan with real figures, scope and dates
