# Converting overlays to UI nodes

Phase 3 of `docs/MODERNIZATION_PLAN.md` (shared UI and transitions). The
pilot converted, through step B, the dialog box, the message box, the card
info popup and the fade (plan 8.1); the rollout the emotion bubbles, the
mission display, "Paused" and "game pad lost", the cutscene images and
texts and the tutorials' top layer (plan 8.3; the minimap stays the 3D
bridge's batches, its node is a dev flag); the conventions
are in `docs/ARCHITECTURE.md` section 12. This is the procedure for the next
overlays (phase 4's: a battle's and a riddle's top layer, the stores'
menus; the world map's name plate is done, docs/ARCHITECTURE.md
section 13) and for whole 2D modes (section 5 below; the title, the game
over, the menu and the stores are done, docs/ARCHITECTURE.md section 14). Phase 3's
`--legacy=` flags that the examples below name (`dialog`, `fades`, the
rollout's overlays) are removed since the phase closed (plan 8.4): a new
part gets a flag of its own, which goes when its phase closes. Run everything from bash in the project root, Godot with
`< /dev/null`; close the Godot editor first (it imports new files and makes
`.uid` files), and do not type while a recording runs (a new run's window
takes the focus).

## 1. Facts first (on the code you start from)

* **Where it is drawn.** Find every call of the overlay's draw and what each
  mode draws before and after it in the same frame (`draw` of the mode, then
  `GameCore.testDraw`'s "Paused" and "game pad lost" after it). A node takes
  the overlay's slot in that order (section 12 of ARCHITECTURE); what the
  frame draws after it stays over it. A node of the UI layer must not come
  after one of Transition in a frame (the levels only rise: GLBackend warns).
* **What its drawing changes.** Grep the draw and everything it calls for
  state changes, and keep each in the twin, in the same order: the GL state
  (`setColor`, `glColor*`, `setAlphaFunc`, `setBlendFunc`, `loadIdentity`),
  the text state (`setFontSize`, `setTextColor`, `startText`/`finishText`),
  the bound texture (`drawImage` binds: `Graphics.skip_image`), drawString's
  `setColor(color)`, and the overlay's own state (counters, alphas or
  `isFinished()` stepped while drawing, like `Dialog._drawCurrent`'s image).
  The twin runs inside the mode's draw, where the drawing ran.
* **How its text is placed.** Positions are baselines (JOGL's TextRenderer);
  centred and right-aligned text use `Graphics.calcAlignCenter` /
  `calcAlignRight` (the advance width, `J.round` of half of it) and some code
  `getStringWidth` (JOGL's ink bounds); `drawString` draws at alpha 1,
  `drawMultiString` at `startText`'s alpha (the current mode's fade value
  unless given). Font: `setFontSize(size[, bold])`, even sizes 20 to 50; the
  bold font stays on until a call sets it back (`ScrollableTexts`, `Deck`).
* **What reads input in a draw.** `GameCore.testDraw` reads the "game pad
  lost" menu's buttons between its texts and its menu: a twin must keep that
  order (show the node before, hand it the menu after). Every mode reads the
  direction buttons and CROSS in its `update`, before `testDraw`, so such an
  overlay only sees a press the mode did not take (a labyrinth reads none
  while the player steps), and a cutscene takes START itself (it ends the
  story): plan the cases around it.
* **Coverage.** Which existing cases show the overlay, in which mode, and in
  which states? A probe copy of the project (a tar without `.git` and
  `tools/parity/out`, ~20 s) with temporary prints in the draws (`[cov]
  f=<Engine.get_process_frames()> <kind> <state>`) and in AutoPlay's `shot`
  (`[cov] f=<frame> shot <name>`), run headless over every case
  (`tools/parity/probe.sh <copy> <out dir> --jobs=4`, about 10 minutes alone,
  more beside a recording), gives per shot what it shows
  (`python -I tools/parity/probe_report.py <out dir> [kind]`): a shot taken
  in frame F shows what frame F - 1 drew (AutoPlay reads the viewport after
  the frame's drawing, before it is rendered). Print what decides the look
  (a zoom's scale, an alpha, the chunk a 3D drawing lands in, a slide's
  position), not only that it was drawn. Write cases for what no shot shows (plan the routes with `pos`
  in headless probe runs: the village player walks 200 px a second; a
  villager talks within 30 px, facing it, feet level; a sign within its
  radius, facing one of its directions; a loot within 35 px). A state that no
  route reaches in a seeded run gets a documented dev-only way, preferably a
  debug console command that AutoPlay's `console` runs (`padlost`,
  `emotion`; `kill` for a boss's end). Record the new cases twice on
  unconverted code: identical. Record them from a copy made from the
  committed code plus only the new scripts, `cases.txt` and the dev hooks,
  so the conversion can be written meanwhile.

## 2. The node

* A scene in `scenes/ui/` (Control root, script beside it, the root's
  `theme` = `resources/theme/game_theme.tres`, `mouse_filter` ignore on every
  node), its layout in legacy screen pixels: what the legacy code kept in
  position tables becomes node positions and exported values.
* Text: `BaselineLabel` (`scenes/ui/BaselineLabel.gd`) at the legacy baseline,
  with a theme type variation for its size (add a role to the theme, based on
  `BaselineLabel`, or use `Text20` … `Text50` where the size is data); `bold`
  and `color` from the legacy state. Keep `oversampling` at 1 for the legacy
  look at every window size. Centred or right-aligned text: its `alignment`
  (the node at the centre or the end; it rounds as `calcAlignCenter` and
  `calcAlignRight`). Positions the legacy measures with JOGL's ink bounds
  (`getStringWidth`) are computed in the twin. A varying number of lines:
  `LabelList` (`scenes/ui/LabelList.gd`).
* Images: TextureRect (`stretch_mode` keep) or, for a paper or menu piece, a
  Panel with a StyleBoxTexture of the theme (no margins, the panel the
  texture's size). The legacy colour of an image is its `self_modulate` (so
  children keep theirs); text takes the legacy text colour.
* The material: the root's `material` is `Graphics.canvas_material()` as the
  twin found it (the blending and alpha test of the 2D state), children
  `use_parent_material`.
* Methods named for what they show (`show_message`, `show_card`), typed,
  taking Godot values; no reference to a mode or legacy object.
* Under a transform (a cutscene's zoom scales the modelview): Godot's own
  transforms round a quad's corners differently from the legacy drawing,
  which transforms them on the CPU (`Graphics._emit2D`). Large images under
  the zoom came out the same with the modelview as a Node2D transform
  (`Graphics.modelview_2d`: `CutsceneImage`), the small emotion bubbles did
  not (up to 2/255 on a few pixels), neither under the village camera in
  `World`: they draw the legacy quad (`Graphics.screen_points`, then
  `canvas_item_add_triangle_array`), which is exact by construction. Text
  ignores the modelview (JOGL's TextRenderer).
* A Control is culled by its rect (its size from its position): a
  `BaselineLabel` (size 0 at its baseline) whose baseline is off the screen
  would vanish with glyphs still on it; it clears its custom rect, so it is
  culled by what it draws. Check a new node at the screen's edges.
* 3D in a 3D chunk (the minimap): the legacy drawing's geometry can be kept
  (`Graphics.begin_capture_3d` / `end_capture_3d`) and each batch drawn by a
  node through `Graphics.show_node`, in the chunk and the slot the batch had.
  The frame is then the same to the bit, but the 3D bridge's pool of
  instances no longer holds that drawing, and its instances render later
  batches (a battle's) 1/255 apart: compare the frames after the overlay too
  (plan 8.3). That was the floor's walls, reordered by Godot's sort: since
  they are drawn in a fixed order (phase 4.4's rollout) the minimap's node
  is identical on the battle cases.
* A 3D part as a node of its own in its chunk (the battle's enemy, phase
  4.4's rollout: `EnemyView`): the twin computes what the legacy vertices
  would have been (`Graphics.eye_points`: the corners through the
  modelview, eye space; `eye_normal`; the colour at the draw,
  `getCurrentColor`; the texture coordinates of the legacy quads) and the
  node draws them with the material of the render state there
  (`Graphics.material_3d`), as GL_QUADS' triangles. Probe the part's batch
  first: its chunk and index per frame, what merges into it (consecutive
  triangles of one material are one batch; a slot ends the batch before it),
  its render states (the alpha test the previous frame left is part of
  them), and what the first frame's `initDraw` adds before it. Key
  `show_node` by the legacy object's instance id: the node is kept from
  frame to frame and freed in a frame it is not shown. A slot takes no pool
  instance, so the batches after it move to other instances: compare the
  frames of every case that draws the part, not only its own shots.
  Since the floor's walls are drawn in a fixed order (ARCHITECTURE section
  10, `WALL_SORTING_STEP`), that moves nothing on the screen: a difference
  there is the node's. Before, it reordered the walls' tied surfaces (1/255
  on their overlaps, plan 9.4).


## 3. The twin and the flag

In the legacy draw method, behind `Main.is_legacy("<overlay>")`:

```gdscript
func drawThing(g):
	g.setFontSize(26)                     # state changes before the drawing stay
	if not Main.is_legacy("thing"):
		_show_thing(g)
		return
	...                                   # the legacy drawing, unchanged


## drawThing without the drawing: the same state changes, and the node.
func _show_thing(g) -> void:
	var tint: Color = g.getCurrentColor() # where the image was drawn
	var mat = g.canvas_material()
	g.skip_image(IMAGE)                    # drawImage's bind
	g.startText()
	var color: Color = Graphics.text_color(g.text_alpha())
	g.finishText()
	var view = g.show_ui(THING_VIEW, Graphics.UI_LAYER)
	if view != null:
		view.show_thing(..., color, tint, mat, Graphics.font_bold())
```

`show_ui` returns the frame's next node of that scene on that layer (pooled
per scene, layer and occurrence in the frame) in the slot of the frame's
order; call it once per drawing it replaces. Leave the modes' call sites as
they are. Add the flag to the table of ARCHITECTURE section 7. A drawing that
stands in for a legacy drawing of another overlay can reuse its node: the
pause's dim is `Graphics.show_fade(0.5)`. A twin keeps every state change of
the drawing, also those that are not drawing: counters and slides stepped
there (the emotions' shake, the mission's `Hideable.update`), timers and what
they trigger (the time mission's "Time's up!" leaves the floor), input
(above).

## 4. Parity

* `tools/check.sh` must report 0 failed.
* `tools/parity/parity.sh ab "--legacy=<overlay>" "" <cases that show it>`:
  identical at tolerance 0 (the pilot's nodes are exact; a difference is a
  missed state change, a wrong slot, or a different draw call).
* Golden vs. after on all other cases (`record after --jobs=5`, about 19
  minutes for 417 cases; more jobs only with enough free memory, plan 12):
  identical.
* With every flag of the phase on (`--legacy=dialog,fades,<overlay>`) the run
  equals the golden: the legacy paths did not change.
* Look at the shots that show the overlay (a contact sheet,
  `tools/parity/contact_sheet.gd`), legacy and node.
* Measure the frame rate in normal runs (no `--seed`), legacy vs. node, where
  the overlay is drawn for a while: AutoPlay's `fps=` with a `log` every
  0.5 s for 10 s, with `APPDATA` pointed at a scratch folder (the shipped
  saves only).
* Parity per overlay on code that has them all: the node run of every case
  once (`record after`), then `--legacy=<overlay>` on the overlay's cases,
  compared with it: the same pairs as `ab`, recorded once.

## 5. Whole 2D modes (phase 4.2: the title, the game over, the menu, the stores, the mini-games)

A mode whose whole frame is UI (no world under it) is converted the same
way, part by part; ARCHITECTURE section 14 has the conventions and the
reasons. What it adds to sections 1–4:

* **The place.** Every converted drawing is a UI node in the frame's order
  (`Graphics.show_ui`), not a scene of the mode under `World`: the stores
  and the menu pages draw legacy parts and phase 3's nodes (the keeper's
  dialog, the card info, the tutorials) between their own parts, and
  `World` is under all of it. Parts drawn one right after the other with
  nothing that could come between them may share a scene (the title's
  background and logo); a drawing that other modes repeat gets a reusable
  node (`MenuList`, `ShadowText`, `SlotDates`), shown where the legacy call
  was.
* **Facts.** Besides section 1: the mode's sub-states (which lists, pages,
  confirm boxes and dims each draws), the `MenuNode.draw` variant each list
  uses (prices, numbers, equipment, active children, the bounding box and
  its scroll bar, a dimmed hand; ARCHITECTURE section 14's table) and the
  game state its draws change (the cursor fix-up and its sound, the scroll
  bar's lazy init, `StatusPage`'s static `y`, the Church's `totalCost` and
  hand positions, `BUTTON_ICONS` loaded on first use). Check what is 3D
  before planning chunks: the stores, the menu pages and the riddles draw
  none (their cards are `drawImage`s).
* **Coverage.** Probe the mode's draw with its sub-state (the page, the
  store's mode, the riddle kind) and `MenuNode.draw` with its flags, the
  mode and the list's name: the phase 4.2 probe found the stores' cases
  showing only their root menus (plan 9.2). Seeded runs read no player saves
  and empty `user://saves_deterministic/`: a slot list shows "Empty", and a
  slot saved during the run is dated by the game clock (`SaveSlots.note_saved`,
  dev only), so slot lists can be shot. A shot shows the frame before it: the
  first frame of a game is shot at `wait 33`.
* **Flags.** One `--legacy=<part>` per converted part (`title`, `game_over`,
  `menu_list`), so that a part's legacy drawing can be checked against its
  node on its own; with all of a mode's flags on, the frame is drawn exactly
  as before. Parts whose pixels never overlap may change their relative
  order between flag combinations without a pixel changing; check which do.
  The flags go with the legacy drawing when the phase closes (phase 4.2's
  eleven: plan 9.2, "Closing phase 4.2").
* **Pooled nodes keep their textures.** A pooled node stays (hidden) after
  its mode is left, with the textures it was last given; release large
  ones when hidden if a mode's pages hold many.

What the menu added (phase 4.2's rollout; docs/ARCHITECTURE.md section 14,
"The menu"):

* **Switch at the call sites, not in shared code.** A helper that the next
  modes also call (`MenuNode.draw`, `StatusPage.drawTop`, `Deck.drawDeck`,
  `StartPage.drawInfo`, `drawMenuBackgroundStatic`) stays as it is; its twin
  is a new method beside it (`show_*`, `place_*`), and the converted mode's
  call sites choose with the flag, through small wrappers where many sites do
  the same (`AbstractPage.draw_list`, `draw_title`, `draw_help`,
  `StartPage.draw_screen_shot`, `draw_info`, `StatusPage.draw_top`). The
  stores keep the legacy calls until their part. When the phase closes, a
  wrapper that only chose between the two becomes a plain call of the twin
  at its call sites (`draw_list` → `MenuNode.show_children_freely`,
  `show_children`, `show_all_children`; `draw_top` → `show_top`), and one
  whose body was the twin keeps its name (`draw_title`, `draw_help`,
  `draw_screen_shot`, `draw_info`).
* **Images.** `Graphics.place_image(image, x, y[, scale])` is drawImage
  without the drawing: the bind and the quad's rect as `GameTexture.drawPart`
  rounds it (position rounded, far corner truncated), with the current
  colour; a TextureRect (`expand_mode` ignore size, `stretch_mode` scale) on
  that rect draws the same pixels, scaled too (the cards at 0.7 and 0.9, the
  scroll bars at 0.4). `ImageList` pools such rects; `place_centered_image`
  is drawCenteredImage's.
* **Under a modelview** (the automap's overview at a third): try the
  images' rects in their own space under a `Node2D` with the modelview as
  its transform (`Graphics.modelview_2d`, as `CutsceneImage`'s `Zoom`); the
  automap's small cells were exact that way. Where it is not (the emotion
  bubbles under a cutscene zoom: up to 2/255), draw the legacy quad
  (`Graphics.screen_points`, `canvas_item_add_triangle_array`). Text ignores
  the modelview.
* **A sequence of images and labels at computed places** (a help line) can
  run the legacy drawing itself against a stand-in for Graphics that passes
  the state calls on and records what would have been drawn
  (`HelpLineCapture`, as `DungeonQuads` for the dungeon's quads): no
  duplicated arithmetic, the state changes are the legacy code's. Use it for
  drawings that only place images and text; a part with a layout of its own
  (a status line, an item) is a scene with that layout, fed by a twin.
* **Order inside a node.** Keep the children in the legacy drawing order
  wherever two parts can overlap (an icon and its label, a change over its
  value, a floor's name under its cells): a node whose children's kinds vary
  keeps a child per entry (`HelpLine`); a list split by a nested list is
  several nodes (`MenuList` per part).
* **Coverage.** Lists that scroll need more entries than the shipped saves
  have: the dev console's `give` (key items, equipment). Headless probe runs
  have no thumbnail (`copyFrame` reads no viewport): the probe tells which
  mode the menu was opened from (`MenuStarter.checkMenu`), the windowed shots
  show the picture. Print the list's `bboffset`, the deck's lines and the
  flying cards' progress, not only that they were drawn.
* **Flags per kind of part** (`menu_frame`, `menu_list`, `menu_text`,
  `status`, `deck`, `automap`), not per page: the stores' parts are the same
  kinds and use the same flags.

What the stores added (phase 4.2's rollout; docs/ARCHITECTURE.md section 14,
"The stores"):

* **Reuse first.** A mode that draws what another mode's nodes already show
  needs call sites, not nodes: the stores' frame, lists, status, decks, info
  lines, help line and boxes are the menu's nodes fed with the store's state
  (`StartPage.show_info` takes any three lines, `AbstractPage.show_pieces`
  any placed images, `AbstractStore.show_box` any piece and texts). New
  nodes only where nothing covers a part: `LevelBar` (parts of images),
  `BlessPage`/`BlessRow` (a page of the Church's own).
* **A dim under later UI nodes** is the Fade node on the UI layer
  (`Graphics.show_fade(value, Graphics.UI_LAYER)`): the levels only rise in a
  frame, and the box and the list that follow a confirm dim are UI nodes.
  The riddles' backdrop and the battles' result screens can use the same.
* **Parts of images** (`drawImage` with a percent or a range:
  `GameTexture.drawPart`, `drawPartRange`): `Graphics.place_image_part`
  gives the quad and its texture coordinates; draw the legacy quad
  (`canvas_item_add_triangle_array` with the same corners, coordinates and
  colour, as `EmotionBubble`: `LevelBar`). A TextureRect with an
  AtlasTexture of the part's region was 1–5/255 off on the antialiased edges
  of the image (up to 17 on one pixel), though whole images drawn by
  TextureRects match the legacy quads to the bit.
* **A hand drawn twice in two colours** (the Church's markers) is two
  images of the hand (`MenuHand.place_hand_image`, `place_hand_with_color`)
  in an `ImageList`, each with the colour it was drawn in.
* **Game state in a draw.** The Church sums `totalCost` in its draw and
  places its markers there; the twin does both, in the same order, and
  CROSS on "Done" reads the sum. A list's cursor fix-up in the draw is
  reached when a refill leaves the cursor past the end (the Weapon Store
  selling the last entry of a list: plan 9.2).
* **Coverage.** Most store states need routes through the Cheater
  (`console cheater`, `tools/autoplay/stores.txt`) and dev-only state: the
  console's `gold` (unaffordable items and cards), `give card` (a merge page
  that scrolls), `--status=churchbless.tut:1` (a tutorial shown once), a
  store whose stock or blessing Slot 1 has not used up (Dellna's). The probe
  prints of the store's modes (`menuMode`, the Church's `blessMode` and
  `mode_`) tell which sub-page each shot shows; headless probe runs print
  exit leak reports that windowed runs do not, so take leak lines from the
  windowed parity logs only.

What the mini-games added (phase 4.2's rollout; docs/ARCHITECTURE.md section
14, "The riddles"):

* **An overlay of another mode with the same nodes.** A riddle is the
  labyrinth's top layer, not a mode of its own, but its parts are the kinds
  the menu and the stores already show: images (`show_pieces` with
  `place_image`), lines (`show_lines`), a dim (`show_fade` on the UI layer),
  a help line (`draw_help`). It needed call sites and two small line
  helpers, no scene.
* **Scaled images up are not exact as TextureRects.** The riddles' images
  at 1.12, 1.2 and 1.7 came out 1/255 apart on a few pixels (18/255 on one)
  as TextureRects of `place_image`'s rect, where the menu's cards scaled down
  (0.7, 0.9) and every 1:1 image match. Draw such an image as its legacy
  quad: `Graphics.place_image_part` with percent 1 and a `LevelBar` (its
  corners and texture coordinates as `GameTexture.drawPart` emits them).
* **Port bugs of number width.** The Java's `float` is 32-bit; a value
  stepped in a loop and compared (`fade += .1f` until `>= 1`) can take one
  step more in GDScript's 64-bit floats. Round each step to a 32-bit float
  where the Java's count of steps matters (`RiddleGame._toFloat`:
  `PackedFloat32Array([x])[0]`), as its own change with new goldens before
  the conversion.
* **Every frame of a fade.** A fade stepped per update shows its values only
  frame by frame: shots `wait 16` apart are one frame each (a run of up to
  about twenty; the remainder of 1000/60 adds up), and the probe's value per
  shot proves that every step is shot.
* **"Paused" does not stop a mode.** `GameCore` only draws the overlay (the
  Java too): under "Paused" and "game pad lost" the mode keeps updating and
  reading input (a riddle fades in, the pad lost menu's DOWN also moves a
  puzzle's cursor). Plan pause cases with that in mind.
* **State the mode inherits.** A top layer draws with whatever the frame
  left: the colour of the minimap's arrow, the alpha test of the floor's
  weather or save point (`setAlphaFunc(.1)`: the dim's first frames are
  dropped), the font size of earlier frames (Cesadur's text at 24). The
  nodes take `canvas_material()` and the sizes where the drawing was, so
  they inherit the same; the probe should print them.
* **Game state shown through the console.** A solved riddle sets its doors'
  statuses: the console's `trigger <name>` prints a Database status in the
  log before and after (`riddle_*_solved` cases), no dev hook needed.

What the closing of phase 4.2 added (plan 9.2, "Closing phase 4.2"):

* **Unreachable code keeps legacy helpers alive.** The status and bestiary
  pages (opened only from themselves) were the last callers of
  `StatusPage.drawTop`, `StartPage.drawInfo` and `MenuNode.drawAllChildren`;
  a survey of who calls a helper must ask whether the caller can run.
* **A dev mode is a caller too.** The developer Cheater drew its list
  through `MenuNode.draw`; it got a case with shots first (`cheater_menu`),
  then the twin (`MenuNode.show_children`), and the shots stayed identical.
* **A removed flag is ignored.** `Main.is_legacy` answers only for the names
  the code asks about: a run with a removed `--legacy=` name is a normal
  run. Check it with a few cases rather than assume it.

What the battle's top layer added (phase 4.4's pilot; docs/ARCHITECTURE.md
section 15, plan 9.4):

* **Another overlay with the same nodes.** A battle's 2D top layer is drawn
  where a riddle's is (after the labyrinth's dialog's slot; in a boss area of
  its own after its dialog), and its parts are kinds that exist: the dims
  and the flash are Fade nodes on UI, the scaled background a `LevelBar`
  quad, the lines `MenuText`, the cards `CardView`, the bars `LevelBar`
  parts, the icons `MenuBackground` pieces. Twins and two `Graphics` bridge
  members (`show_fade_colour_white`, `place_value_with_shadow`), no scene.
* **Lines over shadows in one node.** `drawWithShadow` and
  `drawValueWithShadow` are two lines each (the shadow 1 px down and to the
  right, then the line): `ResultScreenBase.shadow_lines` and `value_lines`
  give both entries for a `MenuText`, so a screen of 30 lines is one node.
  Split it where another part is drawn between its lines (the spoils
  screen's bars), so the order stays the legacy one.
* **Probe every frame, not only the shots.** A part can overlap another in
  frames no shot catches: the probe's lines per frame (a small script over
  the logs) found the legend's icons sliding out over the spoils screen in
  the frames after the console's `kill`, the tutorial over the icons, no
  flash during a screen. Shoot such frames on purpose.
* **Legacy that never draws.** `Clock.draw` has no caller (nor in the Java),
  no enemy's data has a drop, and the party's red screen
  (`Character3D.draw`) is a 2D image drawn under the 3D projection at z 0,
  behind the near plane: check that a drawing can show before planning its
  node or its case.
* **Dev state for screens a route cannot reach** (the console's `exp`: the
  last level of a class, a level up; `drop`: a dropped item) and a crit
  found with the probe (the seed fixes which cast lands a critical hit and
  when: the frames of the flash are shot one by one).
* **A screen's display can disagree with the game.** The spoils screen shows
  "Level up!" when the experience exactly fills the bar, though
  `calcSpoils` levels the character up only when it exceeds what is left (as
  in the Java): plan cases on the logic, not on what the screen says.
