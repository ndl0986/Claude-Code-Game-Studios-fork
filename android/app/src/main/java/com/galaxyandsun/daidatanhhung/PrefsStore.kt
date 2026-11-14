package com.galaxyandsun.daidatanhhung

import android.content.Context
import com.galaxyandsun.daidatanhhung.core.Store

/** The device store: `lang`, best `stars.<hero>`, and the flags `completed.*`, `seen_open.*`, `medal.*` (D-16, D-07). */
class PrefsStore(context: Context) : Store {
    private val p = context.getSharedPreferences("game", Context.MODE_PRIVATE)
    override fun lang(): String? = p.getString("lang", null)
    override fun setLang(code: String) { p.edit().putString("lang", code).apply() }
    override fun stars(heroId: String) = p.getInt("stars.$heroId", 0)
    override fun setStars(heroId: String, stars: Int) { p.edit().putInt("stars.$heroId", stars).commit() }
    override fun flag(key: String) = p.getBoolean(key, false)
    override fun setFlag(key: String) { p.edit().putBoolean(key, true).commit() }
}
