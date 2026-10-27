Several village variants have no obstacle (`o`) lines, so the player walks through buildings, trees and furniture there.

**Priority:** Medium (triage V5). The Java original has the same data.

**Where** (`.vil` files with no `o` line, checked 2026-10-23):

* A sibling with the same background has obstacles: Alares - 1 (Alares - 0), Dellna - 2 (Dellna - 0/1), Parasne - 2 (Parasne - 1; its background is `Parasne--1`).
* Night variants whose day variant has obstacles: Alares - Celis at Night, Crossroad at Night, Pensara - The Trade District at Night, Port of Alares at Night.
* No variant to copy from: Kin's Place, Zazo - Farl's House.
* Probably meant to be empty (cutscene stages, memories, unreachable): Dellna - Ana's Home Memory, Home of Celis - Memory, The Senate, The Ship Cabin - Story, No Place (and at Night), Zazo - Teo (and at Night).

**Fix idea:** copy the obstacles of the variant with the same background; draw new ones for Kin's Place and Farl's House. Check which of the last group the player can walk in. Mirror each change in the village's `.tscn` (docs/CONVERTING_VILLAGES.md).
