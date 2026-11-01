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

const sys = load("dash.performance/system.js");
const sample = `=== meminfo
MemTotal:       16000000 kB
MemAvailable:   12000000 kB
Buffers:          100000 kB
Cached:           900000 kB
SwapTotal:       2000000 kB
SwapFree:        1500000 kB
=== loadavg
0.50 0.40 0.30 1/900 1234
=== uptime
3700.5 1000.0
=== cpufreq
cpu MHz		: 1000.0
cpu MHz		: 3000.0
=== cpumodel
model name	: Intel(R) Core(TM) i5-10300H CPU @ 2.50GHz
=== diskstats
 259 0 nvme1n1 100 0 2000 0 50 0 4000 0 0 0 0
 259 1 nvme1n1p1 100 0 2000 0 50 0 4000 0 0 0 0
   7 0 loop0 9 0 9000 0 9 0 9000 0 0 0 0
   8 0 sda 1 0 1000 0 1 0 2000 0 0 0 0
=== df
Filesystem 1B-blocks Used
/dev/mapper/root[/@home] /home 500 100
/dev/mapper/root[/@log] /var/log 500 100
/dev/mapper/root / 500 100
/dev/nvme1n1p1 /boot 200 50
tmpfs /run 100 1
=== net
enp4s0 down 10 20
wlo1 up 1000 2000
veth1 up 9 9
=== temps
acpitz 40000
coretemp 62500
nvme 38000
=== gpus
nvidia|active|||||||NVIDIA Corporation TU117M [GeForce GTX 1650 Ti] (rev a1)
nvidia|active||||||30, 512, 4096, 55|NVIDIA GPU
nvidia|suspended||||||
i915|active||||350|1050||Intel UHD|with bar
amdgpu|active|42|1048576|2097152|||
`;
const machine = plain(sys.parse(sample));
assert.equal(machine.memory.total, 16000000);
assert.equal(machine.memory.cached, 1000000);
assert.equal(machine.memory.swapUsed, 500000);
assert.equal(machine.load, "0.50  0.40  0.30");
assert.equal(machine.uptime, 3700.5);
assert.equal(machine.cpuModel, "Intel Core i5-10300H CPU @ 2.50GHz");
assert.equal(machine.cores, 2);
assert.equal(machine.cpuMhz, 2000);
assert.deepEqual(machine.disk, { read: 3000 * 512, written: 6000 * 512 }, "whole disks only");
assert.deepEqual(machine.filesystems.map(f => f.mount), ["/", "/boot"], "subvolumes are one filesystem");
assert.deepEqual(machine.net.map(i => i.name), ["enp4s0", "wlo1"]);
assert.equal(machine.cpuTemperature, 63);
assert.equal(machine.diskTemperature, 38);
const [plainNvidia, awake, asleep, intel, amd] = machine.gpus;
assert.equal(plainNvidia.busy, null, "no reading unless asked");
assert.equal(plainNvidia.name, "NVIDIA TU117M [GeForce GTX 1650 Ti]");
assert.equal(awake.busy, 30);
assert.equal(awake.memoryTotal, 4096 * 1048576);
assert.equal(awake.temperature, 55);
assert.equal(asleep.asleep, true);
assert.equal(asleep.name, "nvidia");
assert.equal(intel.busy, null);
assert.equal(intel.frequency, 350);
assert.equal(intel.name, "Intel UHD|with bar");
assert.equal(amd.busy, 42);
assert.equal(amd.memoryUsed, 1048576);
assert.equal(plain(sys.parse("")).gpus.length, 0);
assert.equal(sys.rate(100, 300, 2), 100);
assert.equal(sys.rate(300, 100, 2), 0, "a restarted counter");
assert.equal(sys.bytes(512), "512 B");
assert.equal(sys.bytes(2048), "2.0 KB");
assert.equal(sys.bytes(1048576 * 500), "500 MB");
assert.equal(sys.duration(3700), "1h 1m");
assert.equal(sys.duration(90000), "1d 1h");
assert.deepEqual(plain(sys.scaled([1, 2, 4])), [25, 50, 100]);
assert.deepEqual(plain(sys.scaled([])), []);

