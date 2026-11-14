package com.galaxyandsun.daidatanhhung.core

import com.galaxyandsun.daidatanhhung.core.content.Content
import com.galaxyandsun.daidatanhhung.core.content.ContentLoader
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import java.io.File

/** Reads the repo's content/ folder: data/ plus samples/ (the debug build's hero). */
object TestContent {
    /** Unit tests run with the module dir (android/app) as working dir. */
    val root: File = listOf(File("../../content"), File("../content"), File("content")).first { File(it, "data").isDirectory }

    private fun read(path: String): String? =
        listOf(File(root, "data/$path"), File(root, "samples/$path")).firstOrNull { it.isFile }?.readText()

    fun load(): Content = ContentLoader(::read).load(extraHeroes = listOf("sample"))

    fun fixture(name: String): JsonObject = Json.parseToJsonElement(File(root, "fixtures/$name").readText()).jsonObject

    fun game(store: Store = MemoryStore(), sfx: MutableList<Sfx> = mutableListOf()): Game =
        Game(load(), "sample", store) { sfx += it }
}
