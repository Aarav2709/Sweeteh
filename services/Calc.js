.pragma library

// small safe expression evaluator, no eval
const consts = { pi: Math.PI, e: Math.E, tau: Math.PI * 2 };
const funcs = {
    sqrt: Math.sqrt, abs: Math.abs, round: Math.round, floor: Math.floor, ceil: Math.ceil,
    sin: Math.sin, cos: Math.cos, tan: Math.tan, asin: Math.asin, acos: Math.acos, atan: Math.atan,
    ln: Math.log, log: Math.log10, exp: Math.exp
};

function tokenize(src) {
    const tokens = [];
    const re = /\s*(\d+(?:\.\d+)?(?:e[+-]?\d+)?|\.\d+|[a-z]+|\*\*|[-+*\/%^()!,x×÷])/gy;
    let m;
    let pos = 0;
    while (pos < src.length) {
        re.lastIndex = pos;
        m = re.exec(src);
        if (!m)
            return null;
        tokens.push(m[1]);
        pos = re.lastIndex;
        while (pos < src.length && src[pos] === " ")
            pos++;
    }
    return tokens;
}

function evaluate(input) {
    const src = String(input).toLowerCase().replace(/,/g, "").trim();
    if (!src || !/[\d)]/.test(src))
        return null;
    const tokens = tokenize(src);
    if (!tokens)
        return null;
    let i = 0;
    const peek = () => tokens[i];
    const next = () => tokens[i++];

    function primary() {
        const t = next();
        if (t === undefined)
            throw "end";
        if (t === "(") {
            const v = expr();
            if (next() !== ")")
                throw "paren";
            return v;
        }
        if (t === "-")
            return -power();
        if (t === "+")
            return power();
        if (/^[\d.]/.test(t))
            return parseFloat(t);
        if (t in consts)
            return consts[t];
        if (t in funcs) {
            if (next() !== "(")
                throw "call";
            const v = expr();
            if (next() !== ")")
                throw "paren";
            return funcs[t](v);
        }
        throw "token";
    }

    function postfix() {
        let v = primary();
        while (peek() === "!" || peek() === "%") {
            const op = next();
            if (op === "!") {
                let f = 1;
                for (let k = 2; k <= v; k++)
                    f *= k;
                v = f;
            } else {
                v = v / 100;
            }
        }
        return v;
    }

    function power() {
        const base = postfix();
        if (peek() === "^" || peek() === "**") {
            next();
            return Math.pow(base, power());
        }
        return base;
    }

    function term() {
        let v = power();
        while (["*", "/", "x", "×", "÷"].includes(peek())) {
            const op = next();
            const r = power();
            v = op === "/" || op === "÷" ? v / r : v * r;
        }
        return v;
    }

    function expr() {
        let v = term();
        while (peek() === "+" || peek() === "-") {
            const op = next();
            const r = term();
            v = op === "+" ? v + r : v - r;
        }
        return v;
    }

    try {
        const v = expr();
        if (i !== tokens.length || !isFinite(v))
            return null;
        // a bare number is not a sum
        if (tokens.length === 1)
            return null;
        return Math.round(v * 1e10) / 1e10;
    } catch (e) {
        return null;
    }
}
