// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

// WMO weather codes, as used by Open-Meteo -> { label, icon }.
function describe(code) {
    if (code === 0 || code === 1) return { label: code ? "Mostly clear" : "Clear", icon: "sun" };
    if (code === 2 || code === 3) return { label: code === 2 ? "Partly cloudy" : "Cloudy", icon: "cloud" };
    if (code === 45 || code === 48) return { label: "Fog", icon: "fog" };
    if (code >= 51 && code <= 57) return { label: "Drizzle", icon: "rain" };
    if (code >= 61 && code <= 67) return { label: "Rain", icon: "rain" };
    if ((code >= 71 && code <= 77) || code === 85 || code === 86) return { label: "Snow", icon: "snow" };
    if (code >= 80 && code <= 82) return { label: "Showers", icon: "rain" };
    if (code === 95 || code === 96 || code === 99) return { label: "Thunderstorm", icon: "storm" };
    return { label: "Unknown", icon: "cloud" };
}

function geocodeUrl(city) {
    return "https://geocoding-api.open-meteo.com/v1/search?count=1&format=json&name=" + encodeURIComponent(city);
}

function forecastUrl(place, unit) {
    return "https://api.open-meteo.com/v1/forecast?latitude=" + Number(place.latitude) + "&longitude=" + Number(place.longitude)
        + "&current=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=4"
        + (unit === "fahrenheit" ? "&temperature_unit=fahrenheit" : "");
}

// A geocoding reply -> { name, latitude, longitude }, or null when the city was not found.
function place(reply) {
    const r = reply && reply.results && reply.results[0];
    if (!r || typeof r.latitude !== "number" || typeof r.longitude !== "number") return null;
    return { name: String(r.name || ""), latitude: r.latitude, longitude: r.longitude };
}

// A forecast reply -> { temperature, code, days: [{ date, code, high, low }] }, or null.
function summary(reply) {
    const now = reply && reply.current, daily = reply && reply.daily;
    if (!now || typeof now.temperature_2m !== "number" || !daily || !Array.isArray(daily.time)) return null;
    return {
        temperature: Math.round(now.temperature_2m),
        code: now.weather_code,
        days: daily.time.slice(1).map((date, i) => ({
            date: date, code: daily.weather_code[i + 1],
            high: Math.round(daily.temperature_2m_max[i + 1]), low: Math.round(daily.temperature_2m_min[i + 1])
        }))
    };
}
