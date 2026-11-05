# Generated game art

## Taunt expressions and launcher icon

Created with the built-in image_gen tool. Project assets:

- `rivals-angry-v1.png`: transparent five-column, two-row atlas in Persona order. It overrides idle frames while taunted, including when animation is disabled or the rival folds. The next lot restores normal expressions.
- `app-icon-v1.png`: opaque square enchanted eye-gavel artwork, used on the menu and as the source for platform launcher generation. The handle was corrected after visual review.

### Angry portrait prompt

Use case: identity-preserve. Edit the provided rival portrait atlas into angry expressions. Output exactly FIVE columns and TWO rows of equal SQUARE cells, aspect ratio 5:2, ten portraits. Use ONLY characters in first two rows of reference, same order. Preserve exact character identities, costumes, props, palette, pixel-art style, head sizes and positions within cells. Every character visibly angry: strongly furrowed inward-sloping brows, narrowed open eyes, tense scowling mouths; no smiles. Anger must read at 56px. Do not add emoji, symbols, flames or text. Preserve glasses, masks, beards, fan, candle and other accessories. Fully contained characters, transparent background, no borders. Top row: spectacles man, crown fan woman, bearded cane man, purple masked woman, hooded candle monk. Bottom: owl woman, loupe professor, high collar aristocrat, coin woman, wine baron. Only change expressions.

Reference: `rivals-neutral-v3.png`.

### Icon prompt

Use case: stylized-concept. Create a unique square app icon for Cursed Auction House, matching the reference's chunky gothic pixel-art objects, antique gold outlines, rich plum shadows and oxidized teal highlights. Reference is style only, do not reproduce atlas. One bold enchanted auction gavel, its gold and purple head contains a single luminous teal slit-pupil eye, handle angled down-right, hovering above a small gold auction strike block. A few crisp teal spectral sparks suggest the curse. Opaque deep midnight plum background, subtle stepped halo. Strong simple silhouette readable at 32 pixels, central design inside middle 70% for launcher masking, generous padding. Crisp deliberate pixel clusters, limited palette, polished retro game inventory art, no smooth 3D, no text, no letters, no rounded outer corners, no border. Full-bleed square opaque image.

Reference: `artifacts-pixel-v2.png`.

### Final handle correction prompt

Precise geometry correction only to the gavel handle. Keep head and eye and base and all design identical. The handle still slopes too steeply downward. Rotate the ENTIRE handle and socket counterclockwise about its attachment on the right side of the head by about 20 degrees, so it extends more to the RIGHT, only slightly downward. In this 1254 square composition: attachment remains near (710,490), move handle's far end from (990,800) to about (1080,660). Handle must be straight and its long axis visibly perpendicular to the long cylinder axis of the hammer head. Keep length, purple wrapping, gold trim, jewel pommel, pixel art, exact background and strike block. No other changes.

## Living pixel-art animation

Runtime uses rows 1–2 of `rivals-neutral-v3.png` for open-eyed neutral poses and rows 3–6 of `rivals-idle-v3.png` for blink/glance poses. Both atlases have five columns and six rows. The correction also opened eyes in its blink row, so that row is deliberately unused; the original closed-eye frames are preserved.

The active rival atlas is `rivals-idle-v3.png`: five columns and six rows. Rows 1–2 are neutral, rows 3–4 blink, and rows 5–6 glance; each pair uses the same ten-rival roster order. Rivals spend most of their cycle neutral, blink briefly, and occasionally glance sideways. Breathing uses one-pixel movement. Different durations and phase offsets keep rivals from moving in unison. Public leading/taunted status adds small shifts; folded rivals stop. Reduced motion and disabled TickerMode stop the ticker; taunted rivals retain their angry expression.

Artifact artwork remains `artifacts-pixel-v2.png`, with restrained stepped floating, slight rocking (except heavy idols), and a brief decorative pixel glint. Neither pose nor glint depends on hidden values, curses, or bluff state. Selection, dossier and results remain static for readability.

The portrait animation atlas was created with the built-in image_gen tool using `rivals-pixel-v2.png` as the edit target. Original atlases are retained.

### Animation atlas prompt