const market = load("dash.trade/market.js");
const src = e => { const v = plain(market.source(e)); return v && { kind: v.kind, symbol: v.symbol }; };
assert.deepEqual(src(" aapl "), { kind: "yahoo", symbol: "AAPL" });
assert.deepEqual(src("THYAO.IS"), { kind: "yahoo", symbol: "THYAO.IS" });
assert.deepEqual(src("EURUSD=X"), { kind: "yahoo", symbol: "EURUSD=X" });
assert.deepEqual(src("^GSPC"), { kind: "yahoo", symbol: "^GSPC" });
assert.deepEqual(src("tefas:aft"), { kind: "tefas", symbol: "AFT" });
for (const bad of ["", "a b", "../x", "a/b", "AAPL?x=1", "tefas:../x", "tefas:", "x".repeat(25), 5, null, {}, { symbol: "a b" }, { formula: "" }, { formula: "2*3" }, { formula: "AAPL/0" }, { formula: "a;b" }, { formula: "process.exit()" }]) assert.equal(market.source(bad), null, "refuse: " + JSON.stringify(bad));
assert.equal(market.source({ symbol: "USDTRY=X", label: "Dolar" }).label, "Dolar");
assert.equal(market.source("AAPL").label, "AAPL");
const gram = market.source({ formula: "GC=F*USDTRY=X/31.1035", label: "Gram", currency: "TRY" });
assert.equal(gram.label, "Gram");
assert.deepEqual(plain(gram.needs).map(n => n.symbol), ["GC=F", "USDTRY=X"]);
const parts = { "yahoo:GC=F": { price: 3000, change: 1, history: [2900, 3000] }, "yahoo:USDTRY=X": { price: 50, change: 2, history: [48, 49, 50] } };
const computed = plain(market.compute(gram, parts));
assert.ok(Math.abs(computed.price - 3000 * 50 / 31.1035) < 1e-9);
assert.ok(Math.abs(computed.change - 3.02) < 1e-9, "changes compound");
assert.equal(computed.currency, "TRY");
assert.equal(computed.history.length, 2, "the shorter history");
assert.ok(Math.abs(computed.history[1] - computed.price) < 1e-9, "the newest point is today");
assert.equal(market.compute(gram, { "yahoo:GC=F": parts["yahoo:GC=F"] }), null, "waits for every part");
assert.equal(plain(market.compute(gram, { "yahoo:GC=F": parts["yahoo:GC=F"], "yahoo:USDTRY=X": { error: true } })).error, true, "a failed part fails the line");
const ratio = plain(market.compute(market.source({ formula: "GC=F/SI=F" }), { "yahoo:GC=F": { price: 100, change: 10, history: [] }, "yahoo:SI=F": { price: 50, change: 10, history: [] } }));
assert.equal(ratio.price, 2);
assert.ok(Math.abs(ratio.change) < 1e-9, "dividing cancels equal moves");
assert.ok(market.dataUrl({ kind: "yahoo", symbol: "EURUSD=X" }).includes("/chart/EURUSD%3DX?"));
assert.equal(market.pageUrl({ kind: "tefas", symbol: "AFT" }), "https://www.tefas.gov.tr/tr/fon-detayli-analiz/AFT");
const chart = plain(market.parseChart(JSON.stringify({ chart: { result: [{ meta: { shortName: "Apple     Inc   ", currency: "USD", regularMarketPrice: 110, chartPreviousClose: 50 },
    indicators: { quote: [{ close: [90, null, 100, 110] }] } }] } })));
assert.equal(chart.name, "Apple Inc");
assert.equal(chart.change, 10, "against the previous close, not the start of the range");
assert.deepEqual(chart.history, [90, 100, 110]);
assert.equal(market.parseChart('{"chart":{"result":null,"error":{"code":"Not Found"}}}'), null);
assert.equal(plain(market.parseChart(JSON.stringify({ chart: { result: [{ meta: { regularMarketPrice: 5 } }] } }))).change, null, "one close has no change");
assert.equal(market.turkishNumber("0,959756"), 0.959756);
assert.equal(market.turkishNumber("1.234,56"), 1234.56);
assert.equal(market.turkishNumber("-0,12"), -0.12);
assert.ok(isNaN(market.turkishNumber("abc")));
const fund = plain(market.parseTefas('<script>"lastPrice":"Son Fiyat (TL)"</script><p>Son Fiyat (TL)</p><span></span><div>0,959756</div><p>Günlük Getiri (%)</p><i>%</i><b>-0,3975</b>'));
assert.equal(fund.price, 0.959756);
assert.equal(fund.change, -0.3975);
assert.equal(fund.currency, "TRY");
assert.equal(plain(market.parseTefas('<p>Son Fiyat (TL)</p><b>1,5</b>')).change, null);
for (const bad of ["", "<html>nothing</html>", "<p>Son Fiyat (TL)</p><b>yok</b>", "<p>Son Fiyat (TL)</p><b>0</b>"]) assert.equal(market.parseTefas(bad), null, "no guessed price: " + bad);
assert.equal(market.price(1234.5, "USD"), "1,234.50 USD");
assert.equal(market.price(1234567.891, ""), "1,234,567.89");
assert.equal(market.price(242.2, "TRY"), "242.20 TRY");
assert.equal(market.price(0.959756, "TRY"), "0.9598 TRY");
assert.equal(market.price(1.1166, "USD"), "1.1166 USD");
assert.equal(market.percent(1.5), "+1.50%");
assert.equal(market.percent(-0.256), "-0.26%");
assert.equal(market.percent(null), "");
assert.deepEqual(plain(market.shape([1])), []);
assert.deepEqual(plain(market.shape([10, 20])), [8, 100]);
assert.deepEqual(plain(market.shape([5, 5])), [50, 50]);

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

