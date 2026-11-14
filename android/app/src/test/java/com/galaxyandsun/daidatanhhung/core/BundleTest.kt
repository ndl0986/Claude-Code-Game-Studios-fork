package com.galaxyandsun.daidatanhhung.core

import com.galaxyandsun.daidatanhhung.core.content.Validator
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.io.ByteArrayOutputStream
import java.util.zip.CRC32
import java.util.zip.Inflater

/**
 * story-screens AC14 (r8d) / content R10b: every assets.json picture is in the Android bundle (content/data is the
 * assets root, build.gradle.kts) and decodes at the size assets.json states; every story picture_id resolves.
 */
class BundleTest {
    private val content = TestContent.load()
    private val data = File(TestContent.root, "data")

    @Test fun everyAssetsJsonPictureIsBundledAndDecodes() {
        val pics = content.assets.assets.filter { it.kind == "picture" }
        assertTrue("assets.json lists pictures", pics.isNotEmpty())
        for (a in pics) {
            val f = File(data, a.file)
            assertTrue("${a.id}: ${a.file} bundled", f.isFile)
            assertEquals("${a.id}: bytes", a.bytes, f.length())
            val img = Png.decode(f.readBytes()); assertNotNull("${a.id}: decodes", img)
            a.width?.let { assertEquals("${a.id}: width", it, img!!.first) }
            a.height?.let { assertEquals("${a.id}: height", it, img!!.second) }
        }
    }

    @Test fun theTqtEndingStillIsBundledAndDecodes() {
        val id = content.heroes.getValue("tran-quoc-toan").mission.ending.pictureId
        assertEquals("pic.scene_tqt_ending", id)
        val a = content.assets.assets.first { it.id == id }
        assertEquals("ending still decodes at 640 × 360", 640 to 360, Png.decode(File(data, a.file).readBytes()))
    }

    @Test fun r10bFlagsAPictureWhoseFileIsMissing() {
        val ending = content.assets.assets.first { it.id == "pic.scene_tqt_ending" }
        val problems = Validator.picturesBundled(content.assets.assets) { it != ending.file && File(data, it).isFile }
        assertEquals(listOf("R10b picture pic.scene_tqt_ending: file ${ending.file} is not bundled"), problems)
        assertEquals("the real bundle has every file", emptyList<String>(), Validator.picturesBundled(content.assets.assets) { File(data, it).isFile })
    }

    @Test fun theFullValidatorRunsR10b() {
        val real = TestContent.load().copy(heroes = TestContent.load().heroes.filterKeys { it != "sample" })
        assertTrue(Validator.validate(real, checkPictures = true) { File(data, it).isFile }.none { it.startsWith("R10b") })
    }

    @Test fun storyPicturesAreCoverCroppedNeverStretched() {
        val whole = StoryLayout.coverCrop(640.0, 360.0, 1280.0, 720.0)
        assertEquals(StoryLayout.Box(0.0, 0.0, 640.0, 360.0), whole)
        val square = StoryLayout.coverCrop(400.0, 400.0, 1280.0, 720.0) // a square still: crop top and bottom
        assertEquals(400.0, square.width, 1e-9); assertEquals(225.0, square.bottom - square.top, 1e-9); assertEquals(200.0, square.cy, 1e-9)
        val tall = StoryLayout.coverCrop(1600.0, 720.0, 1280.0, 720.0) // wider than 16:9: crop the sides
        assertEquals(1280.0, tall.width, 1e-9); assertEquals(160.0, tall.left, 1e-9)
    }
}

/**
 * A strict PNG check for the JVM tests (android.jar has no ImageIO): signature, every chunk's CRC, IHDR, and the
 * IDAT stream inflating to exactly height × (1 + row bytes). Returns (width, height), or null if it doesn't decode.
 */
object Png {
    fun decode(b: ByteArray): Pair<Int, Int>? {
        val sig = byteArrayOf(-119, 80, 78, 71, 13, 10, 26, 10)
        if (b.size < 33 || !b.copyOfRange(0, 8).contentEquals(sig)) return null
        fun u32(i: Int) = ((b[i].toInt() and 0xFF) shl 24) or ((b[i + 1].toInt() and 0xFF) shl 16) or ((b[i + 2].toInt() and 0xFF) shl 8) or (b[i + 3].toInt() and 0xFF)
        var i = 8; var w = 0; var h = 0; var depth = 0; var colour = 0; var interlace = 0; var end = false
        val idat = ByteArrayOutputStream()
        while (i + 12 <= b.size && !end) {
            val len = u32(i); val type = String(b, i + 4, 4, Charsets.US_ASCII)
            if (len < 0 || i + 12 + len > b.size) return null
            val crc = CRC32().apply { update(b, i + 4, 4 + len) }.value.toInt()
            if (crc != u32(i + 8 + len)) return null
            when (type) {
                "IHDR" -> { w = u32(i + 8); h = u32(i + 12); depth = b[i + 16].toInt(); colour = b[i + 17].toInt(); interlace = b[i + 20].toInt() }
                "IDAT" -> idat.write(b, i + 8, len)
                "IEND" -> end = true
            }
            i += 12 + len
        }
        if (!end || w <= 0 || h <= 0 || interlace != 0) return null
        val channels = when (colour) { 0 -> 1; 2 -> 3; 3 -> 1; 4 -> 2; 6 -> 4; else -> return null }
        val rowBytes = (w * channels * depth + 7) / 8
        val expected = h.toLong() * (1 + rowBytes)
        val inf = Inflater().apply { setInput(idat.toByteArray()) }
        val buf = ByteArray(65536); var total = 0L
        while (!inf.finished()) { val n = inf.inflate(buf); if (n == 0 && (inf.needsInput() || inf.needsDictionary())) return null; total += n }
        inf.end()
        return if (total == expected) w to h else null
    }
}