Use case: identity-preserve. Edit target: the supplied pixel-art rival atlas. Create an animation atlas with EXACTLY FIVE columns and SIX rows, 30 equal SQUARE cells, canvas aspect ratio 5:6. Keep the ten original characters, pixel-art style, colors, costumes, props, face shapes and scale. Each pair of rows repeats the original roster in exactly its original order. Rows 1 and 2: neutral eyes-open idle portraits. Rows 3 and 4: identical portraits with eyes CLOSED in a natural blink (glasses stay, eyelids closed behind them). Rows 5 and 6: identical portraits with a subtle sideways eye glance and tiny head tilt, not a new pose. Every cell same registration: identical head size, shoulder baseline, prop locations and center, no zoom or camera movement between frames. Changes must be extremely small, suitable for swapping frames in a game. Portraits fully contained within cells with generous transparent margin. Character order in odd rows: elderly spectacles man, crowned fan lady, bearded cane man, purple mask lady, candle monk. Even rows: dark-haired owl lady, white-haired loupe professor, stern high collar man, coin rogue girl, wine baron. Crisp chunky pixel art, simple shading, no realism. No text, labels, borders, background or grid lines. True transparent background.

### Targeted atlas correction

undefined

## Previous pixel-art pass

Current artwork uses a simplified pixel-art direction, generated with the built-in image_gen tool (not the API CLI). PNG atlases retain transparency and are bundled by pubspec.yaml.

- rivals-pixel-v2.png: five columns, two rows; row-major order matches Persona.values.
- artifacts-pixel-v2.png: four columns, four rows; urn, reliquary, mask, dagger, scythe, blade, grimoire, codex, scroll, crown, amulet, locket, idol, effigy, totem, Crown of Nine Sorrows.
- rivals-v1.png and artifacts-v1.png: retained earlier painted artwork, no longer used by the game.

Flutter renders the current sprites without texture filtering and moves them in whole logical-pixel steps to avoid soft subpixel bobbing. These are generated pixel-style illustrations, not hand-authored 32x32 source sprites.

Animation uses Flutter transforms, not frame-by-frame character animation: idle bobbing, leader/taunt accents, folded fading, and floating artifacts. Reduced motion disables motion and transitions; offstage tickers pause. Selection and dossier portraits are static. Appearance uses public names only; hidden curses and values do not affect it. Later Endless bosses currently reuse category art.

## Current portrait prompt

undefined

## Current artifact prompt

undefined

## Archived first-pass generation notes

Created with the built-in image_gen tool (not the API CLI). These PNG atlases preserve transparency and are bundled by pubspec.yaml.

- rivals-v1.png: five columns, two rows; row-major order matches Persona.values.
- artifacts-v1.png: four columns, four rows; urn, reliquary, mask, dagger, scythe, blade, grimoire, codex, scroll, crown, amulet, locket, idol, effigy, totem, Crown of Nine Sorrows.

Animation uses Flutter transforms, not frame-by-frame character animation: idle bobbing, leader/taunt accents, folded fading, and floating artifacts. Reduced motion disables motion and transitions; offstage tickers pause. Selection and dossier portraits are static. Appearance uses public names only; hidden curses and values do not affect it. Later Endless bosses currently reuse category art.

## Portrait prompt

Use case: stylized-concept. Asset type: game portrait atlas for Cursed Auction House. Create one square transparent PNG atlas, exactly 5 columns by 2 rows of equally sized cells. Each cell contains one centered waist-up gothic auction rival, with generous transparent padding; no overlap across cells. Hand-painted dark fantasy storybook, crisp silhouettes readable at 56 pixels, muted plum, antique gold, teal rim lighting. Top row left to right: elderly thin man with spectacles and Victorian suit (Silas); regal woman with small crown and closed fan (Duchess); bearded collector with cane (Orrin); mysterious woman with half mask and ring (Vex); hooded monk holding candle (Morrow). Bottom row: dark-haired woman with owl brooch and pocket watch (Ravenna); elderly professor with magnifying loupe (Ash); stern aristocrat with high collar (Harrow); roguish young woman with coin and catalogue (Jinx); opulent heavyset baron holding wine glass (Gilt). All portraits same scale, fully contained in their cells, face at same relative height. No text, no letters, no labels, no borders, no backgrounds. Actual transparent background.

## Artifact prompt

Use case: stylized-concept. Asset type: transparent artifact atlas for gothic auction game. One square PNG with precisely 4 columns and 4 rows of equal square cells, one isolated object centered in each cell with 15 percent transparent margin, no overlapping cells. Hand-painted dark fantasy storybook, antique gold, oxidized teal, plum shadows, readable silhouettes. Row 1: ancient urn; jeweled reliquary box; haunted ceremonial mask; curved dagger. Row 2: small scythe; ancient sword blade; closed grimoire; chained codex. Row 3: rolled scroll; small royal crown; pendant amulet; oval locket. Row 4: stone idol; wooden effigy; carved totem; elaborate boss crown with nine dark jewels. Each complete object fully visible in its cell. Subtle highlights, no external effects or cast shadows crossing cells. No text, labels, cell borders, scenery, floor. Truly transparent background.
