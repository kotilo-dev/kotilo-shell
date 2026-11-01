// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

// Weeks of a month as rows of 7 { day, inMonth }, with the days of the months around it filling
// the gaps. month is 0-11. firstDay is the first weekday of the locale: 0 Sunday to 6 Saturday.
function weeks(year, month, firstDay) {
    const lead = (new Date(year, month, 1).getDay() - firstDay + 7) % 7;
    const days = new Date(year, month + 1, 0).getDate();
    const count = Math.ceil((lead + days) / 7) * 7;
    const rows = [];
    for (let i = 0; i < count; i++) {
        if (i % 7 === 0) rows.push([]);
        const date = new Date(year, month, i - lead + 1);
        rows[rows.length - 1].push({ day: date.getDate(), inMonth: date.getMonth() === ((month % 12) + 12) % 12 });
    }
    return rows;
}

// Weekdays in display order, as 0 Sunday to 6 Saturday.
function weekdays(firstDay) {
    return [0, 1, 2, 3, 4, 5, 6].map(i => (firstDay + i) % 7);
}
