import Toybox.Activity;
import Toybox.Application;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// Campo de dados que roda dentro da atividade nativa (Corrida, Ciclismo, Natação, Triathlon).
// Numa tela de dados só dele, mostra o painel: contagem para o próximo consumo, o produto e
// um anel com o carboidrato consumido do plano; num espaço pequeno de outra tela, só a
// contagem. Na hora certa vibra e abre um alerta por cima da tela atual, que some sozinho.
//
// Configurações (app Garmin Connect no celular):
//   enabled e activeRun/Bike/Swim/Other: em quais atividades o FuelUp atua; nas demais a
//   tela mostra "inativo" e não alerta nem registra.
//   confirmWithLap desligado: alerta sem ação conta como consumido ("taken", by "auto");
//   ligado: LAP em até 2 min confirma ("taken", by "lap"); sem LAP vira "missed".
// O celular pode corrigir os registros depois (by "phone").
class FuelField extends WatchUi.DataField {
    const CONFIRM_WINDOW_SECONDS = 120;
    const REMIND_AFTER_SECONDS = 60;
    // Abaixo disso o campo divide a tela com outros e mostra só a contagem.
    const FULL_LAYOUT_MIN_HEIGHT = 150;
    const RING_WIDTH = 8;

    private var _items;
    private var _strategyId;
    private var _strategyName;
    // -1 = ainda não posicionado no cronograma (a atividade não começou).
    private var _next = -1;
    private var _active = true;
    private var _pendingSince = -1;
    private var _reminded = false;
    private var _sessionStart = 0;
    private var _seq = 0;
    private var _lastT = 0;
    private var _carbsPlanned = 0;
    private var _carbsTaken = 0;

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
        if (!_active) {
            return;
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
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        if (h < FULL_LAYOUT_MIN_HEIGHT) {
            dc.drawText(cx, h * 0.25, Graphics.FONT_XTINY, "FuelUp", center);
            dc.drawText(cx, h * 0.62, Graphics.FONT_MEDIUM, _active ? status() : "--", center);
            return;
        }

        if (!_active) {
            dc.drawText(cx, h * 0.42, Graphics.FONT_SMALL, "FuelUp", center);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 0.56, Graphics.FONT_XTINY, "inativo nesta atividade", center);
            return;
        }

        drawRing(dc, w, h);

        if (_next < 0) {
            dc.drawText(cx, h * 0.34, Graphics.FONT_XTINY, "FUELUP", center);
            dc.drawText(cx, h * 0.50, Graphics.FONT_SMALL, _strategyName, center);
            dc.drawText(cx, h * 0.66, Graphics.FONT_XTINY, Lang.format("$1$ g carbo", [_carbsPlanned]), center);
            return;
        }

        if (_next < _items.size()) {
            var item = _items[_next];
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 0.24, Graphics.FONT_XTINY, _pendingSince >= 0 ? "CONFIRME COM LAP" : "PROXIMO", center);
            dc.setColor(_pendingSince >= 0 ? Graphics.COLOR_ORANGE : fg, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 0.45, Graphics.FONT_NUMBER_HOT, status(), center);
            dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 0.64, Graphics.FONT_SMALL, item["p"], center);
        } else {
            dc.drawText(cx, h * 0.45, Graphics.FONT_MEDIUM, "Plano concluido", center);
        }

        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.79, Graphics.FONT_XTINY, Lang.format("$1$ / $2$ g carbo", [_carbsTaken, _carbsPlanned]), center);
    }

    // Anel na borda da tela: trilho cinza e, em laranja, a fração do carboidrato planejado já consumida.
    private function drawRing(dc as Graphics.Dc, w, h) {
        var r = (w < h ? w : h) / 2 - RING_WIDTH / 2 - 1;
        dc.setPenWidth(RING_WIDTH);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(w / 2, h / 2, r);
        if (_carbsPlanned > 0 && _carbsTaken > 0) {
            var sweep = 360 * _carbsTaken / _carbsPlanned;
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            if (sweep >= 360) {
                dc.drawCircle(w / 2, h / 2, r);
            } else {
                dc.drawArc(w / 2, h / 2, r, Graphics.ARC_CLOCKWISE, 90, 90 - sweep);
            }
        }
        dc.setPenWidth(1);
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
    }

    // Se o campo for recarregado no meio do treino, não dispara os alertas que já passaram.
    private function begin(t) {
        _active = isActiveForCurrentSport();
        _sessionStart = Time.now().value() - t;
        _next = 0;
        while (_next < _items.size() && _items[_next]["t"] < t - 1) {
            _next += 1;
        }
    }

    // A tela do FuelUp fica em todas as atividades em que o atleta a adicionou; as
    // configurações decidem em quais delas ele alerta. Esporte desconhecido conta como "outras".
    private function isActiveForCurrentSport() as Boolean {
        if (Application.Properties.getValue("enabled") == false) {
            return false;
        }
        var sport = null;
        if (Activity has :getProfileInfo) {
            var profile = Activity.getProfileInfo();
            if (profile != null) {
                sport = profile.sport;
            }
        }
        var key = "activeOther";
        if (sport == Activity.SPORT_RUNNING) {
            key = "activeRun";
        } else if (sport == Activity.SPORT_CYCLING) {
            key = "activeBike";
        } else if (sport == Activity.SPORT_SWIMMING) {
            key = "activeSwim";
        }
        return Application.Properties.getValue(key) == true;
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
