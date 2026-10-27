import Toybox.Activity;
import Toybox.Application;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// Campo de dados que roda dentro da atividade nativa (Corrida, Ciclismo, Triathlon).
// Mostra só a contagem para o próximo consumo; na hora certa vibra e abre um alerta
// por cima da tela atual, que some sozinho.
//
// Registro (configuração "confirmWithLap"):
//   desligado: alerta sem ação conta como consumido ("taken", by "auto").
//   ligado: LAP em até 2 min confirma ("taken", by "lap"); sem LAP vira "missed".
// O celular pode corrigir os registros depois (by "phone").
class FuelField extends WatchUi.SimpleDataField {
    const CONFIRM_WINDOW_SECONDS = 120;
    const REMIND_AFTER_SECONDS = 60;

    private var _items;
    private var _strategyId;
    // -1 = ainda não posicionado no cronograma (a atividade não começou).
    private var _next = -1;
    private var _pendingSince = -1;
    private var _reminded = false;
    private var _sessionStart = 0;
    private var _seq = 0;
    private var _lastT = 0;

    function initialize() {
        SimpleDataField.initialize();
        label = "FuelUp";
        // A estratégia sincronizada fica no Storage; sem ela, usa a de teste do POC.
        var strategy = Application.Storage.getValue("strategy") as Dictionary?;
        if (strategy == null) {
            strategy = SampleStrategy.get();
        }
        _items = strategy["items"];
        _strategyId = strategy["id"];
    }

    function compute(info as Activity.Info) as Numeric or Duration or String or Null {
        if (info.timerTime == null || info.timerTime == 0) {
            return "--";
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

        if (_pendingSince >= 0) {
            return "LAP?";
        }
        if (_next >= _items.size()) {
            return "Fim";
        }
        return Format.duration(_items[_next]["t"] - t);
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
