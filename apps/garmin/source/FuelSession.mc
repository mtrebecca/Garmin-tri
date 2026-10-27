import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Application;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Sensor;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

enum SessionState {
    STATE_IDLE,
    STATE_RECORDING,
    STATE_PAUSED,
    STATE_FINISHED
}

// Grava a atividade e executa o cronograma de consumo.
//
// O progresso do plano fica no Storage ("progress") para sobreviver ao fechamento do app.
// A gravação em si não pode ser retomada pelo Connect IQ: ao reabrir, o plano continua
// de onde parou numa nova atividade, somando o tempo já corrido (_offset).
class FuelSession {
    const SNOOZE_SECONDS = 300;
    const REVIBRATE_SECONDS = 15;
    const SAVE_EVERY_SECONDS = 30;

    var strategy;
    var items;
    var state = STATE_IDLE;
    var nextIndex = 0;
    var nextDueAt = 0;
    var alertActive = false;
    var carbsTaken = 0;
    var carbsPlanned = 0;
    // Há um treino interrompido desta mesma estratégia que pode ser continuado.
    var resumable = false;

    private var _session = null;
    private var _timer;
    private var _startedAt = 0;
    private var _lastVibeAt = 0;
    private var _seq = 0;
    private var _offset = 0;
    private var _lastSaveAt = 0;

    function initialize(strategy) {
        self.strategy = strategy;
        items = strategy["items"];
        for (var i = 0; i < items.size(); i++) {
            carbsPlanned += items[i]["c"];
        }
        if (items.size() > 0) {
            nextDueAt = items[0]["t"];
        }
        _timer = new Timer.Timer();

        var progress = Application.Storage.getValue("progress");
        resumable = progress != null && strategy["id"].equals(progress["sid"]);
    }

    // Tempo já corrido no treino interrompido, para mostrar antes de continuar.
    function resumableSeconds() {
        var progress = Application.Storage.getValue("progress");
        return progress != null ? progress["offset"] : 0;
    }

    function resume() {
        var progress = Application.Storage.getValue("progress");
        nextIndex = progress["next"];
        nextDueAt = progress["due"];
        carbsTaken = progress["taken"];
        _seq = progress["seq"];
        _startedAt = progress["startedAt"];
        _offset = progress["offset"];
        _lastSaveAt = _offset;
        resumable = false;
        start();
    }

    function startFresh() {
        clearProgress();
        resumable = false;
        start();
    }

    function start() {
        if (_session == null) {
            Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
            Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
            _session = ActivityRecording.createSession({
                :name => "FuelUp",
                :sport => Activity.SPORT_RUNNING,
                :subSport => Activity.SUB_SPORT_GENERIC
            });
            // Ao continuar, mantém o início original para os ids dos registros seguirem estáveis.
            if (_startedAt == 0) {
                _startedAt = Time.now().value();
            }
            _timer.start(method(:onTick), 1000, true);
        }
        _session.start();
        state = STATE_RECORDING;
        saveProgress();
    }

    function pause() {
        if (state == STATE_RECORDING) {
            _session.stop();
            state = STATE_PAUSED;
        }
    }

    function save() {
        finish();
        _session.save();
        _session = null;
        clearProgress();
    }

    function discard() {
        finish();
        _session.discard();
        _session = null;
        clearProgress();
    }

    // App fechando no meio do treino: salva o que foi gravado e mantém o progresso para continuar.
    function onAppStop() {
        if (_session != null && state != STATE_FINISHED) {
            saveProgress();
            finish();
            _session.save();
            _session = null;
        }
    }

    function elapsedSeconds() {
        var info = Activity.getActivityInfo();
        if (info == null || info.timerTime == null) {
            return _offset;
        }
        return _offset + info.timerTime / 1000;
    }

    function currentItem() {
        return nextIndex < items.size() ? items[nextIndex] : null;
    }

    function onPosition(info as Position.Info) as Void {
    }

    function onTick() as Void {
        if (state == STATE_RECORDING) {
            var t = elapsedSeconds();
            if (alertActive) {
                // O alerta insiste até o atleta confirmar, pular ou adiar.
                if (t - _lastVibeAt >= REVIBRATE_SECONDS) {
                    notify(t);
                }
            } else if (nextIndex < items.size() && t >= nextDueAt) {
                alertActive = true;
                notify(t);
                WatchUi.pushView(new AlertView(self), new AlertDelegate(self), WatchUi.SLIDE_UP);
            }
            if (t - _lastSaveAt >= SAVE_EVERY_SECONDS) {
                saveProgress();
            }
        }
        WatchUi.requestUpdate();
    }

    function confirm() {
        carbsTaken += items[nextIndex]["c"];
        record("taken");
        advance();
    }

    function skip() {
        record("skipped");
        advance();
    }

    function snooze() {
        record("snoozed");
        nextDueAt = elapsedSeconds() + SNOOZE_SECONDS;
        alertActive = false;
        saveProgress();
    }

    private function advance() {
        alertActive = false;
        nextIndex += 1;
        if (nextIndex < items.size()) {
            // Se um adiamento empurrou o consumo anterior para depois do próximo,
            // espera 1 min em vez de disparar dois alertas seguidos.
            var now = elapsedSeconds();
            var t = items[nextIndex]["t"];
            nextDueAt = t > now ? t : now + 60;
        }
        saveProgress();
    }

    private function saveProgress() {
        var t = elapsedSeconds();
        _lastSaveAt = t;
        Application.Storage.setValue("progress", {
            "sid" => strategy["id"],
            "startedAt" => _startedAt,
            "next" => nextIndex,
            "due" => nextDueAt,
            "taken" => carbsTaken,
            "seq" => _seq,
            "offset" => t
        });
    }

    private function clearProgress() {
        Application.Storage.deleteValue("progress");
    }

    private function finish() {
        if (state == STATE_RECORDING) {
            _session.stop();
        }
        _timer.stop();
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        state = STATE_FINISHED;
    }

    private function notify(t) {
        _lastVibeAt = t;
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

    // Os registros ficam no relógio até serem enviados ao backend. O id é estável,
    // então reenviar o mesmo registro não gera duplicidade (upsert por client_event_id).
    private function record(action) {
        var logs = Application.Storage.getValue("logs");
        if (logs == null) {
            logs = [];
        }
        _seq += 1;
        logs.add({
            "id" => Lang.format("$1$-$2$-$3$", [_startedAt, nextIndex, _seq]),
            "sid" => strategy["id"],
            "i" => nextIndex,
            "a" => action,
            "t" => elapsedSeconds(),
            "ts" => Time.now().value()
        });
        Application.Storage.setValue("logs", logs);
    }
}
