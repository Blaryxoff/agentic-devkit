(root = null, only = null, opts = {}) => {
  const t0 = performance.now();
  let R;
  if (root == null) R = document.querySelector("main") || document.body;
  else {
    try { R = document.querySelector(root); } catch (e) { return { root, blocked: "invalid-root", error: String(e && e.message || e) }; }
    if (!R) return { root, blocked: "root-not-found" };
  }
  const want = k => !only || only.includes(k);
  const CAP = opts.cap || 12;
  const cap = a => a.length > CAP ? { items: a.slice(0, CAP), truncated: a.length - CAP } : a;
  const ALL = [R, ...R.querySelectorAll("*")];
  const maxNodes = opts.maxNodes || 6000, maxMs = opts.maxMs || 4000;
  const NODES = ALL.slice(0, maxNodes);
  const out = { root: root || (R === document.body ? "body" : "main"), viewport: [innerWidth, document.documentElement.clientWidth],
    nodes: ALL.length, truncatedNodes: ALL.length - NODES.length,
    untested: { shadowRoots: NODES.filter(e => e.shadowRoot).length, iframes: NODES.filter(e => e.tagName === "IFRAME").length } };
  const late = () => performance.now() - t0 > maxMs;
  const stop = k => late() && (out.timedOut = out.timedOut || k, true);

  const ST = new Map(), RC = new Map(), CC = new Map();
  const st = e => { let s = ST.get(e); if (!s) ST.set(e, s = getComputedStyle(e)); return s; };
  const rc = e => { let r = RC.get(e); if (!r) RC.set(e, r = e.getBoundingClientRect()); return r; };
  const cv = document.createElement("canvas"); cv.width = cv.height = 1;
  const cx = cv.getContext("2d", { willReadFrequently: true });
  const rgba = c => { if (CC.has(c)) return CC.get(c);
    cx.clearRect(0, 0, 1, 1); cx.fillStyle = "rgba(0,0,0,0)"; cx.fillStyle = c; cx.fillRect(0, 0, 1, 1);
    const d = cx.getImageData(0, 0, 1, 1).data, v = [d[0], d[1], d[2], d[3] / 255]; CC.set(c, v); return v; };
  const over = (t, b) => [0, 1, 2].map(i => t[i] * t[3] + b[i] * (1 - t[3])).concat(1);
  const lum = c => { const [r, g, b] = c.slice(0, 3).map(v => { v /= 255;
    return v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; }); return 0.2126 * r + 0.7152 * g + 0.0722 * b; };
  const ratio = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05); };
  const show = x => Math.floor(x * 100) / 100;
  const hex = c => "#" + c.slice(0, 3).map(v => Math.round(v).toString(16).padStart(2, "0")).join("");

  const vis = e => { const r = rc(e); if (!(r.width > 0 && r.height > 0)) return false;
    if (e.checkVisibility) return e.checkVisibility({ opacityProperty: true, visibilityProperty: true, contentVisibilityAuto: true });
    for (let n = e; n; n = n.parentElement) { const s = st(n); if (s.display === "none" || s.visibility === "hidden" || +s.opacity === 0) return false; }
    return true; };
  const clipsAll = s => /^inset\((?:[5-9]\d(?:\.\d+)?|100)%(?:\s+[^\s)]+)?\)/.test(s.clipPath) ||
    /^(?:circle|ellipse)\(0(?:px|%)?[\s)]/.test(s.clipPath) ||
    (/^(absolute|fixed)$/.test(s.position) && /^rect\(0px,? 0px,? 0px,? 0px\)$/.test(s.clip));
  const clippedAway = e => { const r = rc(e); if (clipsAll(st(e))) return true;
    for (let n = e.parentElement; n && n !== document.documentElement; n = n.parentElement) {
      const s = st(n); if (clipsAll(s)) return true;
      if (s.overflowX === "visible" && s.overflowY === "visible" && s.clipPath === "none") continue;
      const p = rc(n); if (r.right <= p.left || r.left >= p.right || r.bottom <= p.top || r.top >= p.bottom) return true; }
    return false; };
  const shown = e => vis(e) && !clippedAway(e);
  const inView = e => { const r = rc(e); return r.bottom > 0 && r.right > 0 && r.top < innerHeight && r.left < innerWidth; };
  const onPage = e => { const r = rc(e); return r.right > 0 && r.left < innerWidth && r.bottom + scrollY > 0; };

  const complex = s => s.backgroundImage !== "none" || s.filter !== "none" || s.mixBlendMode !== "normal" ||
    (s.backdropFilter && s.backdropFilter !== "none") || +s.opacity < 1;
  const faded = e => { for (let n = e; n; n = n.parentElement) { const s = st(n);
    if (+s.opacity < 1 || s.filter !== "none" || s.mixBlendMode !== "normal") return true; } return false; };
  const PS = new Map();
  const pseudo = (e, p) => { let m = PS.get(e); if (!m) PS.set(e, m = {});
    if (!(p in m)) { const s = getComputedStyle(e, p); m[p] = s.content !== "none" && s.content !== "normal" ? s : null; } return m[p]; };
  const pseudoFill = e => ["::before", "::after"].some(p => { const s = pseudo(e, p);
    return !!s && (rgba(s.backgroundColor)[3] > 0 || s.backgroundImage !== "none"); });
  const BD = new Map();
  const backdrop = e => { if (BD.has(e)) return BD.get(e); const layers = []; let indeterminate = false;
    for (let n = e.parentElement; n; n = n.parentElement) { const s = st(n); if (complex(s) || pseudoFill(n)) indeterminate = true;
      const c = rgba(s.backgroundColor); if (c[3] > 0) { layers.push(c); if (c[3] >= 1) break; } }
    const v = { c: layers.reduceRight((acc, l) => over(l, acc), [255, 255, 255, 1]), indeterminate }; BD.set(e, v); return v; };
  const pseudoPaint = e => ["::before", "::after"].some(p => { const s = pseudo(e, p);
    return !!s && (rgba(s.backgroundColor)[3] > 0 || s.backgroundImage !== "none" ||
      borderSides(s).length > 0 || s.boxShadow !== "none" || s.outlineStyle !== "none"); });

  const SIDES = ["Top", "Right", "Bottom", "Left"];
  const borderSides = s => SIDES.filter(k => parseFloat(s[`border${k}Width`]) > 0 &&
    !/none|hidden/.test(s[`border${k}Style`]) && rgba(s[`border${k}Color`])[3] > 0);
  const COLOR = /(rgba?|hsla?|hwb|oklch|oklab|lab|lch|color)\([^)]*\)/i;
  const layersOf = v => !v || v === "none" ? [] : v.split(/,(?![^(]*\))/).map(L => {
    const m = L.match(COLOR), c = m ? rgba(m[0]) : [0, 0, 0, 1];
    const [x = 0, y = 0, blur = 0, spread = 0] = ((m ? L.replace(m[0], "") : L).match(/-?[\d.]+px/g) || []).map(parseFloat);
    return { c, a: c[3], x, y, blur, spread, inset: /\binset\b/.test(L) }; });
  const paints = (L, r, back) => L.a > 0 && (L.blur > 0 || L.spread > 0 || L.x !== 0 || L.y !== 0) &&
    (L.inset || (r.width + 2 * L.spread > 0 && r.height + 2 * L.spread > 0)) &&
    Math.max(Math.abs(L.x), Math.abs(L.y)) <= L.blur + Math.max(L.spread, 0) + 1 &&
    ratio(over([L.c[0], L.c[1], L.c[2], L.blur > 0 && L.spread <= 0 ? L.a / 2 : L.a], back), back) >= 1.1;
  const shadowOf = e => { const L = layersOf(st(e).boxShadow); return L.length > 0 && L.some(l => paints(l, rc(e), backdrop(e).c)); };
  const outlined = s => s.outlineStyle !== "none" && parseFloat(s.outlineWidth) > 0 && rgba(s.outlineColor)[3] > 0;
  const drawsEdge = e => { const s = st(e); return borderSides(s).length > 0 || shadowOf(e) || outlined(s); };
  const filled = e => rgba(st(e).backgroundColor)[3] > 0 || st(e).backgroundImage !== "none";
  const styled = e => drawsEdge(e) || filled(e) || pseudoPaint(e);

  const FIELD = "input:not([type=checkbox]):not([type=radio]):not([type=hidden]):not([type=button]):not([type=submit]):not([type=reset]):not([type=image]),select,textarea,[role=combobox]";
  const TINY = "input[type=checkbox],input[type=radio],[role=checkbox],[role=radio],[role=switch]";
  const CTL = "button,input:not([type=hidden]),select,textarea,summary,[role=button],[role=combobox],[role=tab],[role=switch],a[href]";
  const NAMED = "button,a[href],input:not([type=hidden]),select,textarea,summary,[role=button],[role=link],[role=combobox],[role=tab],[role=switch],[role=checkbox],[role=radio],[role=menuitem]";
  const txt = n => (n && n.textContent || "").trim().replace(/\s+/g, " ");
  const nameText = n => [...n.childNodes].map(c => c.nodeType === 3 ? c.textContent
    : c.nodeType !== 1 || c.getAttribute("aria-hidden") === "true" || st(c).display === "none" || st(c).visibility === "hidden" ? ""
    : c.tagName === "IMG" ? ` ${c.alt || ""} ` : c.matches("select,input,textarea") ? "" : ` ${(c.getAttribute("aria-label") || "").trim() || nameText(c)} `).join("");
  const clean = s => s.trim().replace(/\s+/g, " ");
  const accName = e => { const lb = e.getAttribute("aria-labelledby");
    if (lb) { const t = clean(lb.split(/\s+/).map(id => { const n = document.getElementById(id); return n ? nameText(n) : ""; }).join(" ")); if (t) return t; }
    const al = (e.getAttribute("aria-label") || "").trim(); if (al) return al;
    if (e.matches("input,select,textarea")) { const l = clean([...(e.labels || [])].map(nameText).join(" ")); if (l) return l;
      if (e.matches("input[type=button],input[type=submit],input[type=reset]") && e.value) return e.value;
      if (e.matches("input[type=image]") && e.alt) return e.alt; }
    else { const t = clean(nameText(e)); if (t) return t; }
    return (e.getAttribute("title") || e.getAttribute("placeholder") || "").trim(); };
  const label = e => (accName(e) || e.tagName.toLowerCase()).slice(0, 32);
  const ident = e => (e.id ? `#${e.id}` : (e.getAttribute("class") || e.tagName.toLowerCase())).slice(0, 50);
  const isCtl = e => e.matches(CTL) && !e.matches(TINY) && vis(e) && (!e.matches("a") || styled(e));
  let _controls; const controls = () => _controls || (_controls = NODES.filter(isCtl));

  const room = el => el.matches(FIELD) ? 40 : 16;
  const FW = new Map();
  const seenText = c => [c, ...c.querySelectorAll("*")].some(n => [...n.childNodes].some(t => t.nodeType === 3 && t.textContent.trim()) &&
    rc(n).width > 1 && rc(n).height > 1 && vis(n) && !clippedAway(n));
  const adornment = c => !seenText(c) && !styled(c);
  const fieldWrap = f => { if (FW.has(f)) return FW.get(f); const lim = rc(f).height + room(f); let w = f;
    for (let n = f; n && rc(n).height <= lim; n = n.parentElement) {
      if (n !== f && [...n.querySelectorAll(CTL)].some(c => c !== f && !f.contains(c) && !adornment(c))) break;
      if (drawsEdge(n)) { w = n; break; } }
    FW.set(f, w); return w; };
  const IND = new Map();
  const indep = n => { if (IND.has(n)) return IND.get(n); const fs = [...n.querySelectorAll(FIELD)].concat(n.matches(FIELD) ? [n] : []), ws = fs.map(fieldWrap);
    const others = [...n.querySelectorAll(CTL)].concat(n.matches(CTL) ? [n] : [])
      .filter(c => !c.matches(FIELD) && !c.matches(TINY) && !ws.some(w => w.contains(c)));
    const v = fs.length + others.length; IND.set(n, v); return v; };
  const chain = el => { const lim = rc(el).height + room(el), outc = [];
    for (let n = el; n && n !== R.parentElement && rc(n).height <= lim && (n === el || indep(n) <= 1); n = n.parentElement) outc.push(n);
    return outc; };
  const box = (el, stop) => { let best = el; for (const n of chain(el)) { if (n === stop) break; if (styled(n)) best = n; } return best; };

  if (want("rhythm")) {
    const seen = new Set(), rows = [];
    for (const row of NODES) {
      if (stop("rhythm")) break;
      const cs = st(row);
      if (!/flex|grid/.test(cs.display) || (cs.display.includes("flex") && cs.flexDirection.startsWith("column"))) continue;
      if (indep(row) < 2) continue;
      const bx = [];
      for (const c of row.children) { const x = c.matches(CTL) ? c : c.querySelector(CTL);
        if (x && vis(x) && !x.matches(TINY)) { const b = box(x, row); if (!seen.has(b) && !bx.includes(b)) bx.push(b); } }
      if (bx.length < 2) continue;
      const lines = [];
      for (const b of bx.map(b => ({ el: b, r: rc(b) })).sort((a, z) => a.r.top - z.r.top)) {
        const l = lines.find(l => b.r.top < l.bottom - 2 && b.r.bottom > l.top + 2);
        if (l) { l.items.push(b); l.bottom = Math.max(l.bottom, b.r.bottom); } else lines.push({ top: b.r.top, bottom: b.r.bottom, items: [b] }); }
      for (const l of lines) {
        if (l.items.length < 2) continue;
        const hs = [...new Set(l.items.map(i => Math.round(i.r.height)))];
        const fs = [...new Set(l.items.map(i => st(i.el).fontSize))];
        const off = opts.scale ? hs.filter(h => !opts.scale.includes(h)) : [];
        if (hs.length > 1 || fs.length > 1 || off.length) { l.items.forEach(i => seen.add(i.el));
          rows.push({ heights: hs, fontSizes: fs, offScale: off, boxes: l.items.map(i => ({ t: label(i.el), h: Math.round(i.r.height), fs: st(i.el).fontSize })) }); } } }
    out.rhythm = cap(rows);
  }

  if (want("boundaries")) {
    const done = new Set(), res = [];
    for (const e of controls()) {
      if (stop("boundaries")) break;
      if (e.matches("a")) continue;
      const ch = chain(e), top = ch[ch.length - 1]; if (done.has(top)) continue; done.add(top);
      if (ch.some(shadowOf) && !faded(e)) continue;
      const { c: back, indeterminate } = backdrop(top); let ind = indeterminate, fill = back, edge = 1;
      for (const n of [...ch].reverse()) { const s = st(n); if (complex(s) || pseudoPaint(n)) ind = true;
        const f = over(rgba(s.backgroundColor), fill); edge = Math.max(edge, ratio(f, back));
        for (const k of borderSides(s)) edge = Math.max(edge, ratio(over(rgba(s[`border${k}Color`]), f), back));
        if (outlined(s)) edge = Math.max(edge, ratio(over(rgba(s.outlineColor), back), back));
        fill = f; }
      if (edge >= 3 && !ind) continue;
      const field = e.matches(FIELD) || !!top.querySelector(FIELD);
      res.push({ t: label(e), kind: field ? "field" : txt(e) ? "text" : "icon", disabled: e.matches(":disabled,[aria-disabled=true]"),
        fill: hex(fill), behind: hex(back), edge: show(edge), indeterminate: ind || undefined });
    }
    out.boundaries = cap(res);
  }

  if (want("surfaces")) {
    const card = n => shadowOf(n) || (borderSides(st(n)).length > 0 && rgba(st(n).backgroundColor)[3] > 0);
    const inCard = e => { for (let n = e.parentElement; n && n !== document.body; n = n.parentElement) if (card(n)) return true; return false; };
    const ind = e => complex(st(e)) || pseudoPaint(e) || backdrop(e).indeterminate;
    const bare = NODES.filter(e => { if (stop("surfaces")) return false; const s = st(e), r = rc(e);
      if (!(r.width > 240 && r.height > 48)) return false;
      if (!(borderSides(s).length || (parseFloat(s.borderTopLeftRadius) >= 4 && rgba(s.backgroundColor)[3] > 0))) return false;
      if ((shadowOf(e) && !faded(e)) || !vis(e) || inCard(e)) return false;
      if (ind(e)) return true;
      const back = backdrop(e).c; return ratio(over(rgba(s.backgroundColor), back), back) < 1.1; })
      .map(e => ({ el: ident(e), fill: st(e).backgroundColor, behind: hex(backdrop(e).c), indeterminate: ind(e) || undefined }));
    const surfaced = e => { const s = st(e); return rgba(s.backgroundColor)[3] >= 1 || borderSides(s).length > 0 || shadowOf(e); };
    const blocks = NODES.filter(e => e.matches("section,article,div") && vis(e) && rc(e).width > 240 &&
        e.querySelector(":scope > h1,:scope > h2,:scope > h3,:scope > h4,:scope > header"))
      .map(e => ({ heading: txt(e.querySelector("h1,h2,h3,h4")).slice(0, 40), surfaced: surfaced(e) }));
    out.surfaces = { bare: cap(bare), mixed: blocks.some(b => b.surfaced) && blocks.some(b => !b.surfaced) ? cap(blocks) : [] };
  }

  if (want("repeated")) {
    out.repeated = cap(NODES.filter(l => !stop("repeated") && l.matches("ul,ol,tbody,[role=list],[role=feed]")).map(l => {
      const items = [...l.children].filter(vis); if (items.length < 5) return null;
      const shape = i => txt(i).replace(/\d+/g, "#").slice(0, 60);
      const counts = items.reduce((m, i) => (m[shape(i)] = (m[shape(i)] || 0) + 1, m), {});
      const top = Object.entries(counts).sort((a, b) => b[1] - a[1])[0];
      return top[1] / items.length >= 0.6 ? { list: ident(l), items: items.length, shapes: Object.keys(counts).length, dominant: top[0], share: show(top[1] / items.length) } : null;
    }).filter(Boolean));
  }

  if (want("alignment")) {
    const pairs = [], stacks = [];
    for (const b of NODES) {
      if (stop("alignment")) break;
      const kids = [...b.children].filter(vis);
      const pr = b.matches("dl") ? kids.filter(k => k.matches("dd")).map(dd => [dd.previousElementSibling, dd])
        : kids.filter(k => k.children.length === 2 && [...k.children].every(c => txt(c) && c.children.length <= 1)).map(k => [...k.children]);
      if (pr.length >= 3) {
        const wrapped = pr.map(([l, v]) => !!l && rc(v).top > rc(l).top + 2);
        const mixedWrap = wrapped.some(Boolean) && wrapped.some(w => !w);
        const columnar = b.matches("dl") || st(b).display.includes("grid");
        const lefts = [...new Set(pr.map(([, v]) => Math.round(rc(v).left)))];
        const ls = [...new Set(pr.map(([l]) => l && st(l).fontSize))], vs = [...new Set(pr.map(([, v]) => st(v).fontSize))];
        if (mixedWrap || (columnar && lefts.length > 1) || ls.length > 1 || vs.length > 1)
          pairs.push({ block: ident(b), mixedWrap, valueLefts: lefts, labelSizes: ls, valueSizes: vs });
      }
      const cs = st(b);
      if (cs.display.includes("flex") && cs.flexDirection.startsWith("column")) {
        const bx = kids.filter(c => rc(c).height <= 120 && indep(c) === 1)
          .map(c => c.matches(CTL) ? c : c.querySelector(CTL)).filter(x => x && vis(x) && !x.matches(TINY)).map(x => box(x, b));
        const lefts = [...new Set(bx.map(x => Math.round(rc(x).left)))];
        if (bx.length >= 2 && lefts.length > 1) stacks.push({ stack: ident(b), controlLefts: lefts });
      }
    }
    out.alignment = { pairs: cap(pairs), stacks: cap(stacks) };
  }

  if (want("transport")) {
    const text = R.innerText ?? R.textContent ?? "";
    const esc = s => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const B = "(?<![\\p{L}\\p{N}_])", E = "(?![\\p{L}\\p{N}_])";
    const uniq = m => [...new Set(m || [])].slice(0, CAP);
    const forbidden = (opts.forbidden || []).filter(Boolean);
    out.transport = {
      isoDates: uniq(text.match(/(?<![\d.])\d{4}-\d{2}-\d{2}(?:T[\d:.]+(?:Z|[+-]\d{2}:?\d{2})?)?(?![\d.])/g)),
      machineNumbers: uniq(text.match(/(?<![\d.,])\d+\.(?:\d*0|\d{3,})(?![\d.,])/g)),
      slugs: uniq(text.match(new RegExp(`${B}[a-z]+(?:_[a-z0-9]+)+${E}`, "gu"))),
      forbidden: forbidden.length ? uniq(text.match(new RegExp(`${B}(?:${forbidden.map(esc).join("|")})${E}`, "gu"))) : [],
      lang: document.documentElement.lang || null };
  }

  if (want("mute")) {
    const inputs = NODES.filter(i => i.matches("input,textarea") && vis(i) && i.matches(FIELD));
    out.mute = {
      empty: cap(inputs.filter(i => !i.value && !i.placeholder).map(i => ({ type: i.type || "textarea", label: label(i) }))),
      nativeCandidates: cap(inputs.filter(i => /^(number|date|time|datetime-local|month|week|file|color)$/.test(i.type)).map(i => ({ type: i.type, t: label(i) }))) };
  }

  if (want("navigation")) {
    const here = new URL(location.href), hp = here.pathname.replace(/\/$/, "");
    const links = [...document.querySelectorAll("a[href]")].filter(shown).map(a => { let u;
      try { u = new URL(a.getAttribute("href"), location.href); } catch (e) { return null; }
      if (u.origin !== here.origin || !/^(https?|file):$/.test(u.protocol)) return null;
      return { href: u.pathname + u.search, path: u.pathname.replace(/\/$/, ""), text: label(a), top: Math.round(rc(a).top), inView: inView(a) };
    }).filter(Boolean);
    const up = links.filter(l => l.path !== hp && (l.path === "" || hp.startsWith(l.path + "/")));
    out.navigation = { path: hp, inAppLinks: links.length, waysUp: up.length, aboveTheFold: up.filter(l => l.inView).length,
      examples: up.slice(0, 4).map(({ path, ...l }) => l) };
  }

  if (want("groups")) {
    const unnamed = NODES.filter(e => !stop("groups") && e.matches(NAMED) && vis(e) && !accName(e)).map(e => ({ tag: e.tagName.toLowerCase(), type: e.type || null, el: ident(e) }));
    const cols = [];
    for (const t of NODES.filter(e => e.tagName === "TABLE")) { if (stop("groups")) break;
      const rows = [...t.querySelectorAll("tbody tr")].filter(vis); if (rows.length < 3) continue;
      const heads = [...t.querySelectorAll("thead th")].map(th => txt(th).slice(0, 24));
      for (let c = 0; c < rows[0].children.length; c++) {
        const vals = rows.map(r => txt(r.children[c])).filter(Boolean);
        if (vals.length >= 3 && new Set(vals).size === 1) cols.push({ column: heads[c] || c, rows: vals.length, value: vals[0].slice(0, 24) }); } }
    const detached = NODES.filter(r => !stop("groups") && r.matches("li,tr,[role=row]") && vis(r)).map(r => {
      const icons = [...r.querySelectorAll("button,a[href]")].filter(b => vis(b) && !txt(b)); if (icons.length < 2) return null;
      const lbl = [...r.querySelectorAll("*")].find(n => n.children.length === 0 && txt(n) && !n.closest("button,a")); if (!lbl) return null;
      const g = rc(icons[0]), l = rc(lbl);
      return g.top >= l.bottom - 2 ? { row: label(r), groupTop: Math.round(g.top), labelBottom: Math.round(l.bottom), icons: icons.length } : null;
    }).filter(Boolean);
    out.groups = { unnamed: cap(unnamed), constantColumns: cap(cols), detached: cap(detached) };
  }

  if (want("primaries")) {
    const fills = (opts.primaryFills || []).map(c => hex(rgba(c)));
    const sat = c => { const [r, g, b] = c.slice(0, 3).map(v => v / 255), mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2;
      return { s: mx === mn ? 0 : (mx - mn) / (1 - Math.abs(2 * l - 1)), l }; };
    const hits = [], groups = {};
    for (const e of document.querySelectorAll(CTL)) {
      if (stop("primaries")) break;
      if (!shown(e) || !onPage(e) || e.matches(":disabled,[aria-disabled=true]")) continue;
      const f = rgba(st(e).backgroundColor); if (f[3] < 1) continue;
      const k = hex(f), item = { t: label(e), fill: k, inRoot: R.contains(e), inView: inView(e),
        state: e.matches("[aria-pressed=true],[aria-selected=true],[aria-current]:not([aria-current=false]),[aria-checked=true]") ? "selected" : null };
      if (fills.length) { if (fills.includes(k)) hits.push(item); continue; }
      const { s, l } = sat(f); if (s >= 0.45 && l >= 0.2 && l <= 0.85) (groups[k] = groups[k] || []).push(item);
    }
    out.primaries = fills.length ? { fills, count: hits.length, items: cap(hits) }
      : { heuristic: "saturated opaque fills; pass opts.primaryFills from the project's tokens",
          groups: Object.entries(groups).map(([fill, items]) => ({ fill, count: items.length, items: items.slice(0, 6) })) };
  }

  out.ms = Math.round(performance.now() - t0);
  return out;
}
