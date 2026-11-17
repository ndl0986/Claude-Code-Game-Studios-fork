package com.galaxyandsun.daidatanhhung

import android.app.Activity
import android.graphics.Paint
import android.graphics.Typeface
import android.os.Bundle
import android.util.Log
import java.io.File

/**
 * Debug only (TASK-005h, R8c): writes Nunito's advance width of every character the content can use,
 * at the weights the apps render, in font units (textSize 1000), to files/nunito-advances.json.
 * Pull it with `adb exec-out run-as com.galaxyandsun.daidatanhhung cat files/nunito-advances.json`.
 */
class FontMetricsActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val chars = buildList {
            for (c in 0x20..0x7E) add(c)
            for (c in 0xA0..0x24F) add(c)
            for (c in 0x300..0x323) add(c)
            for (c in 0x1EA0..0x1EF9) add(c)
            addAll(listOf(0x2013, 0x2014, 0x2018, 0x2019, 0x201C, 0x201D, 0x2026, 0x27E8, 0x27E9, 0x2192, 0x2605))
        }
        val sb = StringBuilder("{\n  \"units_per_em\": 1000,\n  \"source\": \"Android Paint.getTextWidths, content/data/fonts/nunito.ttf, textSize 1000\",\n  \"weights\": {")
        listOf(800, 600).forEachIndexed { wi, w ->
            val p = Paint().apply { typeface = Typeface.Builder(assets, "fonts/nunito.ttf").setFontVariationSettings("'wght' $w").build(); textSize = 1000f }
            if (wi > 0) sb.append(",")
            sb.append("\n    \"$w\": {")
            chars.forEachIndexed { i, c ->
                val s = String(Character.toChars(c)); val out = FloatArray(s.length); p.getTextWidths(s, out)
                if (i > 0) sb.append(",")
                sb.append("\n      \"").append(String.format("%04X", c)).append("\": ").append(Math.round(out[0]))
            }
            sb.append("\n    }")
        }
        sb.append("\n  }\n}\n")
        File(filesDir, "nunito-advances.json").writeText(sb.toString())
        Log.i("FontMetrics", "done ${chars.size} chars")
        finish()
    }
}
