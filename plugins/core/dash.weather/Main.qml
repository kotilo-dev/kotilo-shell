// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.components as C
import "forecast.js" as Forecast

// Reads the weather when the dashboard opens. Stays offline until the user names a city: it never
// looks up a location from the IP address.
C.Card {
    id: card
    readonly property var area: ({ x: 0, y: 0, w: 0.36, h: 0.27 })
    centered: true
    readonly property string city: K.Settings.get("dash.weather", "city", "")
    readonly property string unit: K.Settings.get("dash.weather", "unit", "celsius")
    property var place: null
    property var weather: null
    property string status: city.length ? "Loading…" : "Set a city in Settings to see the weather."

    function fetch(url, done) {
        K.Shell.run(["curl", "-fsSL", "--max-time", "10", "--max-filesize", "500000", "--proto", "=https", "--", url], { timeout: 12000 }).then(r => {
            if (r.code !== 0) { card.status = "Could not reach Open-Meteo."; return; }
            try { done(JSON.parse(r.stdout)); } catch (e) { card.status = "Open-Meteo returned something unreadable."; }
        }, () => { card.status = "Could not run curl."; });
    }

    Component.onCompleted: {
        if (!city.length) return;
        fetch(Forecast.geocodeUrl(city), reply => {
            card.place = Forecast.place(reply);
            if (!card.place) { card.status = "That city was not found."; return; }
            fetch(Forecast.forecastUrl(card.place, card.unit), forecast => {
                card.weather = Forecast.summary(forecast);
                if (!card.weather) card.status = "Open-Meteo returned something unreadable.";
            });
        });
    }

    C.Label { visible: !card.weather; width: parent.width; wrapMode: Text.Wrap; secondary: true; textFormat: Text.PlainText; text: card.status }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: !!card.weather
        spacing: K.Theme.space.lg

        C.Icon { anchors.verticalCenter: parent.verticalCenter; size: 48; color: K.Theme.text.primary; name: card.weather ? Forecast.describe(card.weather.code).icon : "" }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            C.Label { color: K.Theme.accent.primary; font.pixelSize: K.Theme.font.size + 15; font.weight: Font.DemiBold; text: card.weather ? card.weather.temperature + (card.unit === "fahrenheit" ? "°F" : "°C") : "" }
            C.Label { secondary: true; text: card.weather ? Forecast.describe(card.weather.code).label : "" }
        }
    }
}
