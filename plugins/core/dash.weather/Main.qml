// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import qs.Shell as K
import qs.components as C
import "forecast.js" as Forecast

// Reads the weather when the dashboard opens. Stays offline until the user names a city: it never
// looks up a location from the IP address.
C.Card {
    id: card
    readonly property var area: ({ x: 0, y: 0, w: 0.52, h: 0.36 })
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

    component Slot: Column {
        id: cell
        property string label: ""
        property string icon: ""
        property string value: ""
        width: parent.width / 5
        spacing: 1

        C.Label { anchors.horizontalCenter: parent.horizontalCenter; secondary: true; font.pixelSize: K.Theme.font.size - 3; textFormat: Text.PlainText; text: cell.label }
        C.Icon { anchors.horizontalCenter: parent.horizontalCenter; size: 15; color: K.Theme.text.secondary; name: cell.icon }
        C.Label { anchors.horizontalCenter: parent.horizontalCenter; font.pixelSize: K.Theme.font.size - 2; font.features: { "tnum": 1 }; textFormat: Text.PlainText; text: cell.value }
    }

    Row {
        width: parent.width
        visible: !!card.weather
        spacing: K.Theme.space.md

        Column {
            id: now
            anchors.verticalCenter: parent.verticalCenter
            width: 112
            spacing: K.Theme.space.xs

            C.Label { width: parent.width; elide: Text.ElideRight; color: K.Theme.accent.primary; font.weight: Font.DemiBold; textFormat: Text.PlainText; text: card.place ? card.place.name : "" }
            Row {
                spacing: K.Theme.space.sm
                C.Icon { anchors.verticalCenter: parent.verticalCenter; size: 30; color: K.Theme.text.primary; name: card.weather ? Forecast.describe(card.weather.code).icon : "" }
                C.Label { anchors.verticalCenter: parent.verticalCenter; font.pixelSize: K.Theme.font.size + 13; font.weight: Font.DemiBold; text: card.weather ? card.weather.temperature + "°" : "" }
            }
            C.Label { width: parent.width; elide: Text.ElideRight; secondary: true; font.pixelSize: K.Theme.font.size - 1; text: card.weather ? Forecast.describe(card.weather.code).label : "" }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - now.width - parent.spacing
            spacing: K.Theme.space.sm

            Row {
                width: parent.width
                Repeater {
                    model: card.weather ? card.weather.hours : []
                    delegate: Slot {
                        required property var modelData
                        label: modelData.label
                        icon: Forecast.describe(modelData.code).icon
                        value: modelData.temperature + "°"
                    }
                }
            }
            Row {
                width: parent.width
                Repeater {
                    model: card.weather ? card.weather.days : []
                    delegate: Slot {
                        required property var modelData
                        label: Qt.formatDate(new Date(modelData.date + "T12:00:00"), "ddd")
                        icon: Forecast.describe(modelData.code).icon
                        value: modelData.high + "° " + modelData.low + "°"
                    }
                }
            }
        }
    }
}
