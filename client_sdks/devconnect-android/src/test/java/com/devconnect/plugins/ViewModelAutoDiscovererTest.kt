package com.devconnect.plugins

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelStore
import androidx.lifecycle.ViewModelStoreOwner
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import org.junit.After
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class ViewModelAutoDiscovererTest {

    /**
     * Seeds a [ViewModel] directly into the [ViewModelStore.map] field.
     * The field name changed from `mMap` (≤ 2.6) to `map` in 2.7.0.
     * ViewModelStore.put(String, ViewModel) is also `public final` in
     * 2.7.0, but going through the field keeps the test honest about
     * what the production code actually reads.
     */
    private fun seedStore(vm: ViewModel): ViewModelStore {
        val store = ViewModelStore()
        val mapField = ViewModelStore::class.java.getDeclaredField("map").apply { isAccessible = true }
        @Suppress("UNCHECKED_CAST")
        val map = mapField.get(store) as HashMap<String, ViewModel>
        map["test_vm"] = vm
        return store
    }

    class FakeVmStore(private val vm: ViewModel) : ViewModelStoreOwner {
        override val viewModelStore: ViewModelStore = ViewModelStore().also { store ->
            // Use reflection to seed a VM — ViewModelStore.put is public
            // but its constructor expects a key, and put(String, ViewModel)
            // is internal in androidx.lifecycle. Easier: just call the
            // exposed API through reflection in the test.
            val putMethod = ViewModelStore::class.java.getDeclaredMethod("put", String::class.java, ViewModel::class.java)
            putMethod.isAccessible = true
            putMethod.invoke(store, "test_vm", vm)
        }
    }

    class FlowVm : ViewModel() {
        val counter: MutableStateFlow<Int> = MutableStateFlow(0)
    }

    class LiveDataVm : ViewModel() {
        val name: MutableLiveData<String> = MutableLiveData("init")
    }

    @Before
    fun setup() {
        ViewModelAutoDiscoverer.stop()
    }

    @After
    fun teardown() {
        ViewModelAutoDiscoverer.stop()
    }

    @Test
    fun `discover finds StateFlow properties on a ViewModel`() {
        val store = seedStore(FlowVm())
        val found = ViewModelAutoDiscoverer.discoverViewModel(store, "FlowVm")
        assertTrue("expected StateFlow to be discovered, got=$found", found.any { it.first == "counter" && it.second == "StateFlow" })
    }

    @Test
    fun `discover finds LiveData properties on a ViewModel`() {
        val store = seedStore(LiveDataVm())
        val found = ViewModelAutoDiscoverer.discoverViewModel(store, "LiveDataVm")
        assertTrue("expected LiveData to be discovered, got=$found", found.any { it.first == "name" && it.second == "LiveData" })
    }

    @Test
    fun `start and stop are idempotent`() {
        ViewModelAutoDiscoverer.start()
        ViewModelAutoDiscoverer.start()
        Thread.sleep(200)
        ViewModelAutoDiscoverer.stop()
        ViewModelAutoDiscoverer.stop()
        // No assertion needed — just verify no exception.
    }
}
