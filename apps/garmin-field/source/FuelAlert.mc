import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Alerta exibido por cima da tela da atividade; o sistema fecha sozinho.
class FuelAlert extends WatchUi.DataFieldAlert {
    private var _item;
    private var _withLap;

    function initialize(item, withLap) {
        DataFieldAlert.initialize();
        _item = item;
        _withLap = withLap;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_ORANGE);
        dc.clear();
        var cx = dc.getWidth() / 2;
        var h = dc.getHeight();
        var center = Graphics.TEXT_JUSTIFY_CENTER;

        dc.drawText(cx, h * 0.15, Graphics.FONT_XTINY, "HORA DE CONSUMIR", center);
        dc.drawText(cx, h * 0.32, Graphics.FONT_MEDIUM, _item["p"], center);
        dc.drawText(cx, h * 0.52, Graphics.FONT_SMALL, Format.itemDetails(_item), center);
        if (_withLap) {
            dc.drawText(cx, h * 0.72, Graphics.FONT_XTINY, "LAP  consumi", center);
        }
    }
}
