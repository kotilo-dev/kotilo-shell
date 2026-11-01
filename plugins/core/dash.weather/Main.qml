// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.components as C
import "forecast.js" as Forecast

// Reads the weather when the dashboard opens. Stays offline until the user names a city: it never
// looks up a location from the IP address.
C.Card {
    id: card
    title: place ? place.name : "Weather"
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
        visible: !!card.weather
        spacing: K.Theme.space.md

        C.Icon { anchors.verticalCenter: parent.verticalCenter; size: 32; color: K.Theme.text.secondary; name: card.weather ? Forecast.describe(card.weather.code).icon : "" }
        Column {
            C.Label { font.pixelSize: K.Theme.font.size + 11; text: card.weather ? card.weather.temperature + "°" : "" }
            C.Label { secondary: true; text: card.weather ? Forecast.describe(card.weather.code).label : "" }
        }
    }

    Row {
        width: parent.width
        visible: !!card.weather

        Repeater {
            model: card.weather ? card.weather.days : []
            delegate: Column {
                required property var modelData
                width: parent.width / 3
                spacing: K.Theme.space.xs

                C.Label { secondary: true; font.pixelSize: K.Theme.font.size - 2; text: Qt.formatDate(new Date(modelData.date + "T12:00:00"), "ddd") }
                C.Icon { size: 16; color: K.Theme.text.secondary; name: Forecast.describe(modelData.code).icon }
                C.Label { font.features: { "tnum": 1 }; text: modelData.high + "° " + modelData.low + "°" }
            }
        }
    }
}
