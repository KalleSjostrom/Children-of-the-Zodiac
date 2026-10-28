# Converting overlays to UI nodes

Phase 3 of `docs/MODERNIZATION_PLAN.md` (shared UI and transitions). The
pilot converted, through step B, the dialog box, the message box, the card
info popup and the fade (plan 8.1); the conventions are in
`docs/ARCHITECTURE.md` section 12. This is the procedure for the next
overlays (plan 8.2 lists them, with their place in each mode's frame and what
blocks each). Run everything from bash in the project root, Godot with
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
* **Coverage.** Which existing cases show the overlay, in which mode, and in
  which states? A probe copy of the project (a tar without `.git` and
  `tools/parity/out`, ~20 s) with temporary prints in the draws (`[cov]
  f=<Engine.get_process_frames()> <mode> <state>`) and in AutoPlay's `shot`
  (`[cov] f=<frame> shot <name>`), run headless over every case, gives per
  shot what it shows: a shot taken in frame F shows what frame F - 1 drew
  (AutoPlay reads the viewport after the frame's drawing, before it is
  rendered). Write cases for what no shot shows (plan the routes with `pos`
  in headless probe runs: the village player walks 200 px a second; a
  villager talks within 30 px, facing it, feet level; a sign within its
  radius, facing one of its directions; a loot within 35 px). Record the new
  cases twice on unconverted code: identical.

## 2. The node

* A scene in `scenes/ui/` (Control root, script beside it, the root's
  `theme` = `resources/theme/game_theme.tres`, `mouse_filter` ignore on every
  node), its layout in legacy screen pixels: what the legacy code kept in
  position tables becomes node positions and exported values.
* Text: `BaselineLabel` (`scenes/ui/BaselineLabel.gd`) at the legacy baseline,
  with a theme type variation for its size (add one to the theme, based on
  `BaselineLabel`, or use `Text20` … `Text50`); `bold` and `color` from the
  legacy state. Keep `oversampling` at 1 for the legacy look at every window
  size. Centred or right-aligned text: compute the x as the legacy does (the
  node's position, from `Font.get_string_size` and the legacy rounding).
* Images: TextureRect (`stretch_mode` keep) or, for a paper or menu piece, a
  Panel with a StyleBoxTexture of the theme (no margins, the panel the
  texture's size). The legacy colour of an image is its `self_modulate` (so
  children keep theirs); text takes the legacy text colour.
* The material: the root's `material` is `Graphics.canvas_material()` as the
  twin found it (the blending and alpha test of the 2D state), children
  `use_parent_material`.
* Methods named for what they show (`show_message`, `show_card`), typed,
  taking Godot values; no reference to a mode or legacy object.

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

`show_ui` returns the frame's next node of that scene (pooled per occurrence
in the frame) in the slot of the frame's order; call it once per drawing it
replaces. Leave the modes' call sites as they are. Add the flag to the table
of ARCHITECTURE section 7.

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
  the overlay is drawn for a while.
