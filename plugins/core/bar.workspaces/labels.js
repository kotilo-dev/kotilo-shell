// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

// 1 -> I. Numbers Roman numerals cannot write stay as digits.
function roman(number) {
    if (!Number.isInteger(number) || number < 1 || number > 3999) return String(number);
    const steps = [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"],
                   [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]];
    let rest = number, text = "";
    for (const [value, symbol] of steps) {
        while (rest >= value) { text += symbol; rest -= value; }
    }
    return text;
}
