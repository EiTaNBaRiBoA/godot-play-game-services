package com.jacobibanez.plugin.android.godotplaygameservices.achievements

import android.util.Log
import androidx.core.app.ActivityCompat
import com.google.android.gms.games.AchievementsClient
import com.google.android.gms.games.PlayGames
import com.google.gson.Gson
import com.jacobibanez.plugin.android.godotplaygameservices.BuildConfig
import com.jacobibanez.plugin.android.godotplaygameservices.signals.AchievementsSignals.achievementUnlocked
import com.jacobibanez.plugin.android.godotplaygameservices.signals.AchievementsSignals.achievementsLoaded
import com.jacobibanez.plugin.android.godotplaygameservices.signals.AchievementsSignals.achievementRevealed
import org.godotengine.godot.Dictionary
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin.emitSignal

class AchievementsProxy(
    private val godot: Godot,
    private val achievementsClient: AchievementsClient = PlayGames.getAchievementsClient(godot.getActivity()!!)
) {

    private val tag: String = AchievementsProxy::class.java.simpleName

    private val showAchievementsRequestCode = 9001

    fun incrementAchievement(achievementId: String, amount: Int) {
        Log.d(tag, "Incrementing achievement with id $achievementId in an amount of $amount")
        achievementsClient.incrementImmediate(achievementId, amount).addOnCompleteListener { task ->
            if (task.isSuccessful) {
                Log.d(
                    tag,
                    "Achievement $achievementId incremented successfully. Unlocked? ${task.result}"
                )
                emitSignal(godot, BuildConfig.GODOT_PLUGIN_NAME, achievementUnlocked, task.result)
            } else {
                Log.e(
                    tag,
                    "Achievement $achievementId not incremented. Cause: ${task.exception}",
                    task.exception
                )
                emitSignal(godot, BuildConfig.GODOT_PLUGIN_NAME, achievementUnlocked, false)
            }
        }
    }

    fun loadAchievements(forceReload: Boolean) {
        Log.d(tag, "Loading achievements")
        achievementsClient.load(forceReload).addOnCompleteListener { task ->
            if (task.isSuccessful) {
                Log.d(
                    tag,
                    "Achievements loaded successfully. Achievements are stale? ${task.result.isStale}"
                )
                val achievementsCount = task.result.get()!!.count
                val achievements: List<Dictionary> =
                    if (task.result.get() != null && achievementsCount > 0) {
                        task.result.get()!!.map { fromAchievement(it) }.toList()
                    } else {
                        emptyList()
                    }

                emitSignal(godot, BuildConfig.GODOT_PLUGIN_NAME, achievementsLoaded, Gson().toJson(achievements))
            } else {
                Log.e(tag, "Failed to load achievements. Cause: ${task.exception}", task.exception)
                val emptyResponse: List<Dictionary> = listOf(Dictionary())
                emitSignal(godot, BuildConfig.GODOT_PLUGIN_NAME, achievementsLoaded, Gson().toJson(emptyResponse))
            }
        }
    }

    fun revealAchievement(achievementId: String) {
        Log.d(tag, "Revealing achievement with id $achievementId")
        achievementsClient.revealImmediate(achievementId).addOnCompleteListener { task ->
            if (task.isSuccessful) {
                Log.d(tag, "Achievement $achievementId revealed")
                emitSignal(godot, BuildConfig.GODOT_PLUGIN_NAME, achievementRevealed, true)
            } else {
                Log.e(
                    tag,
                    "Achievement $achievementId not revealed. Cause: ${task.exception}",
                    task.exception
                )
                emitSignal(godot, BuildConfig.GODOT_PLUGIN_NAME, achievementRevealed, false)
            }
        }
    }

    fun showAchievements() {
        Log.d(tag, "Showing achievements")
        achievementsClient.achievementsIntent.addOnSuccessListener { intent ->
            ActivityCompat.startActivityForResult(
                godot.getActivity()!!, intent,
                showAchievementsRequestCode, null
            )
        }
    }

    fun unlockAchievement(achievementId: String) {
        Log.d(tag, "Unlocking achievement with id $achievementId")
        achievementsClient.unlockImmediate(achievementId).addOnCompleteListener { task ->
            if (task.isSuccessful) {
                Log.d(tag, "Achievement with id $achievementId unlocked")
                emitSignal(godot, BuildConfig.GODOT_PLUGIN_NAME, achievementUnlocked, true)
            } else {
                Log.e(
                    tag,
                    "Error unlocking achievement $achievementId. Cause: ${task.exception}",
                    task.exception
                )
                emitSignal(godot, BuildConfig.GODOT_PLUGIN_NAME, achievementUnlocked, false)
            }
        }
    }
}