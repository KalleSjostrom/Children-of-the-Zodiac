# Asset requests for the look prototypes

Requests to run in the browser (Nano Banana 2 or a similar image model),
for `docs/LOOK_PROTOTYPES_PLAN.md`. One block per asset: attach the file
named, paste the prompt, pick the best of 3–4 variants, and save it under
the name given in `proto/incoming/`. I process everything from there:
keying, grid snapping, palettes, seams, maps, import.

For everything:

* Attach the legacy file each time; the prompt says "keep the layout".
* Check the image's corners for a visible watermark.
* Note any prompt you changed in `proto/ASSET_LOG.md` (or tell me), so
  that it can be redone.

The game's files are under
`C:\Users\c06ks\Work\Children of the Zodiac\res\`.

## 1. The Boar, for 3D (first: the 3D pipeline takes the longest)

### 1.1 Turnaround

* Attach: `res\Battle\enemies\boar\boar1.png` (and `boar2.png`, which
  shows more of its body).
* Save as: `proto/incoming/boar/turnaround.png`, plus one image per view
  if the model gives them separately: `side.png`, `front.png`, `back.png`.

> A model turnaround sheet of exactly this boar (same bristly dark mane
> along the neck and back, curved yellowish tusks, brown hide, thin tail
> with a tuft at the end, yellow eyes): left side view, front view and back
> view side by side, full body, standing square on all four legs, head
> level, mouth closed, tail hanging. Plain mid-grey background, even studio
> lighting, no cast shadows, no ground plane. The same painted style.

If the views come out with different proportions, ask for the side view
alone first ("only the left side view, full body, centred"), then the front
and back views "matching this side view exactly".

### 1.2 Hugging Face: image to 3D

* Spaces to try: search Hugging Face Spaces for **Hunyuan3D** (its
  multi-view variant takes front, back and side images) and **TRELLIS**
  (one image).
* Input: the side view, or the three views for a multi-view model; with
  background removal on.
* Output: textured, exported as `.glb`. Save as
  `proto/incoming/boar/boar.glb`, and note which Space and settings you
  used.
* A free account's GPU quota may run out after a few tries. Save each
  attempt (`boar_hunyuan.glb`, `boar_trellis.glb`): I compare them.

## 2. HD textures, painted (`hd-painted`)

Square, 1024 or 2048 px. I make the normal, height and roughness maps.
Every prompt ends with the same tail; it is written out in 2.1 and shortened
to "(tail)" after that:

> … Painterly but detailed, with believable materials. Albedo only: flat,
> even, shadowless lighting, no highlights, no ambient occlusion, no light
> direction. Straight-on orthographic view, no perspective. Fill the image
> edge to edge: no border, no text, no logo.

### 2.1 Mine wall

* Attach: `res\Labyrinth\Walls\minecavewall.png`
* Save as: `proto/incoming/mine/minecavewall.png`

> Repaint the attached game texture as a high-detail, seamless, tileable
> square texture for a modern 3D game. Same design and layout: rough dark
> grey rock with pale mineral veins, framed by weathered reddish-brown
> wooden support beams with iron bolts: a beam along the top, a post at
> each side, two diagonal braces in the upper corners and a cross beam a
> quarter of the way down, in the same positions. Painterly but detailed,
> with believable materials. Albedo only: flat, even, shadowless lighting,
> no highlights, no ambient occlusion, no light direction. Straight-on
> orthographic view, no perspective. Fill the image edge to edge: no
> border, no text, no logo.

### 2.2 Mine floor

* Attach: `res\Labyrinth\Floors\minecavefloor.jpg`
* Save as: `proto/incoming/mine/minecavefloor.png`

> Repaint the attached game texture as a high-detail, seamless, tileable
> square texture for a modern 3D game: the floor of an old mine tunnel,
> seen from straight above: packed dark grey earth and gravel, small sharp
> rock fragments, a few flattened wooden splinters, a little coal dust.
> Same overall darkness as the input. (tail)

### 2.3 Mine roof

* Attach: `res\Labyrinth\Roofs\minecaveroof.jpg`
* Save as: `proto/incoming/mine/minecaveroof.png`

> Repaint the attached game texture as a high-detail, seamless, tileable
> square texture for a modern 3D game: the rough rock ceiling of a mine
> tunnel, seen from straight below, keeping the input's layout and colours.
> (tail)

### 2.4 Mine doors

* Attach: `res\Labyrinth\Walls\minecavedoor0.png`
* Save as: `proto/incoming/mine/minecavedoor0.png`

> Repaint the attached game texture in high detail for a modern 3D game,
> keeping its exact layout: the same timber frame of a mine tunnel wall
> (rough dark rock with pale veins between weathered wooden beams with iron
> bolts) with a narrow wooden door frame in the middle, its plank door
> standing open to the left, and a pitch black opening behind it. The
> black opening stays pure black. (tail)

* Attach: `res\Labyrinth\Walls\minecavedoorbig0.png`
* Save as: `proto/incoming/mine/minecavedoorbig0.png`

> Repaint the attached game texture in high detail for a modern 3D game,
> keeping its exact layout: a timber mine frame (a beam along the top, a
> post at each side, two diagonal braces in the upper corners, weathered
> reddish-brown wood with iron bolts) around a wide opening that stays pure
> black, with a little loose gravel along the bottom edge. (tail)

### 2.5 Forest wall

* Attach: `res\Labyrinth\Walls\forestwall.png`
* Save as: `proto/incoming/forest/forestwall.png`

> Repaint the attached game texture as a high-detail, seamless (left and
> right edges) square texture for a modern 3D game. Same design: a dry
> stone wall of rounded grey-green fieldstones with moss and lichen, an
> uneven top edge of stones against a flat pure magenta (#FF00FF) sky, and
> a strip of grass along the bottom. (tail)

### 2.6 Forest floor

* Attach: `res\Labyrinth\Floors\forestfloor.jpg`
* Save as: `proto/incoming/forest/forestfloor.png`

> Repaint the attached game texture as a high-detail, seamless, tileable
> square texture for a modern 3D game: a forest path's ground seen from
> straight above: short wet grass, patches of dark earth, fallen leaves and
> small pebbles. Same overall colour as the input. (tail)

### 2.7 Forest door

* Attach: `res\Labyrinth\Walls\forestdoor0.png`
* Save as: `proto/incoming/forest/forestdoor0.png`

> Repaint the attached game texture in high detail for a modern 3D game,
> keeping its exact layout: the same mossy dry stone wall with a ragged
> arched gap in the middle that stays pure black, its stones' top edge
> against a flat pure magenta (#FF00FF) sky, grass along the bottom.
> (tail)

## 3. Forest extras (HD)

### 3.1 Tree cards (3–5 requests, one tree or bush each)

* Attach: `res\Labyrinth\Walls\forestwall.png` (for the style)
* Save as: `proto/incoming/forest/tree1.png`, `tree2.png`, …

> One [tall, mossy oak trunk with its lowest branches / a dark fir tree /
> a dense bush of ferns], full height, front view, in the painted style of
> the attached texture, on a flat pure magenta (#FF00FF) background. No
> shadow, no glow, crisp edges.

### 3.2 Sky

Not needed: I take a CC0 HDRI from Poly Haven for `hd-photo`. For
`hd-painted`, if you like:

* Save as: `proto/incoming/forest/sky.png`

> A 2:1 equirectangular 360° panorama of an overcast, rainy dusk sky above
> a dark forest canopy, the horizon at the vertical centre, the left and
> right edges seamless, nothing below the horizon but dark treetops.
> Painted style, no text.

## 4. Pixel textures (2.2 b), if you want to compare them with PixelLab's

Run these on the same files as 2.1–2.7 (or on your results of 2.x) and
save them as `proto/incoming/pixel/<name>.png` (for example
`minecavewall.png`):

> Redraw the attached texture as 16-bit console era pixel art (SNES
> style): a 128×128 pixel image scaled up 8× with hard square pixels (every
> art pixel a solid 8×8 block), at most 32 colours, no anti-aliasing, no
> gradients, no blur, clear clusters and dark lines between the shapes.
> Same layout as the input, seamless and tileable, straight-on, edge to
> edge. [For the forest wall and door: the sky above the stones stays flat
> pure magenta (#FF00FF).]

## 5. Later: the Goblin, for 3D

* Attach: `res\Battle\enemies\goblin\goblin1.png`
* Save as: `proto/incoming/goblin/turnaround.png`

> A character turnaround sheet of exactly this goblin (same face, green
> skin, purple loincloth, studded shoulder plate, wrapped sandals): front
> view, left side view and back view side by side, full body, in a relaxed
> A-pose with the arms 30–45° from the body and the legs slightly apart, no
> weapons. Plain mid-grey background, even studio lighting, no cast
> shadows, the same painted style.

Then the spear and the curved knife, each alone on grey.
