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
    val root: File = (System.getenv("CONTENT_ROOT")?.let { listOf(File(it)) } ?: emptyList()).plus(listOf(File("../../content"), File("../content"), File("content"))).first { File(it, "data").isDirectory }

    private fun read(path: String): String? =
        listOf(File(root, "data/$path"), File(root, "samples/$path")).firstOrNull { it.isFile }?.readText()

    fun load(): Content = ContentLoader(::read).load(extraHeroes = listOf("sample"))

    fun fixture(name: String): JsonObject = Json.parseToJsonElement(File(root, "fixtures/$name").readText()).jsonObject

    fun game(store: Store = MemoryStore(), sfx: MutableList<Sfx> = mutableListOf()): Game =
        Game(load(), "sample", store) { sfx += it }

    /**
     * The full 4-type Trần Quốc Toản mission (D-08 B): data/ once TASK-011 lands, else the draft
     * content/drafts/heroes/tran-quoc-toan/mission-full.json.
     */
    fun fullContent(): Content {
        val c = load()
        val hero = c.heroes.getValue("tran-quoc-toan")
        if (hero.mission.beats.any { it.type != "fight" }) return c
        val draft = File(root, "drafts/heroes/tran-quoc-toan/mission-full.json")
        val m = ContentLoader.JSON.decodeFromString<com.galaxyandsun.daidatanhhung.core.content.MissionFile>(draft.readText())
        return c.copy(heroes = c.heroes + ("tran-quoc-toan" to hero.copy(mission = m)))
    }

    fun fullGame(store: Store = MemoryStore(), sfx: MutableList<Sfx> = mutableListOf()): Game =
        Game(fullContent(), "tran-quoc-toan", store) { sfx += it }
}
