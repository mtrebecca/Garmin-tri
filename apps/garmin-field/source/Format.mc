import Toybox.Lang;

module Format {

    function duration(seconds) as String {
        if (seconds < 0) {
            seconds = 0;
        }
        var h = seconds / 3600;
        var m = (seconds % 3600) / 60;
        var s = seconds % 60;
        if (h > 0) {
            return Lang.format("$1$:$2$:$3$", [h, m.format("%02d"), s.format("%02d")]);
        }
        return Lang.format("$1$:$2$", [m, s.format("%02d")]);
    }

    // Mostra só o que o item tem; sódio aparece quando não há carbo ou volume (ex.: cápsula de sal).
    function itemDetails(item) as String {
        var parts = [] as Array<String>;
        if (item["c"] > 0) {
            parts.add(Lang.format("$1$ g carb", [item["c"]]));
        }
        if (item["ml"] > 0) {
            parts.add(Lang.format("$1$ ml", [item["ml"]]));
        }
        if (parts.size() == 0 && item["na"] > 0) {
            parts.add(Lang.format("$1$ mg sodio", [item["na"]]));
        }
        var text = "";
        for (var i = 0; i < parts.size(); i++) {
            text += (i > 0 ? " | " : "") + parts[i];
        }
        return text;
    }

    function carbs(taken, planned) as String {
        return Lang.format("$1$ / $2$ g", [taken, planned]);
    }
}
