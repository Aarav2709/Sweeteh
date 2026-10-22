.pragma library

// score how well a query matches text, higher is better, 0 means no match
function score(query, text) {
    if (!query)
        return 1;
    const q = query.toLowerCase();
    const t = String(text || "").toLowerCase();
    if (!t)
        return 0;
    if (t === q)
        return 1000;
    if (t.startsWith(q))
        return 800 - t.length;
    const word = t.indexOf(" " + q);
    if (word >= 0)
        return 600 - word;
    const sub = t.indexOf(q);
    if (sub >= 0)
        return 400 - sub;
    // subsequence match rewards consecutive letters and word starts
    let ti = 0;
    let total = 0;
    let streak = 0;
    for (let qi = 0; qi < q.length; qi++) {
        const found = t.indexOf(q[qi], ti);
        if (found < 0)
            return 0;
        streak = found === ti ? streak + 1 : 0;
        total += 5 + streak * 4 + (found === 0 || t[found - 1] === " " ? 8 : 0) - Math.min(found - ti, 10);
        ti = found + 1;
    }
    return Math.max(1, total);
}

// best score over several fields, later fields weigh less
function best(query, fields) {
    let top = 0;
    for (let i = 0; i < fields.length; i++)
        top = Math.max(top, score(query, fields[i]) * (1 - i * 0.15));
    return top;
}
