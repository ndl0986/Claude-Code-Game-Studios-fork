# TASK-137 follow-up: one shape per animal, duckbill siblings at 64 px, OQ-1 idle check

These are the two non-blocking findings from game-dev-ios's review of batches 3–6 (cb44a14b), done as a small batch
on `content/dino-art-followup`.

## 1. S, K and W: the head is no longer a separate island

The plated heads sat about 6 units off the torso. The art's outline hid the gap, but the silhouette (body union + 3)
showed two blobs, so the stardust would have landed on two islands.
- **Fix:** a short neck now joins the head to the torso, and the head pivot moves to the neck's base (420, 334).
- **New check:** `figures.py` counts the silhouette's islands for every figure and fails the run on a mismatch. It
  expects 1 per figure, n for n babies, and 2 for M (her baby stands apart).
- **Watched it fail first:** against the old templates it flagged exactly S, K and W (`islands 2 (expected 1)`). Now
  all 36 pass (`figures-run.log`).

## 2. Duckbill siblings at 64 px (spec S-7)

`s7-64px-before-after.png` shows white silhouettes at about 64 px figure height: the row above is cb44a14b, the row
below this branch. It also has the plated three. Its script is `s7_check.py`, rendered 1:1.

| Item | Before | After |
|---|---|---|
| E | a short bill | a **long, flat duck bill** past the head |
| H | a small nose bump | a **deep snout under a broad arched nose** |
| I | a small thumb spike | a **longer thumb spike** forward of the chest |
| L | the hatchet crest | unchanged: already distinct |
| M | a brow mark and the baby | **head lowered toward her baby** (a pose no sibling has), plus the baby |

**My read at 64 px:**
- E, L and M separate clearly.
- H and I separate by the head's depth and the spike, which is less strong than the others. If Luan wants more, H's
  arch is the knob.
- **My own call for Luan's look:** M's lowered neck leaves a small hump above the shoulder.

## 3. OQ-1 proposal backed by a check (`art-tools/idle_check.py`)

The proposed idles turn `head` and `tail` around their pivots, in degrees:
- duckbill: head 4, tail 3;
- horned: head 3, tail 3;
- plated: head 2, tail 4;
- ornithomimid: head 5, tail 3.

The check tries every pose at the extremes (each part at −A, 0 and +A) and counts the islands. **All 13 letters stay
one shape** (M stays 2, as drawn). On the old templates it reports **GAP for S, K and W**, so it catches the fault
game-dev-ios predicted. The rates and phases are the proposal in the message to the leader. Cast Rendering R7 owns
the data.

## Checks

| Check | Result |
|---|---|
| `figures.py` all 36 | ALL OK: within R-2, fill, inside, islands (`figures-run.log`). |
| Local D4 lint | PASS, 72 files (`lint.log`). |
| Reproducible | A fresh run matched all 72 committed SVGs. |
| `verify.sh --dev --no-xcode` | **PASS** (`verify.log`, paths masked), including 004's raster check on all 36 pairs. |

Changed SVGs: E, H, I, M, S, K and W (cast and silhouette). No id, path, part name or node count changed. The plated
head pivot moved.
