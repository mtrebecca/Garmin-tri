import Toybox.Graphics;
import Toybox.Lang;

// Ícones desenhados com polígonos (sem bitmaps, para caber em qualquer tela e tamanho).
module Icons {

    const CARBS_COLOR = Graphics.COLOR_ORANGE;
    const WATER_COLOR = Graphics.COLOR_BLUE;

    // Raio: energia / carboidrato.
    function bolt(dc as Graphics.Dc, x, y, size) as Void {
        dc.setColor(CARBS_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [x + size * 0.15, y - size * 0.6],
            [x - size * 0.4, y + size * 0.1],
            [x - size * 0.02, y + size * 0.1],
            [x - size * 0.15, y + size * 0.6],
            [x + size * 0.4, y - size * 0.1],
            [x + size * 0.02, y - size * 0.1]
        ]);
    }

    // Gota: hidratação.
    function drop(dc as Graphics.Dc, x, y, size) as Void {
        dc.setColor(WATER_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y + size * 0.18, size * 0.38);
        dc.fillPolygon([
            [x, y - size * 0.6],
            [x - size * 0.36, y + size * 0.08],
            [x + size * 0.36, y + size * 0.08]
        ]);
    }

    // Ícone + texto centralizados como um bloco na posição (cx, y).
    function stat(dc as Graphics.Dc, cx, y, isWater as Boolean, text as String, font, textColor) as Void {
        var size = 16;
        var gap = 5;
        var width = size + gap + dc.getTextWidthInPixels(text, font);
        var left = cx - width / 2;
        if (isWater) {
            drop(dc, left + size / 2, y, size);
        } else {
            bolt(dc, left + size / 2, y, size);
        }
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(left + size + gap, y, font, text, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
