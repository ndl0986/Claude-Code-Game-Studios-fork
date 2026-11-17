package com.galaxyandsun.daidatanhhung

import android.app.Application

/**
 * Starts audio before anything can be tapped (browser QC lesson O8): the sounds are made and
 * loaded here, and the title's Start button stays disabled until [Audio.ready].
 */
class GameApp : Application() {
    lateinit var audio: Audio; private set

    override fun onCreate() {
        super.onCreate()
        audio = Audio(this)
    }
}
