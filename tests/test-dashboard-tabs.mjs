// SPDX-License-Identifier: GPL-3.0-or-later
// Unit tests for the dashboard tab parsers. Run: node tests/test-dashboard-tabs.mjs
import { readFileSync } from "node:fs";
import vm from "node:vm";
import assert from "node:assert/strict";

const load = path => {
    const src = readFileSync(new URL("../plugins/core/" + path, import.meta.url), "utf8").replace(".pragma library", "");
    const ctx = {};
    vm.runInNewContext(src, ctx);
    return ctx;
};
const plain = v => JSON.parse(JSON.stringify(v));

const proc = load("dash.performance/processes.js");
const top = `top - 21:00:00 up 1:00
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
      1 root      20   0   10000  99999    100 S  99.0   0.1   0:01.00 stale

top - 21:00:01 up 1:00
Tasks: 3 total
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   4143 me        20   0 5695164 400000 132984 S   4.5   2.9   7:47.69 claude
   4144 me        20   0 5695164 100000 132984 S   1.5   2.9   7:47.69 claude
    200 root      20   0       0      0      0 I   6.0   0.0   0:00.07 kworker/u32:5-event
    201 root      20   0       0      0      0 I   0.0   0.0   0:00.07 kworker/2:1-mm
    300 me        20   0    9000    512    100 S   0.0   0.0   0:00.01 Web Content
`;
const parsed = proc.parseTop(top);
assert.equal(parsed.length, 5, "only the last sample");
assert.ok(!parsed.some(p => p.name === "stale"));
assert.equal(parsed[4].name, "Web Content");
const grouped = plain(proc.group(parsed));
assert.deepEqual(grouped[0], { name: "claude", count: 2, cpu: 6, memKb: 500000 });
assert.equal(grouped[1].name, "kworker");
assert.equal(grouped[1].count, 2);
assert.equal(proc.parseTop("nothing here").length, 0);
assert.equal(proc.memory(512), "512 KB");
assert.equal(proc.memory(2048), "2 MB");
assert.equal(proc.memory(3 * 1048576), "3.0 GB");

const gh = load("dash.github/links.js");
assert.equal(gh.pageFor("https://api.github.com/repos/a/b/pulls/12"), "https://github.com/a/b/pull/12");
assert.equal(gh.pageFor("https://api.github.com/repos/a/b/issues/3"), "https://github.com/a/b/issues/3");
assert.equal(gh.pageFor("https://api.github.com/repos/a/b/commits/abc"), "https://github.com/a/b/commit/abc");
assert.equal(gh.pageFor("https://api.github.com/repos/a/b"), "https://github.com/a/b");
assert.equal(gh.pageFor("https://evil.example/repos/a/b"), "");
assert.equal(gh.pageFor(null), "");
assert.equal(gh.safe("https://github.com/a"), true);
for (const bad of ["file:///etc/passwd", "http://github.com/a", "https://github.com.evil.example/a", null]) assert.equal(gh.safe(bad), false);
const rows = plain(gh.notificationRows([{ reason: "review_requested", subject: { title: "T", url: "https://api.github.com/repos/a/b/pulls/1" }, repository: { full_name: "a/b", html_url: "https://github.com/a/b" } },
                                        { reason: "ci_activity", subject: { title: "Run", url: null }, repository: { full_name: "a/b", html_url: "https://github.com/a/b" } }]));
assert.equal(rows[0].url, "https://github.com/a/b/pull/1");
assert.equal(rows[0].trailing, "review requested");
assert.equal(rows[1].url, "https://github.com/a/b", "falls back to the repository");

