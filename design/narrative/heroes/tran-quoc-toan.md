# Hero: Trần Quốc Toản: mission beats and quiz

> **Status:** DRAFT · Task: TASK-004 · Owner: game-art-content · 2026-11-14
> **History sign-off:** NOT SIGNED. Every claim below is ⟨placeholder⟩ until Luan
> signs it off (pillar *Đúng sự thật / True to history*). A Claude session wrote this
> draft and cannot open or verify the sources. Each source location marked ⟨to confirm⟩
> must be checked against the real book by Luan or the team.

## Luan's decisions this file follows (2026-11-14)

| # | Decision |
|---|---|
| D1 | **Sources, in order:** the current primary-school SGK Lịch sử (and the Tiếng Việt reading where the story appears) first, then *Đại Việt sử ký toàn thư*. Textbook series: **Kết nối tri thức với cuộc sống** (CT GDPT 2018). |
| D2 | **Popular-tradition details** (the orange, the banner) are labelled **legend**. |
| D3 | **His death:** one short, calm line in the ending. No scene. |
| D4 | **Landscape** for the missions, menus and the map, until the phone prototype confirms it. |
| D5 | **Quiz stars, retry until right:** 3★ every question right first try, 2★ up to 2 retries, 1★ finished. A wrong answer is soft lavender-grey. Finishing always unlocks the next hero. |
| D6 | **C06 and C08** stay legend until the S3 1282 passage is confirmed, then become fact (as the chronicle records it). |
| D7 | **Beat structure (§ 3, § 6) approved** for TASK-003b. Claims C01–C11 and the source locations are **not yet signed off**. |
| D8 | **Luan signed off (2026-11-14):** C04's wording "Vua Trần họp các vương hầu và trăm quan ở bến Bình Than để bàn việc đánh giặc" (chronicle 1282), and C13 = **15** (born 1267). In the data their `signoff` stays `pending` until their sources are confirmed, because R5 refuses an approved fact with a `to_confirm` source. See § 5. |

## 1. Sources

| ID | Source | Location | Kind |
|---|---|---|---|
| S1 | *Lịch sử và Địa lí*, Kết nối tri thức với cuộc sống, NXB Giáo dục Việt Nam | Grade ⟨to confirm: 4 or 5⟩, lesson on the Trần dynasty and the resistance against the Mông–Nguyên ⟨to confirm⟩, page ⟨to confirm⟩ | Textbook (primary) |
| S2 | *Tiếng Việt*, Kết nối tri thức với cuộc sống, NXB Giáo dục Việt Nam | Grade and page ⟨to confirm⟩. **Not yet known whether this series has the reading.** The older curriculum's *Tiếng Việt 2* had "Bóp nát quả cam", adapted from S4 | Textbook reading |
| S3 | *Đại Việt sử ký toàn thư*, Bản kỷ, Kỷ nhà Trần, reign of Trần Nhân Tông | Entries for the year Nhâm Ngọ (1282) and Ất Dậu (1285) ⟨to confirm⟩; translation edition ⟨to confirm, e.g. NXB Khoa học Xã hội⟩ | Court chronicle (15th century) |
| S4 | Nguyễn Huy Tưởng, *Lá cờ thêu sáu chữ vàng* | Any edition, e.g. NXB Kim Đồng ⟨to confirm⟩ | Children's historical novel (literature) |
| S5 | Wikipedia, "Trần Quốc Toản" (EN), citing Vietnamese encyclopedia sources for the birth year 1267 | https://en.wikipedia.org/wiki/Tr%E1%BA%A7n_Qu%E1%BB%91c_To%E1%BA%A3n · ⟨to confirm against the primary source it cites⟩ | secondary (in `sources.json`, schema 1.3) |
| S6 | Dân Việt, "Bến Bình Than, nơi Trần Quốc Toản bóp nát quả cam…" (2023-02-21) | https://danviet.vn/ben-binh-than-noi-tran-quoc-toan-bop-nat-qua-cam-nay-la-mien-que-nao-cua-tinh-bac-ninh-20230221132457635-d1076438.html · ⟨to confirm⟩ | secondary (in `sources.json`) |
| S7 | Luật Minh Khuê, "Kể về người anh hùng Trần Quốc Toản" (a retelling: "mới 15 tuổi") | https://luatminhkhue.vn/ke-ve-nguoi-anh-hung-tran-quoc-toan.aspx · ⟨to confirm⟩ | secondary (in `sources.json`) |

