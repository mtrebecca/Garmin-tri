import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class FuelUpApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        // A estratégia baixada do backend fica no Storage; sem ela, usa a de teste do POC.
        var strategy = Application.Storage.getValue("strategy");
        if (strategy == null) {
            strategy = SampleStrategy.get();
        }
        var fuel = new FuelSession(strategy);
        return [new MainView(fuel), new MainDelegate(fuel)];
    }
}
