import Toybox.Activity;
import Toybox.Application;
import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// Campo de dados que roda dentro da atividade nativa (Corrida, Ciclismo, Natação, Triathlon).
// Numa tela de dados só dele, mostra o painel: contagem para o próximo consumo, o produto e
// dois anéis com o carboidrato (laranja) e a hidratação (azul) consumidos do plano; num espaço
// pequeno de outra tela, só a contagem. No modo padrão, sem nenhum clique, cada alerta conta
// como consumido, então os totais sobem sozinhos conforme o plano. Na hora certa vibra e abre um alerta por cima da tela atual, que some sozinho.
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
    const RING_WIDTH = 7;
    const RING_GAP = 3;
    const CARBS_COLOR = Icons.CARBS_COLOR;
    const WATER_COLOR = Icons.WATER_COLOR;

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
    private var _mlPlanned = 0;
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
            dc.drawText(cx, h * 0.56, Graphics.FONT_XTINY, "inativo nesta atividade", center);
            return;
        }

        var outer = (w < h ? w : h) / 2 - RING_WIDTH / 2 - 1;
        drawRing(dc, w / 2, h / 2, outer, _carbsTaken, _carbsPlanned, CARBS_COLOR);
        if (_mlPlanned > 0) {
            drawRing(dc, w / 2, h / 2, outer - RING_WIDTH - RING_GAP, _mlTaken, _mlPlanned, WATER_COLOR);
        }

        // Todo texto na cor principal (preto no fundo branco, branco no preto); cor só nos anéis e ícones.
        dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
        if (_next < 0) {
            dc.drawText(cx, h * 0.27, Graphics.FONT_XTINY, "FuelUp", center);
            dc.drawText(cx, h * 0.43, Graphics.FONT_MEDIUM, _strategyName, center);
            dc.drawText(cx, h * 0.57, Graphics.FONT_XTINY, "Inicie a atividade", center);
        } else if (_next < _items.size()) {
            var item = _items[_next];
            var waitingLap = _pendingSince >= 0;
            dc.drawText(cx, h * 0.24, Graphics.FONT_XTINY, waitingLap ? "Aperte LAP se consumiu" : "Próximo em", center);
            dc.drawText(cx, h * 0.41, Graphics.FONT_NUMBER_HOT, status(), center);
            dc.drawText(cx, h * 0.58, Graphics.FONT_SMALL, item["p"], center);
        } else {
            dc.drawText(cx, h * 0.38, Graphics.FONT_MEDIUM, "Plano", center);
            dc.drawText(cx, h * 0.52, Graphics.FONT_MEDIUM, "concluído!", center);
        }

        Icons.stat(dc, cx, h * 0.72, false, Lang.format("$1$/$2$ g", [_carbsTaken, _carbsPlanned]), Graphics.FONT_XTINY, fg);
        if (_mlPlanned > 0) {
            Icons.stat(dc, cx, h * 0.82, true, Lang.format("$1$/$2$ ml", [_mlTaken, _mlPlanned]), Graphics.FONT_XTINY, fg);
        }
    }

    // Anel de progresso: trilho cinza e, na cor do nutriente, a fração do planejado já consumida.
    private function drawRing(dc as Graphics.Dc, x, y, r, taken, planned, color) {
        dc.setPenWidth(RING_WIDTH);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, r);
        if (planned > 0 && taken > 0) {
            var sweep = 360 * taken / planned;
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            if (sweep >= 360) {
                dc.drawCircle(x, y, r);
            } else {
                dc.drawArc(x, y, r, Graphics.ARC_CLOCKWISE, 90, 90 - sweep);
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
        _mlTaken = 0;
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
