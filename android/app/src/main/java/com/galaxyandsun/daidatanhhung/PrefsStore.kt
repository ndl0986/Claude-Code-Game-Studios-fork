package com.galaxyandsun.daidatanhhung

import android.content.Context
import com.galaxyandsun.daidatanhhung.core.Store

/** The device store: only `lang`, `stars.<hero_id>` (best) and `unlocked` (parity item 3). */
class PrefsStore(context: Context) : Store {
    private val p = context.getSharedPreferences("game", Context.MODE_PRIVATE)
    override fun lang(): String? = p.getString("lang", null)
    override fun setLang(code: String) { p.edit().putString("lang", code).apply() }
    override fun stars(heroId: String) = p.getInt("stars.$heroId", 0)
    override fun setStars(heroId: String, stars: Int) { p.edit().putInt("stars.$heroId", stars).apply() }
    override fun unlocked(): Set<String> = p.getStringSet("unlocked", emptySet()) ?: emptySet()
    override fun unlock(heroId: String) { p.edit().putStringSet("unlocked", unlocked() + heroId).apply() }
}
