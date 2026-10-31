extends Control
## A deck of cards (phase 4.2 step B, docs/ARCHITECTURE.md section 14), as
## Deck.drawDeck draws it: the shown lines of cards (CardView each, in the
## deck's order; the current card last, larger), then the deck's hand (when
## the deck is active). The legacy Deck stays in charge of the cards, the
## cursor and the lines shown; each frame its twin (Deck.show_deck) hands this
## node what it would have drawn (Graphics.show_ui). The deck page shows the
## character's deck and the party's (the passive one at alpha .5 while
## editing); the card store its stock later.

const CARD_VIEW := preload("res://scenes/ui/CardView.tscn")

@onready var _cards: Control = $Cards
@onready var _hand: TextureRect = $Hand


## cards: {"images", "index"} each (Deck.place_deck's), in drawing order;
## hand: [texture, position, tint] ([]: none). mat is the material of the
## legacy drawing (Graphics.canvas_material).
func show_deck(cards: Array, hand: Array, mat: Material) -> void:
	material = mat
	var views := _cards.get_children()
	for i in cards.size():
		var view: Control
		if i < views.size():
			view = views[i]
		else:
			view = CARD_VIEW.instantiate()
			view.use_parent_material = true
			_cards.add_child(view)
		view.visible = true
		view.show_card(cards[i].images, cards[i].index, null)
	for i in range(cards.size(), views.size()):
		views[i].visible = false
	_hand.visible = not hand.is_empty() and hand[0] != null
	if _hand.visible:
		_hand.texture = hand[0]
		_hand.position = Vector2(hand[1])
		_hand.self_modulate = hand[2]
