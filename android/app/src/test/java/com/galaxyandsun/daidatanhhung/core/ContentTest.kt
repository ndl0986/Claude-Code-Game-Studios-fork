package com.galaxyandsun.daidatanhhung.core

import com.galaxyandsun.daidatanhhung.core.content.Validator
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/** The bundled content itself: it parses strictly and passes R2, R4–R11. */
class ContentTest {
    private val content = TestContent.load()

    @Test fun dataAndSamplePassValidation() {
        // Sample pictures are drawn in code in debug builds (parity item 5), so R10 is checked on data/ only.
        assertEquals(emptyList<String>(), Validator.validate(content, checkPictures = false))
    }

    @Test fun realHeroesResolveEveryPicture() {
        val real = content.copy(heroes = content.heroes.filterKeys { it in content.index.heroes })
        assertEquals(emptyList<String>(), Validator.validate(real, checkPictures = true))
    }

    @Test fun everyTuningKeyTheAppReadsExists() {
        val missing = Tuning.Keys.ALL.filterNot { it in content.tuning.values }
        assertEquals(emptyList<String>(), missing)
        for ((k, v) in content.tuning.values) assertTrue(k, v.value in v.min..v.max)
    }

    @Test fun assetsExistWithTheirSize() {
        for (a in content.assets.assets) {
            val f = File(TestContent.root, "data/${a.file}")
            assertTrue("${a.id}: ${a.file} missing", f.isFile)
            assertEquals(a.id, a.bytes, f.length())
        }
    }

    @Test fun everyUiStringTheAppUsesExists() {
        val ids = content.strings.strings.map { it.id }.toSet()
        assertEquals(emptyList<String>(), UiIds.ALL.filterNot { it in ids })
    }

    @Test fun sampleIsDebugOnlyAndPending() {
        // The sample hero never ships: it is not in data/index.json, and its claims are pending.
        assertTrue("sample" !in content.index.heroes)
        val gate = ClaimGate.evaluate(content.heroes.getValue("sample").claims.claims.associate { it.id to it.signoff.status },
            Validator.texts(content.heroes.getValue("sample")).map { it.second.claims })
        assertTrue(!gate.releaseBuildPasses)
    }
}