assert.equal(gh.repositoriesPage("xmsadik"), "https://github.com/xmsadik?tab=repositories");
assert.equal(gh.repositoriesPage("../evil"), "https://github.com/");
assert.equal(gh.repositoriesPage(undefined), "https://github.com/");
const now = Date.parse("2026-11-01T12:00:00Z");
assert.equal(gh.age("2026-11-01T11:59:40Z", now), "now");
assert.equal(gh.age("2026-11-01T11:55:00Z", now), "5m");
assert.equal(gh.age("2026-11-01T09:00:00Z", now), "3h");
assert.equal(gh.age("2026-10-30T12:00:00Z", now), "2d");
assert.equal(gh.age("2026-07-01T12:00:00Z", now), "4mo");
assert.equal(gh.age("2027-01-01T00:00:00Z", now), "now", "a future date");
assert.equal(gh.age(undefined, now), "");
const pulls = plain(gh.pullRows([{ title: "T", url: "https://github.com/a/b/pull/1", number: 1, updatedAt: "2026-11-01T09:00:00Z", repository: { nameWithOwner: "a/b" } }], now));
assert.deepEqual(pulls[0], { title: "T", url: "https://github.com/a/b/pull/1", trailing: "3h", detail: "a/b#1" });
for (const remote of ["git@github.com:a/b.git", "https://github.com/a/b.git", "https://github.com/a/b", "ssh://git@github.com/a/b.git"]) assert.equal(gh.remotePage(remote), "https://github.com/a/b", remote);
for (const remote of ["", "git@gitlab.com:a/b.git", "https://github.com.evil.example/a/b", "file:///a/b"]) assert.equal(gh.remotePage(remote), "", remote);
const local = plain(gh.localRows(`### /home/me/dev/clean
time 200
remote git@github.com:a/clean.git
# branch.head main
# branch.ab +0 -0
### /home/me/dev/work
time 100
remote https://gitlab.com/a/work.git
# branch.oid abc
# branch.head feature
# branch.upstream origin/feature
# branch.ab +2 -1
1 .M N... 100644 100644 100644 abc abc file.txt
? new.txt
### /srv/other
time
remote
`, "/home/me"));
assert.deepEqual(local.map(r => r.title), ["work", "clean", "other"], "attention first");
assert.equal(local[0].trailing, "2 changed  ↑2  ↓1");
assert.equal(local[0].detail, "feature  ~/dev/work");
assert.equal(local[0].attention, true);
assert.equal(local[0].url, "", "not on GitHub");
assert.equal(local[1].trailing, "clean");
assert.equal(local[1].url, "https://github.com/a/clean");
assert.equal(local[2].detail, "/srv/other");
assert.equal(gh.localRows("", "/h").length, 0);

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
assert.deepEqual(novemberRows[0].map(c => c.day), [26, 27, 28, 29, 30, 31, 1], "Monday first, with days from October");
assert.deepEqual(novemberRows[0].map(c => c.inMonth), [false, false, false, false, false, false, true]);
const lastWeek = novemberRows[novemberRows.length - 1];
assert.equal(lastWeek[0].day, 30);
assert.equal(lastWeek[0].inMonth, true);
assert.equal(lastWeek[1].day, 1);
assert.equal(lastWeek[1].inMonth, false);
assert.deepEqual(plain(month.weeks(2026, 10, 0))[0].map(c => c.day), [1, 2, 3, 4, 5, 6, 7], "Sunday first");
const inMonth = (y, m) => plain(month.weeks(y, m, 1)).flat().filter(c => c.inMonth).map(c => c.day);
assert.ok(inMonth(2028, 1).includes(29), "leap year");
assert.ok(!inMonth(2026, 1).includes(29));
assert.equal(inMonth(2026, 11).length, 31, "December stays inside its year");
assert.equal(inMonth(2027, 0).length, 31, "January too");
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
const reply = { current: { time: "2026-11-01T22:15", temperature_2m: 18.6, weather_code: 3 },
    hourly: { time: ["2026-11-01T22:00", "2026-11-01T23:00", "2026-11-02T00:00", "2026-11-02T01:00", "2026-11-02T02:00", "2026-11-02T03:00", "2026-11-02T04:00"],
              temperature_2m: [18, 17.6, 17, 16, 15, 14, 13], weather_code: [3, 3, 61, 61, 3, 2, 1] },
    daily: { time: ["2026-11-01", "2026-11-02", "2026-11-03", "2026-11-04", "2026-11-05", "2026-11-06"], weather_code: [1, 2, 3, 61, 0, 1],
             temperature_2m_max: [20, 21.4, 22, 19, 18, 17], temperature_2m_min: [10, 11, 12.5, 9, 8, 7] } };
const s = plain(w.summary(reply));
assert.equal(s.temperature, 19);
assert.deepEqual(s.hours.map(h => h.label), ["23:00", "00:00", "01:00", "02:00", "03:00"], "the next five hours, not the current one");
assert.equal(s.hours[0].temperature, 18);
assert.equal(s.hours[1].code, 61);
assert.equal(s.days.length, 5, "five days after today");
assert.deepEqual(s.days[0], { date: "2026-11-02", code: 2, high: 21, low: 11 });
assert.equal(s.days[4].date, "2026-11-06");
assert.equal(plain(w.summary({ current: reply.current, daily: reply.daily })).hours.length, 0, "no hourly data is not an error");
assert.equal(w.summary({}), null);
console.log("  dashboard card checks pass");