const rss = load("dash.rss/feed.js");
const r = rss.parse(`<?xml version="1.0"?><rss><channel><title>Blog &amp; News</title><link>https://b.example</link>
<item><title><![CDATA[First & <b>bold</b>]]></title><link>https://b.example/1</link><pubDate>Sun, 01 Nov 2026 10:00:00 GMT</pubDate><description>&lt;p&gt;Hello &amp;amp; bye&lt;/p&gt;</description></item>
<item><title>Bad link</title><link>javascript:alert(1)</link><pubDate>nonsense</pubDate></item>
<item><description>no title</description></item></channel></rss>`);
assert.equal(r.title, "Blog & News");
assert.equal(r.items.length, 2, "untitled items are dropped");
assert.equal(r.items[0].title, "First & <b>bold</b>".replace(/<\/?b>/g, "").replace(/\s+/g, " ").trim().replace("& bold", "& bold"));
assert.equal(r.items[0].link, "https://b.example/1");
assert.equal(r.items[0].summary, "Hello & bye");
assert.equal(r.items[0].date, Date.UTC(2026, 10, 1, 10));
assert.equal(r.items[1].link, "", "only web links");
assert.equal(r.items[1].date, 0);

const a = rss.parse(`<feed xmlns="http://www.w3.org/2005/Atom"><title>Atom</title><entry><title>E</title><link rel="self" href="https://a.example/self"/><link rel="alternate" href="https://a.example/e?x=1&amp;y=2"/><updated>2026-11-02T00:00:00Z</updated><summary>S</summary></entry></feed>`);
assert.equal(a.title, "Atom");
assert.equal(a.items[0].link, "https://a.example/e?x=1&y=2");
const merged = plain(rss.merge([r, a], 2));
assert.equal(merged.length, 2);
assert.equal(merged[0].title, "E", "newest first");
assert.equal(merged[0].source, "Atom");
assert.equal(rss.parse("not xml").items.length, 0);
assert.equal(rss.parse("").title, "");

console.log("  dashboard tab checks pass");

const month = load("dash.calendar/month.js");
const novemberRows = plain(month.weeks(2026, 10, 1));     // November 2026 starts on a Sunday
assert.deepEqual(novemberRows[0], [0, 0, 0, 0, 0, 0, 1], "Monday first");
assert.deepEqual(novemberRows[novemberRows.length - 1], [30, 0, 0, 0, 0, 0, 0]);
assert.deepEqual(plain(month.weeks(2026, 10, 0))[0], [1, 2, 3, 4, 5, 6, 7], "Sunday first");
assert.ok(plain(month.weeks(2028, 1, 1)).flat().includes(29), "leap year");
assert.ok(!plain(month.weeks(2026, 1, 1)).flat().includes(29));
assert.deepEqual(plain(month.weekdays(1)), [1, 2, 3, 4, 5, 6, 0]);

const w = load("dash.weather/forecast.js");
assert.equal(w.describe(0).icon, "sun");
assert.equal(w.describe(3).icon, "cloud");
assert.equal(w.describe(63).label, "Rain");
assert.equal(w.describe(75).icon, "snow");
assert.equal(w.describe(95).icon, "storm");
assert.equal(w.describe(1234).label, "Unknown");
assert.ok(w.geocodeUrl("São Paulo & co").endsWith("name=S%C3%A3o%20Paulo%20%26%20co"), "a city cannot alter the query");
assert.equal(w.place({}), null);
assert.equal(w.place({ results: [{ name: "X", latitude: "1", longitude: 2 }] }), null);
const where = w.place({ results: [{ name: "Istanbul", latitude: 41.01, longitude: 28.95 }] });
assert.ok(w.forecastUrl(where, "celsius").includes("latitude=41.01&longitude=28.95"));
assert.ok(!w.forecastUrl(where, "celsius").includes("fahrenheit"));
assert.ok(w.forecastUrl(where, "fahrenheit").includes("temperature_unit=fahrenheit"));
const s = plain(w.summary({ current: { temperature_2m: 18.6, weather_code: 3 }, daily: { time: ["a", "b", "c"], weather_code: [1, 2, 3], temperature_2m_max: [20, 21.4, 22], temperature_2m_min: [10, 11, 12.5] } }));
assert.equal(s.temperature, 19);
assert.deepEqual(s.days, [{ date: "b", code: 2, high: 21, low: 11 }, { date: "c", code: 3, high: 22, low: 13 }]);
assert.equal(w.summary({}), null);
console.log("  dashboard card checks pass");
