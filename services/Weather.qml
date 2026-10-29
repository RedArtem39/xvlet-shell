pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The weather from wttr.in (where the network takes it: the address's
// own place), every 30 minutes. No network, no answer: `ok` is false and
// the pieces say "нет данных".
Singleton {
    id: root

    property bool ok: false
    property int temp: 0
    property int feels: 0
    property string desc: ""
    property string place: ""
    property string icon: "cloud_off"
    property var days: []           // [{ d: "Чт", icon, t }]

    function symbolOf(code) {
        code = +code;
        if (code === 113) return "sunny";
        if (code === 116) return "partly_cloudy_day";
        if ([119, 122, 143, 248, 260].includes(code)) return "cloud";
        if (code >= 200 && code < 300 && code !== 248 && code !== 260) return "thunderstorm";
        if ([179, 227, 230, 323, 326, 329, 332, 335, 338, 368, 371, 392, 395].includes(code)) return "weather_snowy";
        return "rainy";
    }
    Process {
        id: fetch
        command: ["curl", "-s", "--max-time", "12", "https://wttr.in/?format=j1&lang=ru"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text), c = j.current_condition[0];
                    root.temp = +c.temp_C; root.feels = +c.FeelsLikeC;
                    root.desc = (c.lang_ru && c.lang_ru[0] ? c.lang_ru[0].value : c.weatherDesc[0].value);
                    root.icon = root.symbolOf(c.weatherCode);
                    const a = j.nearest_area && j.nearest_area[0];
                    root.place = a ? a.areaName[0].value : "";
                    const names = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"];
                    root.days = (j.weather || []).slice(0, 4).map(w => ({ d: names[new Date(w.date).getDay()], t: +w.maxtempC,
                        icon: root.symbolOf(w.hourly && w.hourly[4] ? w.hourly[4].weatherCode : 116) }));
                    root.ok = true;
                } catch (e) { root.ok = false; }
            }
        }
    }
    Timer { interval: 1800000; running: true; repeat: true; triggeredOnStart: true; onTriggered: fetch.running = true }
    function sign(t) { return (t > 0 ? "+" : "") + t + "°"; }
}
