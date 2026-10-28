import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Alerta exibido por cima da tela da atividade; o sistema fecha sozinho.
// O título diz o que fazer: comer (carboidrato ou sal), beber, ou os dois.
class FuelAlert extends WatchUi.DataFieldAlert {
    private var _item;
    private var _withLap;

    function initialize(item, withLap) {
        DataFieldAlert.initialize();
        _item = item;
        _withLap = withLap;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        var eats = _item["c"] > 0 || (_item["na"] > 0 && _item["ml"] == 0);
        var drinks = _item["ml"] > 0;
        var title = eats && drinks ? "HORA DE COMER E BEBER" : (drinks ? "HORA DE BEBER" : "HORA DE COMER");

        // Faixa colorida no topo: laranja para comer, azul só para beber.
        dc.setColor(eats ? Icons.CARBS_COLOR : Icons.WATER_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, w, h * 0.30);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.21, Graphics.FONT_XTINY, title, center);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.44, Graphics.FONT_MEDIUM, _item["p"], center);

        var y = h * 0.60;
        if (_item["c"] > 0) {
            Icons.stat(dc, cx, y, false, Lang.format("$1$ g carbo", [_item["c"]]), Graphics.FONT_SMALL, Graphics.COLOR_BLACK);
            y += h * 0.11;
        }
        if (drinks) {
            Icons.stat(dc, cx, y, true, Lang.format("$1$ ml", [_item["ml"]]), Graphics.FONT_SMALL, Graphics.COLOR_BLACK);
            y += h * 0.11;
        }
        if (_item["c"] == 0 && !drinks && _item["na"] > 0) {
            dc.drawText(cx, y, Graphics.FONT_SMALL, Lang.format("$1$ mg sódio", [_item["na"]]), center);
            y += h * 0.11;
        }

        if (_withLap) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 0.86, Graphics.FONT_XTINY, "LAP = consumi", center);
        }
    }
}
