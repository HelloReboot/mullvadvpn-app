package net.mullvad.mullvadvpn.model

import android.os.Parcelable
import kotlinx.parcelize.Parcelize

sealed class DeviceState : Parcelable {
    @Parcelize
    object UnknownDeviceState : DeviceState()

    @Parcelize
    data class DeviceRegistered(val deviceConfig: DeviceConfig) : DeviceState()

    @Parcelize
    object DeviceNotRegistered : DeviceState()

    fun isUnknown(): Boolean {
        return this is UnknownDeviceState
    }

    fun deviceName(): String? {
        return (this as? DeviceRegistered)?.deviceConfig?.device?.name
    }

    fun token(): String? {
        return (this as? DeviceRegistered)?.deviceConfig?.token
    }

    companion object {
        fun fromDeviceConfig(deviceConfig: DeviceConfig?): DeviceState {
            return deviceConfig?.let { DeviceRegistered(it) } ?: DeviceNotRegistered
        }
    }
}
