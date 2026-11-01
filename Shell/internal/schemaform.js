// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

// Fields of a settings form, from a JSON schema and the current values (ADR-0004).
// kind: boolean, integer, number, string, enum, or other for what the form cannot edit.
function fields(schema, values) {
    const properties = schema && schema.properties ? schema.properties : {};
    return Object.keys(properties).map(key => {
        const p = properties[key] || {};
        const kind = Array.isArray(p.enum) ? "enum"
                   : ["boolean", "integer", "number", "string"].indexOf(p.type) >= 0 ? p.type : "other";
        const given = values ? values[key] : undefined;
        return { key: key, title: p.title || key, description: p.description || "", kind: kind,
                 value: given !== undefined ? given : p.default,
                 minimum: p.minimum, maximum: p.maximum, options: p.enum || [] };
    });
}

function clamp(field, value) {
    if (typeof field.minimum === "number") value = Math.max(field.minimum, value);
    if (typeof field.maximum === "number") value = Math.min(field.maximum, value);
    return value;
}

// The value one step away, or undefined when this field has no steps.
function step(field, direction) {
    if (field.kind === "boolean") return !field.value;
    if (field.kind === "integer" || field.kind === "number") {
        const base = typeof field.value === "number" ? field.value : (field.minimum || 0);
        return clamp(field, base + direction);
    }
    if (field.kind === "enum" && field.options.length) {
        const count = field.options.length;
        return field.options[(field.options.indexOf(field.value) + direction + count) % count];
    }
    return undefined;
}

// Typed text -> { ok, value }. Never guesses: text that does not fit is refused, not repaired.
function parse(field, text) {
    if (field.kind === "string") return { ok: true, value: text };
    if (field.kind === "integer" || field.kind === "number") {
        const value = text.trim().length ? Number(text) : NaN;
        if (!isFinite(value) || (field.kind === "integer" && Math.floor(value) !== value)) return { ok: false };
        if (clamp(field, value) !== value) return { ok: false };
        return { ok: true, value: value };
    }
    return { ok: false };
}

function display(field) {
    if (field.kind === "other") return "edit in settings.json";
    if (field.kind === "boolean") return field.value ? "on" : "off";
    if (field.value === undefined || field.value === "") return "not set";
    return String(field.value);
}

// Next row with a field, wrapping past headings. rows hold { field } or { heading }.
function move(rows, index, direction) {
    for (let i = 1; i <= rows.length; i++) {
        const next = (index + direction * i + rows.length * i) % rows.length;
        if (rows[next].field) return next;
    }
    return index;
}
