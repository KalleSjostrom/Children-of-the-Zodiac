# Converting overlays to UI nodes

Phase 3 of `docs/MODERNIZATION_PLAN.md` (shared UI and transitions). The
pilot converted, through step B, the dialog box, the message box, the card
info popup and the fade (plan 8.1); the rollout the emotion bubbles, the
mission display, "Paused" and "game pad lost", the cutscene images and
texts and the tutorials' top layer (plan 8.3; the minimap stays the 3D
bridge's batches, its node is a dev flag); the conventions
are in `docs/ARCHITECTURE.md` section 12. This is the procedure for the next
overlays (phase 4's: a battle's and a riddle's top layer, the menu pages,
the stores' menus, the world map's). Run everything from bash in the project root, Godot with
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
  (plan 8.3).

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
* Golden vs. after on all other cases (`record after --jobs=8`, about 15
  minutes for 380 cases): identical.
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
