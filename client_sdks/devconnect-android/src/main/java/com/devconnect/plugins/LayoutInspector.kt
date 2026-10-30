package com.devconnect.plugins

import android.app.Activity
import android.graphics.Bitmap
import android.graphics.Canvas
import android.util.Base64
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream

/**
 * The screen as the desktop's Layout tab shows it: a screenshot plus the
 * view tree, every view with its on-screen bounds and a few properties —
 * all in dp. Compose content shows as its host `ComposeView`.
 */
internal object LayoutInspector {
    /** Past this many views the tree is cut short. */
    private const val MAX_NODES = 3000

    /** Reads and draws views, so call it on the main thread. */
    fun capture(activity: Activity, screenshot: Boolean = true): JSONObject {
        val root = activity.window.decorView
        val density = activity.resources.displayMetrics.density
        val origin = IntArray(2).also { root.getLocationOnScreen(it) }
        var count = 0
        var truncated = false

        fun node(view: View): JSONObject? {
            if (view.visibility == View.GONE) return null
            if (count >= MAX_NODES) {
                truncated = true
                return null
            }
            count++
            val location = IntArray(2).also { view.getLocationOnScreen(it) }
            val margin = view.layoutParams as? ViewGroup.MarginLayoutParams
            val children = JSONArray()
            if (view is ViewGroup) {
                for (i in 0 until view.childCount) node(view.getChildAt(i))?.let(children::put)
            }
            return JSONObject()
                .put("id", System.identityHashCode(view).toString())
                .put("name", view.javaClass.simpleName.ifEmpty { view.javaClass.name })
                .put("x", (location[0] - origin[0]) / density)
                .put("y", (location[1] - origin[1]) / density)
                .put("w", view.width / density)
                .put("h", view.height / density)
                .putOpt("padding", insets(view.paddingLeft, view.paddingTop, view.paddingRight, view.paddingBottom, density))
                .putOpt("margin", margin?.run { insets(leftMargin, topMargin, rightMargin, bottomMargin, density) })
                .put("props", props(view))
                .put("children", children)
        }

        return JSONObject()
            .put("width", root.width / density)
            .put("height", root.height / density)
            .put("screenshot", if (screenshot) screenshotOf(root, density) else JSONObject.NULL)
            .put("root", node(root) ?: JSONObject.NULL)
            .apply { if (truncated) put("truncated", true) }
    }

    /** `[left, top, right, bottom]` in dp, or null when all zero. */
    private fun insets(left: Int, top: Int, right: Int, bottom: Int, density: Float): JSONArray? =
        if ((left or top or right or bottom) == 0) null
        else JSONArray(listOf(left, top, right, bottom).map { it / density.toDouble() })

    private fun props(view: View): JSONObject {
        val props = JSONObject()
        if (view.id != View.NO_ID) {
            runCatching { props.put("id", "@id/" + view.resources.getResourceEntryName(view.id)) }
        }
        if (view is TextView) props.put("text", view.text?.toString()?.take(200))
        view.contentDescription?.let { props.put("contentDescription", it.toString().take(200)) }
        if (view.visibility == View.INVISIBLE) props.put("visibility", "invisible")
        if (view.alpha < 1f) props.put("alpha", view.alpha.toDouble())
        if (!view.isEnabled) props.put("enabled", false)
        return props
    }

    /** [root] drawn at one pixel per dp, as base64 PNG; null if it can't be. */
    private fun screenshotOf(root: View, density: Float): Any = try {
        val bitmap = Bitmap.createBitmap(
            (root.width / density).toInt().coerceAtLeast(1),
            (root.height / density).toInt().coerceAtLeast(1),
            Bitmap.Config.ARGB_8888,
        )
        Canvas(bitmap).apply { scale(1 / density, 1 / density) }.also(root::draw)
        val png = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, png)
        bitmap.recycle()
        Base64.encodeToString(png.toByteArray(), Base64.NO_WRAP)
    } catch (_: Exception) {
        JSONObject.NULL
    }
}
