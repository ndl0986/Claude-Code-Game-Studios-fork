package com.galaxyandsun.daidatanhhung.core

import com.galaxyandsun.daidatanhhung.core.content.AssetsFile
import com.galaxyandsun.daidatanhhung.core.content.ContentLoader
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** R11: a newer MINOR (a new optional field) is read at run time; strict decoding is for tests only. */
class SchemaMinorTest {
    private val json = """{"schema_version":"1.9","assets":[{"id":"pic.x","kind":"picture","file":"pictures/x.png","bytes":10,"width":8,"height":8,"new_field":true}]}"""

    @Test fun runtimeReadsANewerMinorWithUnknownFields() {
        val a = ContentLoader.LENIENT.decodeFromString(AssetsFile.serializer(), json)
        assertEquals(8, a.assets[0].width)
    }

    @Test fun testsStillCatchUnknownKeys() {
        val failed = runCatching { ContentLoader.JSON.decodeFromString(AssetsFile.serializer(), json) }.isFailure
        assertTrue(failed)
    }
}
