import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class MainView extends WatchUi.View {
    private var _fuel;

    function initialize(fuel) {
        View.initialize();
        _fuel = fuel;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var cx = dc.getWidth() / 2;
        var h = dc.getHeight();

        if (_fuel.state == STATE_IDLE) {
            drawCentered(dc, cx, h * 0.30, Graphics.FONT_MEDIUM, _fuel.strategy["name"]);
            drawCentered(dc, cx, h * 0.50, Graphics.FONT_SMALL, Lang.format("$1$ consumos", [_fuel.items.size()]));
            drawCentered(dc, cx, h * 0.65, Graphics.FONT_XTINY, "START para iniciar");
            return;
        }

        if (_fuel.state == STATE_FINISHED) {
            drawCentered(dc, cx, h * 0.30, Graphics.FONT_MEDIUM, "Fim");
            drawCentered(dc, cx, h * 0.50, Graphics.FONT_SMALL, Format.carbs(_fuel.carbsTaken, _fuel.carbsPlanned));
            drawCentered(dc, cx, h * 0.65, Graphics.FONT_XTINY, "BACK para sair");
            return;
        }

        var t = _fuel.elapsedSeconds();
        drawCentered(dc, cx, h * 0.12, Graphics.FONT_NUMBER_MEDIUM, Format.duration(t));

        var info = Activity.getActivityInfo();
        var hr = (info != null && info.currentHeartRate != null) ? info.currentHeartRate.toString() : "--";
        var km = (info != null && info.elapsedDistance != null) ? (info.elapsedDistance / 1000.0).format("%.2f") : "0.00";
        drawCentered(dc, cx, h * 0.40, Graphics.FONT_SMALL, Lang.format("$1$ km  |  $2$ bpm", [km, hr]));

        var item = _fuel.currentItem();
        if (item != null) {
            drawCentered(dc, cx, h * 0.56, Graphics.FONT_XTINY, item["p"]);
            drawCentered(dc, cx, h * 0.66, Graphics.FONT_SMALL, "em " + Format.duration(_fuel.nextDueAt - t));
        } else {
            drawCentered(dc, cx, h * 0.60, Graphics.FONT_XTINY, "Plano concluido");
        }

        drawCentered(dc, cx, h * 0.80, Graphics.FONT_XTINY, Format.carbs(_fuel.carbsTaken, _fuel.carbsPlanned));

        if (_fuel.state == STATE_PAUSED) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            drawCentered(dc, cx, h * 0.03, Graphics.FONT_XTINY, "PAUSADO");
        }
    }

    private function drawCentered(dc, x, y, font, text) {
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
