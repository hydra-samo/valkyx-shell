pragma Singleton
// HYDRA event bus — all reactive change moments.
// Only signals that have actual emitters and/or consumers.
import QtQuick

QtObject {
    // workspace
    signal workspaceChanged(string name)

    // windows
    signal windowFocused(string cls, string title)
    signal windowOpened(string cls)
    signal windowClosed(string cls)
    signal fullscreenChanged(bool on)

    // hardware
    signal volumeChanged(real pct)
    signal brightnessChanged(real pct)
    signal micMuteChanged(bool muted)
    signal batteryChanged(real pct, bool charging)

    // media
    signal mediaChanged(string title)

    // network
    signal wifiChanged(bool enabled)
    signal bluetoothChanged(bool enabled)
    signal networkConnected(string ssid)

    // notifications
    signal notificationReceived(string summary)
    signal notificationsCleared()

    // system
    signal contextChanged(string ctx)
    signal dndChanged(bool on)

    // shell ui
    signal osdShown(string mode, real value)
    signal osdHidden()
}
