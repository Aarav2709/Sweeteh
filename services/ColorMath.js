.pragma library

// srgb to cie lab and back, lab lightness matches the material tone scale

function toLinear(c) {
    return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

function fromLinear(c) {
    return c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
}

function labF(t) {
    return t > 216 / 24389 ? Math.cbrt(t) : (24389 / 27 * t + 16) / 116;
}

function labFInv(t) {
    const t3 = t * t * t;
    return t3 > 216 / 24389 ? t3 : (116 * t - 16) / (24389 / 27);
}

// hex string to lightness, chroma and hue in degrees
function toLch(hex) {
    const n = parseInt(hex.replace("#", ""), 16);
    const r = toLinear((n >> 16 & 255) / 255), g = toLinear((n >> 8 & 255) / 255), b = toLinear((n & 255) / 255);
    const x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047;
    const y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    const z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;
    const fx = labF(x), fy = labF(y), fz = labF(z);
    const L = 116 * fy - 16, A = 500 * (fx - fy), B = 200 * (fy - fz);
    return {
        l: L,
        c: Math.hypot(A, B),
        h: (Math.atan2(B, A) * 180 / Math.PI + 360) % 360
    };
}

function lchToRgb(l, c, h) {
    const A = c * Math.cos(h * Math.PI / 180), B = c * Math.sin(h * Math.PI / 180);
    const fy = (l + 16) / 116, fx = fy + A / 500, fz = fy - B / 200;
    const x = labFInv(fx) * 0.95047, y = labFInv(fy), z = labFInv(fz) * 1.08883;
    return [3.2406 * x - 1.5372 * y - 0.4986 * z, -0.9689 * x + 1.8758 * y + 0.0415 * z, 0.0557 * x - 0.2040 * y + 1.0570 * z].map(fromLinear);
}

// lightness, chroma and hue back to hex, chroma shrinks until the color fits srgb
function fromLch(l, c, h) {
    l = Math.max(0, Math.min(100, l));
    let rgb = lchToRgb(l, c, h);
    for (let i = 0; i < 40 && rgb.some(v => v < -0.001 || v > 1.001); i++) {
        c *= 0.92;
        rgb = lchToRgb(l, c, h);
    }
    return "#" + rgb.map(v => Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16).padStart(2, "0")).join("");
}

// turn a design color part of the way toward the source hue, the way material harmonizes
function harmonize(hex, sourceHex, threshold, harmony) {
    const from = toLch(hex), to = toLch(sourceHex);
    const diff = 180 - Math.abs(Math.abs(from.h - to.h) - 180);
    const rotation = Math.min(diff * harmony, threshold);
    const dir = ((to.h - from.h + 360) % 360) <= 180 ? 1 : -1;
    return fromLch(from.l, from.c, (from.h + rotation * dir + 360) % 360);
}

function boost(hex, chroma, tone) {
    const c = toLch(hex);
    return fromLch(c.l * tone, c.c * chroma, c.h);
}
