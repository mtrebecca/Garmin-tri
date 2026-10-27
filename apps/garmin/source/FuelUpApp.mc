import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class FuelUpApp extends Application.AppBase {
    private var _fuel = null;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        // A estratégia baixada do backend fica no Storage; sem ela, usa a de teste do POC.
        var strategy = Application.Storage.getValue("strategy");
        if (strategy == null) {
            strategy = SampleStrategy.get();
        }
        _fuel = new FuelSession(strategy);
        return [new MainView(_fuel), new MainDelegate(_fuel)];
    }

    function onStop(state as Dictionary?) as Void {
        if (_fuel != null) {
            _fuel.onAppStop();
        }
    }
}
