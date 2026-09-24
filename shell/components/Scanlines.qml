import QtQuick
import qs.config

// Effetto CRT leggerissimo (righe orizzontali), disattivabile dalle impostazioni.
Canvas {
    id: root

    property real strength: 0.035

    visible: Settings.scanlineEffect
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, strength);
        for (let y = 0; y < height; y += 3)
            ctx.fillRect(0, y, width, 1);
    }
}
