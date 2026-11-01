// SPDX-License-Identifier: GPL-3.0-or-later
// Unit tests for Shell/internal/template.js, plus every bundled theme through every target template.
import { readFileSync, readdirSync, existsSync } from "node:fs";
import vm from "node:vm";
import assert from "node:assert/strict";

const root = new URL("../", import.meta.url);
const ctx = {};
vm.runInNewContext(readFileSync(new URL("Shell/internal/template.js", root), "utf8").replace(".pragma library", ""), ctx);
const { render } = ctx;

const t = { bg: { base: "#102030" }, ansi: ["#000000", "#ffffff"], variant: "dark", name: "N" };
assert.equal(render("{{bg.base}}", t), "#102030");
assert.equal(render("{{ bg.base }}", t), "#102030");
assert.equal(render("{{bg.base.rgb}}", t), "16,32,48");
assert.equal(render("{{ansi.1}}", t), "#ffffff");
assert.equal(render("{{#isDark}}d{{/isDark}}{{^isDark}}l{{/isDark}}", t), "d");
assert.equal(render("{{#isDark}}d{{/isDark}}{{^isDark}}l{{/isDark}}", { variant: "light" }), "l");
assert.throws(() => render("{{bg.missing}}", t), /no token bg.missing/);
assert.throws(() => render("{{bg}}", t), /no token bg/);
assert.throws(() => render("{{nope.rgb}}", t), /no token/);

const formats = {
    "theme.ghostty": /^(#.*|(background|foreground|cursor-color|selection-background|selection-foreground) = #[0-9a-f]{6}|palette = \d{1,2}=#[0-9a-f]{6})$/i,
    "theme.kitty": /^(#.*|(background|foreground|cursor|cursor_text_color|selection_background|selection_foreground|color\d{1,2}) #[0-9a-f]{6})$/i
};
const themes = readdirSync(new URL("themes/", root)).filter(id => existsSync(new URL(`themes/${id}/tokens.json`, root)));
assert.ok(themes.length >= 6);
for (const [plugin, format] of Object.entries(formats)) {
    const template = readFileSync(new URL(`plugins/core/${plugin}/template.conf`, root), "utf8");
    for (const id of themes) {
        const lines = render(template, JSON.parse(readFileSync(new URL(`themes/${id}/tokens.json`, root), "utf8"))).trim().split("\n");
        for (const line of lines) assert.match(line, format, `${plugin} with ${id}`);
        assert.equal(lines.filter(l => /(palette = |^color)\d/.test(l)).length, 16, `${plugin} with ${id}: 16 colours`);
    }
}
console.log("  template checks pass");
