import Toybox.Activity;
import Toybox.Application;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// Campo de dados que roda dentro da atividade nativa (Corrida, Ciclismo, Triathlon).
// Numa tela de dados só dele, mostra o painel completo (próximo consumo, contagem e
// consumido × planejado); num espaço pequeno de outra tela, só a contagem. Na hora certa
// vibra e abre um alerta por cima da tela atual, que some sozinho.
//
// Registro (configuração "confirmWithLap"):
//   desligado: alerta sem ação conta como consumido ("taken", by "auto").
//   ligado: LAP em até 2 min confirma ("taken", by "lap"); sem LAP vira "missed".
// O celular pode corrigir os registros depois (by "phone").
class FuelField extends WatchUi.DataField {
    const CONFIRM_WINDOW_SECONDS = 120;
    const REMIND_AFTER_SECONDS = 60;
    // Abaixo disso o campo divide a tela com outros e mostra só a contagem.
    const FULL_LAYOUT_MIN_HEIGHT = 150;

    private var _items;
    private var _strategyId;
    private var _strategyName;
    // -1 = ainda não posicionado no cronograma (a atividade não começou).
    private var _next = -1;
    private var _pendingSince = -1;
    private var _reminded = false;
    private var _sessionStart = 0;
    private var _seq = 0;
    private var _lastT = 0;
    private var _carbsPlanned = 0;
    private var _mlPlanned = 0;
    private var _carbsTaken = 0;
    private var _mlTaken = 0;

    function initialize() {
        DataField.initialize();
        // A estratégia sincronizada fica no Storage; sem ela, usa a de teste do POC.
        var strategy = Application.Storage.getValue("strategy") as Dictionary?;
        if (strategy == null) {
            strategy = SampleStrategy.get();
        }
        _items = strategy["items"];
        _strategyId = strategy["id"];
        _strategyName = strategy["name"];
        for (var i = 0; i < _items.size(); i++) {
            _carbsPlanned += _items[i]["c"];
            _mlPlanned += _items[i]["ml"];
        }
    }

    function compute(info as Activity.Info) as Void {
        if (info.timerTime == null || info.timerTime == 0) {
            return;
        }
        var t = info.timerTime / 1000;
        _lastT = t;
        if (_next < 0) {
            begin(t);
        }

        if (_pendingSince >= 0) {
            var waited = t - _pendingSince;
            if (waited >= CONFIRM_WINDOW_SECONDS) {
                resolve("missed", "lap");
            } else if (!_reminded && waited >= REMIND_AFTER_SECONDS) {
                _reminded = true;
                vibrate();
            }
        } else if (_next < _items.size() && t >= _items[_next]["t"]) {
            alert(t);
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var bg = getBackgroundColor();
        var fg = bg == Graphics.COLOR_BLACK ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
        dc.setColor(fg, bg);
        dc.clear();
        var cx = dc.getWidth() / 2;
        var h = dc.getHeight();
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        if (h < FULL_LAYOUT_MIN_HEIGHT) {
            dc.drawText(cx, h * 0.25, Graphics.FONT_XTINY, "FuelUp", center);
            dc.drawText(cx, h * 0.62, Graphics.FONT_MEDIUM, status(), center);
            return;
        }

        dc.drawText(cx, h * 0.14, Graphics.FONT_XTINY, "FUELUP", center);
        if (_next < 0) {
            dc.drawText(cx, h * 0.40, Graphics.FONT_SMALL, _strategyName, center);
            dc.drawText(cx, h * 0.58, Graphics.FONT_XTINY, Lang.format("$1$ consumos", [_items.size()]), center);
            return;
        }

        if (_next < _items.size()) {
            dc.drawText(cx, h * 0.30, Graphics.FONT_SMALL, _items[_next]["p"], center);
            if (_pendingSince >= 0) {
                dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            }
            dc.drawText(cx, h * 0.49, Graphics.FONT_NUMBER_MEDIUM, status(), center);
            dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.drawText(cx, h * 0.40, Graphics.FONT_MEDIUM, "Plano concluido", center);
        }

        dc.drawText(cx, h * 0.69, Graphics.FONT_SMALL, Lang.format("$1$/$2$ g carbo", [_carbsTaken, _carbsPlanned]), center);
        if (_mlPlanned > 0) {
            dc.drawText(cx, h * 0.82, Graphics.FONT_XTINY, Lang.format("$1$/$2$ ml", [_mlTaken, _mlPlanned]), center);
        }
    }

    // Contagem para o próximo consumo, "LAP?" aguardando confirmação ou "Fim".
    private function status() as String {
        if (_next < 0) {
            return "--";
        }
        if (_pendingSince >= 0) {
            return "LAP?";
        }
        if (_next >= _items.size()) {
            return "Fim";
        }
        return Format.duration(_items[_next]["t"] - _lastT);
    }

    function onTimerLap() as Void {
        if (_pendingSince >= 0) {
            resolve("taken", "lap");
        }
    }

    // Atividade salva ou descartada: o próximo treino recomeça o cronograma.
    function onTimerReset() as Void {
        _next = -1;
        _pendingSince = -1;
        _seq = 0;
        _carbsTaken = 0;
        _mlTaken = 0;
    }

    // Se o campo for recarregado no meio do treino, não dispara os alertas que já passaram.
    private function begin(t) {
        _sessionStart = Time.now().value() - t;
        _next = 0;
        while (_next < _items.size() && _items[_next]["t"] < t - 1) {
            _next += 1;
        }
    }

    private function alert(t) {
        var withLap = Application.Properties.getValue("confirmWithLap") == true;
        vibrate();
        if (WatchUi.DataField has :showAlert) {
            showAlert(new FuelAlert(_items[_next], withLap));
        }
        if (withLap) {
            _pendingSince = t;
            _reminded = false;
        } else {
            record("taken", "auto");
            _next += 1;
        }
    }

    private function resolve(action, by) {
        record(action, by);
        _pendingSince = -1;
        _next += 1;
    }

    private function vibrate() {
        if (Attention has :vibrate) {
            Attention.vibrate([
                new Attention.VibeProfile(100, 500),
                new Attention.VibeProfile(0, 200),
                new Attention.VibeProfile(100, 500)
            ]);
        }
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_ALERT_HI);
        }
    }

    // Mesmo formato do Device App (docs/contrato-estrategia.md), com "by" indicando
    // como o registro foi feito. O id é estável, então reenviar não duplica.
    private function record(action, by) {
        var logs = Application.Storage.getValue("logs") as Array?;
        if (logs == null) {
            logs = [];
        }
        if (action.equals("taken")) {
            _carbsTaken += _items[_next]["c"];
            _mlTaken += _items[_next]["ml"];
        }
        _seq += 1;
        logs.add({
            "id" => Lang.format("$1$-$2$-$3$", [_sessionStart, _next, _seq]),
            "sid" => _strategyId,
            "i" => _next,
            "a" => action,
            "by" => by,
            "t" => _lastT,
            "ts" => Time.now().value()
        });
        Application.Storage.setValue("logs", logs);
    }
}
