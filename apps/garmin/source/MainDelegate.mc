import Toybox.Lang;
import Toybox.WatchUi;

// Botões na tela principal: START inicia/pausa, BACK só sai antes de iniciar ou depois de salvar.
class MainDelegate extends WatchUi.BehaviorDelegate {
    private var _fuel;

    function initialize(fuel) {
        BehaviorDelegate.initialize();
        _fuel = fuel;
    }

    function onSelect() as Boolean {
        if (_fuel.state == STATE_RECORDING) {
            _fuel.pause();
            showPauseMenu();
        } else if (_fuel.state == STATE_IDLE && _fuel.resumable) {
            showResumeMenu();
        } else if (_fuel.state == STATE_IDLE || _fuel.state == STATE_PAUSED) {
            _fuel.start();
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() as Boolean {
        if (_fuel.state == STATE_PAUSED) {
            showPauseMenu();
            return true;
        }
        // Durante a gravação o BACK é ignorado; no início e no fim, sai do app.
        return _fuel.state == STATE_RECORDING;
    }

    private function showPauseMenu() {
        var menu = new WatchUi.Menu2({ :title => "Pausado" });
        menu.addItem(new WatchUi.MenuItem("Retomar", null, :resume, null));
        menu.addItem(new WatchUi.MenuItem("Salvar", null, :save, null));
        menu.addItem(new WatchUi.MenuItem("Descartar", null, :discard, null));
        WatchUi.pushView(menu, new PauseMenuDelegate(_fuel), WatchUi.SLIDE_UP);
    }

    private function showResumeMenu() {
        var menu = new WatchUi.Menu2({ :title => "Treino interrompido" });
        menu.addItem(new WatchUi.MenuItem("Continuar plano", null, :resume, null));
        menu.addItem(new WatchUi.MenuItem("Novo treino", null, :fresh, null));
        WatchUi.pushView(menu, new ResumeMenuDelegate(_fuel), WatchUi.SLIDE_UP);
    }
}

class ResumeMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _fuel;

    function initialize(fuel) {
        Menu2InputDelegate.initialize();
        _fuel = fuel;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :resume) {
            _fuel.resume();
        } else {
            _fuel.startFresh();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class PauseMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _fuel;

    function initialize(fuel) {
        Menu2InputDelegate.initialize();
        _fuel = fuel;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :resume) {
            _fuel.start();
        } else if (id == :save) {
            _fuel.save();
        } else if (id == :discard) {
            _fuel.discard();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
