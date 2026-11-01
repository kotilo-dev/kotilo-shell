// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

function sections(text) {
    const parts = {};
    let name = "";
    for (const line of String(text).split("\n")) {
        if (line.startsWith("=== ")) { name = line.slice(4); parts[name] = []; }
        else if (name && line.length) parts[name].push(line);
    }
    return parts;
}

function meminfo(lines) {
    const kb = {};
    for (const line of lines) {
        const m = /^(\w+):\s+(\d+)/.exec(line);
        if (m) kb[m[1]] = Number(m[2]);
    }
    return { total: kb.MemTotal || 0, available: kb.MemAvailable || 0, cached: (kb.Cached || 0) + (kb.Buffers || 0),
             swapTotal: kb.SwapTotal || 0, swapUsed: (kb.SwapTotal || 0) - (kb.SwapFree || 0) };
}

// Bytes read and written so far on whole disks: partitions would count twice.
function diskBytes(lines) {
    let read = 0, written = 0;
    for (const line of lines) {
        const f = line.trim().split(/\s+/);
        if (f.length < 10 || !/^(nvme\d+n\d+|sd[a-z]+|vd[a-z]+|xvd[a-z]+|mmcblk\d+)$/.test(f[2])) continue;
        read += Number(f[5]) * 512;
        written += Number(f[9]) * 512;
    }
    return { read: read, written: written };
}

// One entry per filesystem. Btrfs subvolumes share a source, so its shortest mount stands for them.
function filesystems(lines) {
    const seen = {};
    for (const line of lines.slice(1)) {
        const f = line.trim().split(/\s+/);
        if (f.length < 4 || !f[0].startsWith("/dev/")) continue;
        const source = f[0].replace(/\[.*$/, ""), mount = f.slice(1, f.length - 2).join(" ");
        if (!seen[source] || mount.length < seen[source].mount.length)
            seen[source] = { source: source, mount: mount, size: Number(f[f.length - 2]), used: Number(f[f.length - 1]) };
    }
    return Object.keys(seen).map(k => seen[k]).sort((a, b) => b.size - a.size);
}

function interfaces(lines) {
    return lines.map(line => {
        const f = line.trim().split(/\s+/);
        return { name: f[0], state: f[1] || "", rx: Number(f[2]) || 0, tx: Number(f[3]) || 0 };
    }).filter(i => !/^(veth|docker|br-|virbr|podman|cni)/.test(i.name));
}

function temperature(lines, sensor) {
    for (const line of lines) {
        const f = line.trim().split(/\s+/);
        if (f[0] === sensor && isFinite(Number(f[1]))) return Math.round(Number(f[1]) / 1000);
    }
    return null;
}

function number(text) {
    return text !== undefined && text !== "" && isFinite(Number(text)) ? Number(text) : null;
}

function gpus(lines) {
    return lines.map(line => {
        const f = line.split("|");
        const smi = (f[7] || "").split(",").map(v => v.trim());
        const nvidia = smi.length >= 4;
        const name = f.slice(8).join("|").replace(/ \(rev \w+\)$/, "").replace(/ Corporation/, "").trim();
        return {
            driver: f[0], name: name.length ? name : f[0], asleep: f[1] === "suspended",
            busy: nvidia ? number(smi[0]) : number(f[2]),
            memoryUsed: nvidia ? (number(smi[1]) || 0) * 1048576 : number(f[3]),
            memoryTotal: nvidia ? (number(smi[2]) || 0) * 1048576 : number(f[4]),
            temperature: nvidia ? number(smi[3]) : null,
            frequency: number(f[5]), maxFrequency: number(f[6])
        };
    });
}

// sample.sh output -> a plain model of the machine.
function parse(text) {
    const s = sections(text);
    const mhz = (s.cpufreq || []).map(l => Number(l.split(":")[1])).filter(isFinite);
    return {
        memory: meminfo(s.meminfo || []),
        load: ((s.loadavg || [""])[0].split(" ").slice(0, 3)).join("  "),
        uptime: Number(((s.uptime || ["0"])[0]).split(" ")[0]) || 0,
        cpuModel: ((s.cpumodel || [""])[0].split(":")[1] || "").trim().replace(/\(R\)|\(TM\)/g, "").replace(/\s+/g, " "),
        cores: mhz.length,
        cpuMhz: mhz.length ? Math.round(mhz.reduce((a, b) => a + b, 0) / mhz.length) : 0,
        disk: diskBytes(s.diskstats || []),
        filesystems: filesystems(s.df || []),
        net: interfaces(s.net || []),
        cpuTemperature: temperature(s.temps || [], "coretemp"),
        diskTemperature: temperature(s.temps || [], "nvme"),
        gpus: gpus(s.gpus || [])
    };
}

// Bytes per second between two counters; a counter that restarts reads as 0.
function rate(before, after, seconds) {
    return seconds > 0 ? Math.max(0, after - before) / seconds : 0;
}

function bytes(n) {
    const units = ["B", "KB", "MB", "GB", "TB"];
    let value = Math.max(0, n), unit = 0;
    while (value >= 1000 && unit < units.length - 1) { value /= 1024; unit++; }
    return (unit > 0 && value < 10 ? value.toFixed(1) : String(Math.round(value))) + " " + units[unit];
}

function duration(seconds) {
    const d = Math.floor(seconds / 86400), h = Math.floor(seconds % 86400 / 3600), m = Math.floor(seconds % 3600 / 60);
    return d ? d + "d " + h + "h" : h ? h + "h " + m + "m" : m + "m";
}

// Rates as percentages of the largest one, for a graph of something with no fixed top.
function scaled(values) {
    const top = Math.max.apply(null, values.concat([1]));
    return values.map(v => v / top * 100);
}
