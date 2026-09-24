import QtQuick
import qs.config

// Grafico a linea riempito (storico CPU/RAM ecc.). values: array 0..1
Canvas {
    id: root

    property var values: []
    property int points: 60
    property color color: Theme.primary

    onValuesChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const n = values.length;
        if (n < 2)
            return;
        const stepX = width / (points - 1);
        const offset = (points - n) * stepX;
        const y = v => height - Math.max(0, Math.min(1, v)) * (height - 2) - 1;

        ctx.beginPath();
        ctx.moveTo(offset, height);
        for (let i = 0; i < n; i++)
            ctx.lineTo(offset + i * stepX, y(values[i]));
        ctx.lineTo(offset + (n - 1) * stepX, height);
        ctx.closePath();
        const grad = ctx.createLinearGradient(0, 0, 0, height);
        grad.addColorStop(0, Theme.alpha(color, 0.35));
        grad.addColorStop(1, Theme.alpha(color, 0.02));
        ctx.fillStyle = grad;
        ctx.fill();

        ctx.beginPath();
        for (let i = 0; i < n; i++) {
            if (i === 0)
                ctx.moveTo(offset, y(values[0]));
            else
                ctx.lineTo(offset + i * stepX, y(values[i]));
        }
        ctx.strokeStyle = color;
        ctx.lineWidth = 1.6;
        ctx.stroke();
    }
}
