package com.galaxyandsun.daidatanhhung.core

import com.galaxyandsun.daidatanhhung.core.content.Content

/**
 * Which heroes are open (D-16, Hero progression GDD): the first playable hero in timeline order,
 * any hero whose previous playable hero is completed, and any hero ever seen open (never re-locks).
 * Playable = bundled in this build (the claim gate already removed unsigned heroes in release).
 */
object Progression {
    fun playable(content: Content): List<String> =
        content.heroes.values.sortedBy { it.mission.hero.timelineOrder }.map { it.mission.hero.id }

    fun openHeroes(content: Content, store: Store): Set<String> {
        val list = playable(content)
        val open = mutableSetOf<String>()
        list.forEachIndexed { i, id ->
            if (i == 0 || store.flag("completed.${list[i - 1]}") || store.flag("seen_open.$id")) open += id
        }
        return open
    }
}
