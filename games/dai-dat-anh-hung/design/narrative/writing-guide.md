# Writing Guide: player text for Dải Đất Anh Hùng

> **Owner**: game-art-content · History and voice sign-off: Luan
> **Applies to**: every player-facing line in `content/data/` (strings, missions, quizzes) for
> every hero. A new hero's content is checked against this guide before review.
> **Last Updated**: 2026-11-14

## 1. Voice and address (D-17, Luan 2026-11-14)

- **Vietnamese: no pronoun for the child where possible.** Write instructions and messages with
  the subject left out, as natural Vietnamese allows: "Thử lại nhé!", "Giữ chặt nút lá cờ!",
  "Nếu bỏ qua, sẽ chưa nhận được huy hiệu của câu chuyện này nhé."
- **When a pronoun is needed, address the child as "em"**, as the primary-school textbooks do.
  Never "bạn", "con", "cháu" or "các bạn".
- **Pronouns for people in the story are not this rule.** Narration may call the hero "cậu" (a
  boy) or "ông" (an adult hero), as the story needs; that's third person.
- **English:** plain "you" is fine ("Try again!", "If you skip, you won't get this story's medal
  yet.").
- **Tone:** warm and encouraging; soft particles ("nhé") are welcome. Never scold or shame, and
  never red for a mistake (art bible §4).

## 2. Words a child understands

- No designer words on screen: not "special", "beat", "level", "meter", "spawn". Name what the
  child sees ("nút lá cờ / the flag button", "Phần / Part").
- One idea per sentence, short words, read-aloud friendly (voice-over comes later).

## 3. Format rules (enforced by validation)

- One sentence per story box, at most 120 characters (R8). EN fits the field budget in
  `content/data/rules.json` (e.g. `ui` 24, `button` 12, `dialog` 60, `goal` 60).
- All text is Unicode NFC, with full Vietnamese diacritics (R7).
- No text inside pictures: words are always a text layer (art bible; Luan's rule 2).

## 4. History rules

- Every story, scene, ending and quiz line cites at least one claim (R3). Claims live in the hero's
  `claims.json`, from `design/narrative/heroes/<hero>.md`.
- A line citing a **legend** claim carries a marker from `markers.json` ("Truyện kể rằng… / The
  story says…") in sentences. Short labels (banner, titles, choices) may rely on a marked sentence
  nearby (R4, R4b).
- Invented details are labelled `invented` and never quizzed (R6).
- No dates, ages, places or numbers that the sources haven't confirmed.
- Death is one calm line, never shown; no question about death or injury (D3, Quiz Q7).

## 5. Before review

Run the content checks (schema plus R1–R18) and read every line aloud in Vietnamese once.
