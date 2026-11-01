// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

// Weeks of a month as 7-day rows of day numbers, 0 for a blank. month is 0-11. firstDay is the
// first weekday of the locale: 0 Sunday to 6 Saturday.
function weeks(year, month, firstDay) {
    const days = new Date(year, month + 1, 0).getDate();
    const cells = [];
    for (let i = 0; i < (new Date(year, month, 1).getDay() - firstDay + 7) % 7; i++) cells.push(0);
    for (let d = 1; d <= days; d++) cells.push(d);
    while (cells.length % 7) cells.push(0);
    const rows = [];
    for (let i = 0; i < cells.length; i += 7) rows.push(cells.slice(i, i + 7));
    return rows;
}

// Weekdays in display order, as 0 Sunday to 6 Saturday.
function weekdays(firstDay) {
    return [0, 1, 2, 3, 4, 5, 6].map(i => (firstDay + i) % 7);
}