**Rule:** a claim is **fact** only if S1 or S3 states it. A detail that comes only from S4,
or from the S2 reading adapted from S4, is **legend**. Anything the game adds for play is
**invented** and is never put in the quiz.

## 2. Claim register

Labels: **fact** · **interpretation** · **legend** (popular tradition, D2) · **invented**
(made for the game, never quizzed). All rows are ⟨placeholder⟩ until signed.

| ID | Claim (VI) | Claim (EN) | Label | Source | Status |
|---|---|---|---|---|---|
| C01 | Trần Quốc Toản sống vào thời nhà Trần. | Trần Quốc Toản lived in the time of the Trần dynasty. | fact | S1, S3 | ⟨placeholder⟩ |
| C02 | Ông là người trong hoàng tộc nhà Trần, được phong tước Hoài Văn hầu. | He belonged to the Trần royal family and held the title Hoài Văn hầu. | fact | S3 ⟨to confirm⟩ | ⟨placeholder⟩ |
| C03 | Quân Mông–Nguyên chuẩn bị sang xâm lược Đại Việt. | The Mông–Nguyên (Yuan) army was preparing to invade Đại Việt. | fact | S1, S3 | ⟨placeholder⟩ |
| C04 | Vua Trần họp các vương hầu và trăm quan ở Bình Than để bàn việc đánh giặc (năm 1282). | The Trần king gathered the princes, lords and officials at Bình Than to plan the defence (1282). | fact | S3 (1282): *"Mùa đông tháng 10, vua ngự ra Bình Than đóng ở vũng Trần Xá họp vương hầu và trăm quan, bàn kế sách công thủ và chia nhau đóng giữ các nơi hiểm yếu"* (quoted via the leader's research; page ⟨to confirm⟩). Not the bô lão: that is Diên Hồng (1284) | ⟨placeholder⟩ |
| C05 | Trần Quốc Toản còn nhỏ tuổi nên không được dự bàn. | Trần Quốc Toản was too young, so he was not allowed to join the meeting. | fact | S3 (1282) ⟨to confirm⟩ | ⟨placeholder⟩ |
| C06 | Vì quá tức giận, ông bóp nát quả cam vua ban lúc nào không biết. | He was so angry that he crushed the orange the king had given him, without noticing. | **legend** (D2); becomes fact (as the chronicle records it) once the S3 1282 passage is confirmed | S4, S2 ⟨to confirm⟩; S3 1282 ⟨to confirm⟩ | ⟨placeholder⟩ |
| C07 | Ông về nhà tập hợp người thân và gia nhân, luyện tập để đánh giặc. | He went home, gathered his relatives and followers, and trained them to fight. | fact | S3 ⟨to confirm⟩ | ⟨placeholder⟩ |
| C08 | Ông may lá cờ thêu sáu chữ vàng "Phá cường địch, báo hoàng ân". | He made a banner with six golden words, "Phá cường địch, báo hoàng ân" ("Defeat the strong enemy, repay the king's kindness"). | **legend** (D2); becomes fact (as the chronicle records it) once the S3 1282 passage is confirmed | S4, S2 ⟨to confirm⟩; S3 1282 ⟨to confirm⟩ | ⟨placeholder⟩ |
| C09 | Đội quân của ông cùng quân nhà Trần đánh giặc Nguyên. | His band fought the Nguyên invaders alongside the Trần army. | fact | S1, S3 (1285) ⟨to confirm⟩ | ⟨placeholder⟩ |
| C10 | Trần Quốc Toản hy sinh khi còn rất trẻ, vì đất nước. | Trần Quốc Toản gave his life for his country while he was still very young. | fact (D3 wording) | S3 (1285) ⟨to confirm⟩ | ⟨placeholder⟩ |
| C11 | Nhà Trần đánh thắng quân Mông–Nguyên. | The Trần dynasty defeated the Mông–Nguyên army. | fact | S1, S3 | ⟨placeholder⟩ |
| C12 | Bến sông đông thuyền, rơm tập đánh, giặc rơi vũ khí rồi bỏ chạy… | A busy riverbank, straw training dummies, enemies dropping weapons and running away… | **invented** | none (game play) | ⟨placeholder⟩ |
| C13 | Năm diễn ra hội nghị Bình Than (1282), Trần Quốc Toản mới 15 tuổi (sinh năm 1267; 16 tuổi theo tuổi mụ). | In the year of the Bình Than meeting (1282), Trần Quốc Toản was 15 (born 1267; 16 by the traditional count). | fact (derived: birth year 1267 + meeting in the 10th month of 1282). **Luan chooses 15 or 16 (tuổi mụ)** | S3, S5, S7 (data); S5/S7 secondary, ⟨to confirm⟩ | ⟨placeholder⟩ |
| C14 | Truyện kể rằng Quốc Toản đến bến Bình Than, xin được gặp vua để xin đánh giặc; lính canh không cho vào vì cậu còn nhỏ. | The story says Quốc Toản came to Bình Than and asked to see the king to ask to fight; the guards would not let him in because he was young. | **legend** | S4, S2 ⟨to confirm⟩; S6 | ⟨placeholder⟩ |
| C15 | Truyện kể rằng vua khen Quốc Toản còn trẻ mà đã biết lo việc nước, và ban cho cậu một quả cam. | The story says the king praised Quốc Toản for caring for the country while so young, and gave him an orange. | **legend**; becomes fact (as the chronicle records it) if the S3 1282 passage records the king giving the orange | S4, S2 ⟨to confirm⟩; S3 1282 ⟨to confirm⟩ | ⟨placeholder⟩ |
| C16 | Trong truyện, Quốc Toản nói: "Xin Quan gia cho đánh! Cho giặc mượn đường là mất nước!" (in the game: "Xin nhà vua cho đánh!", Luan 2026-11-14) | In the story, Quốc Toản says: "Let us fight, Your Majesty! Letting the enemy pass means losing our country!" | **legend** (words from the literary telling; not quoted from the chronicle) | S4, S2 ⟨to confirm⟩ | ⟨placeholder⟩ |

> **C06 and C08: relabel condition (Luan, 2026-11-14).** Both stay **legend** for now.
> They become **fact (as the chronicle records it)** only once the S3 passage for 1282 is
> confirmed in the book, with its edition and page. Until then, the beats and the quiz word
> them "Truyện kể rằng… / The story says…".
>
> **Not stated anywhere in this draft:** his exact age, birth year, where and how he died,
> or the number of followers. These differ between tellings, so the beats say "young" and
> "his band". Add them only once a source has been checked.

## 3. Mission beats

Landscape side-scrolling (D4). Each beat teaches **at most one** new button. The buttons
are **move**, **attack**, **defend** and **special**. Defeat is shown as knock-back: an enemy
stumbles, drops its weapon and runs home. No blood or gore. **No text is painted into art.**
Every word on screen, including the banner's six words, is a VI/EN text layer.

Scene lines are written for voice-over: short sentences that a 6-year-old understands when
read aloud. **Each sentence is its own dialogue box**, at most 120 characters
(`.claude/rules/narrative.md`); every sentence below fits.

**Canon level (`.claude/rules/narrative.md`):** the whole file is **Under Review**. A
claim becomes **Established** only when Luan signs it off.

### Beat 1: Khi các vương hầu họp bàn ở Bình Than / When the lords met at Bình Than

**Corrected (Luan, 2026-11-14):** the old card ("Giặc Nguyên sắp sang xâm lược." on a card titled
"Đến bến Bình Than") could be read as "he went to Bình Than and met the enemy". The context now
comes first, in the **intro**, in order: the invasion is coming that year (C03) → his age that
year (C13) → the king's meeting at Bình Than (C04). Then beat 1 says why he goes.

- **Intro (VI / EN):**
  1. "Ngày xưa, thời nhà Trần, có một cậu bé tên là Trần Quốc Toản." / "Long ago, in the time of the Trần dynasty, there was a boy named Trần Quốc Toản." (C01)
  2. "Năm ấy, quân Mông–Nguyên chuẩn bị sang xâm lược Đại Việt." / "That year, the Mông–Nguyên army was getting ready to invade Đại Việt." (C03)
  3. "Năm ấy, Trần Quốc Toản mới 15 tuổi." / "That year, Trần Quốc Toản was only 15 years old." (C13; 15 from birth year 1267, or 16 by tuổi mụ if Luan prefers)
  4. "Vua Trần họp các vương hầu và trăm quan ở bến Bình Than để bàn việc đánh giặc." / "The Trần king called his lords and officials to Bình Than to plan the defence." (C04)
- **Beat card title (Luan, 2026-11-14):** "Khi các vương hầu họp bàn ở Bình Than" / "When the lords met at Bình Than" (C04). It's a context title, not "Đến…", which could also mislead. Luan's full wording, "Khi các vương hầu họp bàn ở **hội nghị** Bình Than", wraps to 2 lines in the 1-line heading box (1000 px against 854 px at 44 px bold, R8c). The shortest faithful form drops "hội nghị" and keeps "các" and "họp bàn" (820 px, 1 line). Luan may prefer the full title with a 2-line heading box instead.
- **Scene:** "Quốc Toản muốn xin vua cho cùng đi đánh giặc." / "Quốc Toản wants to ask the king to let him fight too." (C05) · "Cậu vội đến bến Bình Than, nơi vua đang họp." / "He hurries to Bình Than, where the king is holding the meeting." (C04)
- **Goal:** "Đến chỗ vua họp ở Bình Than!" / "Get to the king's meeting at Bình Than!" (C12)
- **Play:** **move**. A busy riverbank, with no enemies anywhere in this beat. At the end, the
  guards kindly raise a hand at the meeting's gate. Gate, crowd and carts: C12 invented.
- **Who met (resolved by research, Luan to confirm):** the chronicle (S3, 1282) has the king
  meeting **the vương hầu and trăm quan** at Bình Than. The **bô lão** met at **Diên Hồng** (1284),
  a different event that some books and exercises confuse with Bình Than.

### Beat 1b: Xin gặp vua / Asking to see the king (TASK-016, plan approved by Luan 2026-11-14)

**Script status: APPROVED by Luan (2026-11-14)**, with two changes he made: the king calls Quốc
Toản **"cháu"** (a young prince of the royal family), and **"nhà vua"** replaces "Quan gia"
(simpler for children; the literary telling's "Quan gia" is adapted). EN is unchanged. The
claims stay pending (history sign-off is per claim).

- **Story moment:** at the closed meeting gate, Quốc Toản asks to see the king to ask to fight.
  The guards kindly refuse because he is young. The noise brings the king out. Quốc Toản pleads,
  and the king praises him, gives him an orange and sends him home. Claims: C14, C16, C15
  (**legend**), C05, C04, C12 for the second refusal.
- **Play (new `dialogue` beat type):**
  - illustrated lines with a speaker portrait (Quốc Toản, a guard, the king) or narrator text;
    one sentence per box; tap "Tiếp";
  - **one action:** a big "Xin vào! / Let me in!" button the child taps **twice**. Each tap is
    Quốc Toản asking; the 2nd tap brings the king out;
  - no pads. The orange beat that follows is the playable emotional peak.
- **R4c (requested):** the opening narrator line carries the legend marker, and it covers the
  spoken lines of this beat.
- **Portrayal:**
  - The guards are kind and firm, never rough.
  - **The king (Trần Nhân Tông) is a symbolic image, not a likeness** (Luan): a Trần-era royal
    headdress ("vương miện", period form ⟨placeholder⟩, never a European crown), a beard and
    thick brows for dignity, warm eyes.

| # | Speaker | VI | EN | Claims |
|---|---|---|---|---|
| 1 | Narrator | Truyện kể rằng Quốc Toản đến bến Bình Than, xin được gặp vua. | The story says Quốc Toản came to Bình Than and asked to see the king. | C14 |
| 2 | Guard | Cậu còn nhỏ quá, chưa được vào họp đâu. | You are too young to join the meeting. | C05, C14 |
| — | *(child taps "Xin vào! / Let me in!")* | | | |
| 3 | Quốc Toản | Xin cho tôi gặp nhà vua! | Please let me see the King! | C14 |
| 4 | Guard | Không được đâu, vua đang bàn việc nước. | You can't. The king is planning for the country. | C04, C12 |
| — | *(child taps "Xin vào!" again)* | | | |
| 5 | Narrator | Nghe ồn ào, vua bước ra. | Hearing the noise, the king came out. | C14 |
| 6 | Quốc Toản | Xin nhà vua cho đánh! | Let us fight, Your Majesty! | C16 |
| 7 | Quốc Toản | Cho giặc mượn đường là mất nước! | Letting the enemy pass means losing our country! | C16 |
| 8 | King | Cháu còn trẻ mà đã biết lo cho đất nước, ta khen cháu. | You are young, yet you already care for our country. I praise you. | C15 |
| 9 | Narrator | Vua ban cho Quốc Toản một quả cam, rồi bảo cậu về. | The king gave Quốc Toản an orange and told him to go home. | C15 |

**Data (schema 1.4):** `ask` {at_line 2, taps 2, button "Xin vào! / Let me in!" (C14)}. So: line 1
→ Tiếp; line 2 (the guard refuses) → "Xin vào!" shows line 3 (Quốc Toản asks); line 3 → "Xin vào!"
shows line 4 (the guard refuses again); then Tiếp, and the noise brings the king out (line 5).

**Checks done:**
- Every line fits the scene box (R8c at 38 px, weight 600) in VI and EN, ≤ 2 lines.
- One sentence per box: the famous plea is split into lines 6 and 7.
- D-17: no line addresses the child player. "Cậu", "cháu" and "ta" are characters speaking
  to each other.

### Beat 2: Quả cam / The orange

- **Story moment:** he is told he is too young to join. Holding the king's orange, he
  squeezes it without noticing. Claims: C05, C06 (**legend**).
- **Play:** a short story moment, not combat. The child **holds** the special button to
  show his feeling growing. The orange is squeezed (juice, no mess on him), then he turns
  and runs home determined. Bad feelings are shown, never shamed.
- **Goal:** hold until the meter fills.
- **Scene, after TASK-016:** only "Truyện kể rằng cậu tức quá, bóp nát quả cam lúc nào không biết." / "The story says he was so upset that he crushed an orange without even noticing." (C06). The "too young" line moves into beat 1b, which now tells it.

### Beat 3: Lá cờ sáu chữ vàng / The banner of six golden words

- **Story moment:** at home he gathers his family and followers, trains them, and raises
  his banner. Claims: C07, C08 (**legend**).
- **Play:**
  - **attack**, taught on straw training dummies;
  - **defend**, taught against a friendly sparring partner's padded stick;
  - **special** raises the banner, and followers join and walk behind him.
  Training details: C12 invented.
- **Goal:** finish the training and raise the banner.
- **Banner art:** the six words are a **text layer**, not painted. The VI layer shows
  "Phá cường địch, báo hoàng ân". The EN layer shows the translation, with the VI words
  small beneath it.
- **Scene (VI):** "Quốc Toản về nhà, tập hợp mọi người cùng luyện võ. Truyện kể rằng cậu may một lá cờ thêu sáu chữ vàng: Phá cường địch, báo hoàng ân."
- **Scene (EN):** "Quốc Toản went home and trained his people to fight. The story says he made a banner with six golden words: 'Defeat the strong enemy, repay the king's kindness.'"

### Beat 4: Cùng đánh giặc / Fighting the invaders

- **Story moment:** his band joins the Trần army against the Nguyên invaders. Claims: C09,
  C11. Specific enemies and places: C12 invented.
- **Play:** `reach-the-flag` with two enemy encounters on the way (move, attack, defend).
  **attack** knocks enemies back, and they drop their weapons and run home; **defend** blocks a
  telegraphed strike. No special pad and no arrows (D-10: B, Luan 2026-11-14; combat GDD). Drama
  comes from the wind, river and sky.
- **Goal:** reach the Trần army's flag. Getting hit only knocks him back a step: no lives,
  no game over.
- **Scene (VI):** "Đội quân nhỏ của Quốc Toản cùng quân nhà Trần đánh giặc Nguyên." (as in `mission.json` `tqt.f4.scene.1`)
- **Scene (EN):** "Quốc Toản's small band fought the Nguyên invaders alongside the Trần army."

### Ending (no scene, D3)

A calm still picture: the banner on a riverbank at dawn. Two lines:

- **VI:** "Nhà Trần đã đánh thắng quân Mông–Nguyên. Trần Quốc Toản đã hy sinh khi còn rất trẻ, vì đất nước." (C11, C10)
- **EN:** "The Trần dynasty defeated the Mông–Nguyên army. Trần Quốc Toản gave his life for his country while he was still very young." (C11, C10)

## 4. Quiz

Five picture-supported, three-choice questions. **Invented details (C12) are never quizzed.**
Each **legend** question starts "Truyện kể rằng… / The story says…".
- **Retry until right (Luan, 2026-11-14).** A wrong answer makes its card shake gently
  and turn soft lavender-grey (art bible § 4, "Try again", never red), and the child tries
  again. When the child picks the right answer, the game shows the "why" line with the
  beat's picture.
- No time limit.
- **Stars** are counted over the whole quiz (Luan, 2026-11-14):
  - 3★: every question right on the first try;
  - 2★: up to 2 retries in total;
  - 1★: finished.
  ⟨tuning: the thresholds belong to the quiz system spec⟩.
- Finishing the quiz always unlocks the next hero. Stars reward mastery; they never gate it.

| # | Question (VI / EN) | Choices (correct first here; shuffled in game) | Claim | Why line (VI / EN) |
|---|---|---|---|---|
| Q1 | Trần Quốc Toản sống vào thời nhà nào? / Which dynasty did Trần Quốc Toản live in? | **Nhà Trần / Trần** · Nhà Lý / Lý · Nhà Lê / Lê | C01 | Họ của ông là Trần, ông sống thời nhà Trần. / He lived in the time of the Trần dynasty. |
| Q2 | Vì sao Quốc Toản không được vào bàn việc nước ở Bình Than? / Why wasn't Quốc Toản allowed into the meeting at Bình Than? | **Vì cậu còn nhỏ tuổi / He was too young** · Vì cậu đến muộn / He was late · Vì cậu bị ốm / He was ill | C05 | Cậu còn nhỏ tuổi nên không được dự bàn. / He was too young to join. |
| Q3 | Truyện kể rằng Quốc Toản đã bóp nát quả gì? / The story says Quốc Toản crushed what fruit? | **Quả cam / An orange** · Quả chuối / A banana · Quả dừa / A coconut | C06 (legend) | Truyện kể rằng cậu bóp nát quả cam vua ban. / The story says he crushed the orange from the king. |
| Q4 | Truyện kể rằng lá cờ của Quốc Toản thêu mấy chữ vàng? / The story says Quốc Toản's banner had how many golden words? | **Sáu / Six** · Ba / Three · Mười / Ten | C08 (legend) | "Phá cường địch, báo hoàng ân": sáu chữ. / "Phá cường địch, báo hoàng ân": six words. |
| Q5 | Quốc Toản cùng quân nhà Trần đánh giặc nào? / Which invaders did Quốc Toản fight with the Trần army? | **Quân Mông–Nguyên / The Mông–Nguyên army** · Quân Minh / The Ming army · Quân Thanh / The Qing army | C09 | Thời nhà Trần, quân ta đánh giặc Mông–Nguyên. / In the Trần times, Đại Việt fought the Mông–Nguyên invaders. |

Picture needs: one icon per choice (dynasty banners for Q1, the three fruits for Q3, and so
on). These go to `/asset-spec` after Luan's sign-off.

## 5. Sign-off checklist for Luan

- [ ] S1 to S4: confirm the grade, lesson and page for S1 and S2 (does the Kết nối tri thức *Tiếng Việt* have the reading?) and the S3 translation edition.
- [x] **C04** (wording) and **C13** (15): signed off by Luan, 2026-11-14 (D8). The data flips to `approved` once S3 (and the birth-year source) are `confirmed` (R5).
- [ ] C01 to C03, C05 to C11: sign each claim, or correct it.
- [x] C06 and C08: the rule is decided (Luan, 2026-11-14). They stay legend until the S3 1282 passage is confirmed (see § 2).
- [x] The four beats: the structure is approved (Luan, 2026-11-14). The claims inside them still need sign-off.
- [ ] The ending lines (D3 wording).
- [ ] Quiz Q1 to Q5. The star rule is decided (retry until right, Luan 2026-11-14).
- [ ] Portrayal: the orange beat shows anger without shaming; the battle shows knock-back only.

When signed, change each row's status to `signed (Luan, <date>)` and remove ⟨placeholder⟩.

## 6. Beat structure for TASK-003b: structure approved by Luan; claims still need sign-off

**Status: structure approved by Luan (2026-11-14); claims still need sign-off.** This is
the structure for TASK-003b: the riverbank to Bình Than, then the orange, then training
and raising the banner, then fighting beside the Trần army. TASK-003 ships as approved,
with 4 combat beats and move, attack and defend. The text is still ⟨placeholder⟩, so keep
strings in data, not code.

| Beat | Buttons used | New button taught | Enemies | Ends when |
|---|---|---|---|---|
| 1 Riverbank | move | move | none | reach the gate |
| 2 Orange | special (hold) | hold special | none | hold meter full |
| 3 Banner | attack, defend, special | attack, defend, special (tap) | straw dummies + a friendly sparring partner | banner raised, followers join |
| 4 Battle | move, attack, defend (no special, D-10) | none | two encounters of slow enemies | reach the Trần flag |

Rules for every beat: no lives or game over, getting hit means a small knock-back, defeated
enemies drop their weapons and run, and the banner's words are a text layer. Then show the
ending still and two lines, and then the five-question quiz (retry until right, stars as in § 4).

## 7. Content data (TASK-009, 2026-11-14)

This doc is the source for `content/data/heroes/tran-quoc-toan/` (and the draft in `content/drafts/heroes/tran-quoc-toan/`). Every claim's `signoff` is
`pending` until Luan signs it off (D-03). Release builds refuse the mission (R12), and debug
builds show `UNSIGNED Cxx` badges.

| File | What | Bundled? |
|---|---|---|
| `content/data/heroes/tran-quoc-toan/claims.json` | C01–C12 as in § 2. C06 and C08 carry the relabel condition (D6) | yes |
| `content/data/heroes/tran-quoc-toan/mission.json` | **The slice mission (D-08: B, Luan 2026-11-14):** walk (riverbank) → hold-meter (the orange) → training (dummies 3, blocks 3, finish_special, banner) → reach-the-flag (2 encounters). No special pad on reach-the-flag (D-10: B) | yes |
| `content/data/heroes/tran-quoc-toan/quiz.json` | Q1–Q5 as in § 4. Q3 and Q4 open with the legend marker. Each choice cites its question's claim | yes |
| `content/drafts/heroes/tran-quoc-toan/mission-fights.json` | The earlier 4-fight version (P-02, now superseded). Kept as a draft only | no |

Every story screen can be skipped with a kind warning. A run with a skipped screen earns no
medal for this story (D-07; mission-flow GDD Core Rule 15).

**Pictures:** the 16 picture ids (`pic.quiz_*`, `pic.scene_tqt_ending`) currently point to flat
placeholder PNGs (shape and colour, art bible palette, no text) in `content/data/pictures/`. Real
art replaces each file under the same id after `/asset-spec`.

**No next hero yet:** `next_hero` is `null`. Results then shows `ui.results.more_heroes` ("Còn nhiều anh hùng nữa sắp đến / More heroes are coming") and returns to the title, with no unlock screen (leader's call, 2026-11-14).
