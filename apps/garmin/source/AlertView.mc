import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Tela de alerta: fica aberta até o atleta agir (diferente do alerta nativo, que some em segundos).
class AlertView extends WatchUi.View {
    private var _fuel;

    function initialize(fuel) {
        View.initialize();
        _fuel = fuel;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_ORANGE);
        dc.clear();
        var item = _fuel.currentItem();
        if (item == null) {
            return;
        }
        var cx = dc.getWidth() / 2;
        var h = dc.getHeight();
        var center = Graphics.TEXT_JUSTIFY_CENTER;

        dc.drawText(cx, h * 0.12, Graphics.FONT_XTINY, "HORA DE CONSUMIR", center);
        dc.drawText(cx, h * 0.28, Graphics.FONT_MEDIUM, item["p"], center);
        dc.drawText(cx, h * 0.45, Graphics.FONT_SMALL, Format.itemDetails(item), center);
        dc.drawText(cx, h * 0.62, Graphics.FONT_XTINY, "START  consumi", center);
        dc.drawText(cx, h * 0.72, Graphics.FONT_XTINY, "DOWN  +5 min", center);
        dc.drawText(cx, h * 0.82, Graphics.FONT_XTINY, "BACK  pular", center);
    }
}

class AlertDelegate extends WatchUi.BehaviorDelegate {
    private var _fuel;

    function initialize(fuel) {
        BehaviorDelegate.initialize();
        _fuel = fuel;
    }

    function onSelect() as Boolean {
        _fuel.confirm();
        return close();
    }

    function onNextPage() as Boolean {
        _fuel.snooze();
        return close();
    }

    function onBack() as Boolean {
        _fuel.skip();
        return close();
    }

    // UP não faz nada aqui, para evitar ação acidental.
    function onPreviousPage() as Boolean {
        return true;
    }

    private function close() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
