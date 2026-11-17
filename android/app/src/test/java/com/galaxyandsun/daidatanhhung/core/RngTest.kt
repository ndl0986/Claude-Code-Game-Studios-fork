package com.galaxyandsun.daidatanhhung.core

import org.junit.Assert.assertEquals
import org.junit.Test
import java.io.File
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

class RngTest {
    /** The browser prototype's rng() with seed 1 (node, index.html @203d73e), first 5 values. */
    @Test fun matchesThePrototypeBitForBit() {
        val r = Mulberry32(1)
        val expected = listOf(0.6270739405881613, 0.002735721180215478, 0.5274470399599522, 0.9810509674716741, 0.9683778982143849)
        for (e in expected) assertEquals(e, r.next(), 0.0)
    }

    /** content/fixtures/rng.json (game-dev-ios adds it): seed → first N outputs. */
    @Test fun matchesTheSharedFixtureWhenPresent() {
        val f = File(TestContent.root, "fixtures/rng.json")
        if (!f.isFile) { println("fixtures/rng.json not present yet"); return }
        for (c in TestContent.fixture("rng.json")["cases"]!!.jsonArray.map { it.jsonObject }) {
            val r = Mulberry32(c["seed"]!!.jsonPrimitive.content.toLong())
            for (e in c["first"]!!.jsonArray) assertEquals(c.toString(), e.jsonPrimitive.content.toDouble(), r.next(), 0.0)
        }
    }

    @Test fun sameSeedSameSequence() {
        val a = Mulberry32(42); val b = Mulberry32(42)
        repeat(100) { assertEquals(a.next(), b.next(), 0.0) }
    }
}
