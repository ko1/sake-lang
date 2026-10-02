// The Sake IDE page: a CodeMirror editor on the left, run output / inferred types / SakeAST on the right.
// Sake itself runs in two Web Workers on ruby.wasm: one analyzes as you type (diagnostics, types, hovers,
// completion of your own names), the other runs the program and can be stopped without losing the first.
import { EditorState, Prec, StateEffect } from "@codemirror/state";
import {
  EditorView, keymap, lineNumbers, highlightActiveLine, highlightActiveLineGutter, drawSelection,
  hoverTooltip, highlightSpecialChars, dropCursor,
} from "@codemirror/view";
import { defaultKeymap, history, historyKeymap, indentWithTab } from "@codemirror/commands";
import { StreamLanguage, syntaxHighlighting, HighlightStyle, indentOnInput, bracketMatching } from "@codemirror/language";
import { ruby } from "@codemirror/legacy-modes/mode/ruby";
import { autocompletion, completionKeymap, closeBrackets, closeBracketsKeymap, startCompletion } from "@codemirror/autocomplete";
import { linter, lintGutter, lintKeymap } from "@codemirror/lint";
import { searchKeymap, highlightSelectionMatches } from "@codemirror/search";
import { tags as t } from "@lezer/highlight";
import { EXAMPLES } from "./examples.gen.js";

const RUN_TIMEOUT_MS = 10000;
const ANALYZE_TIMEOUT_MS = 20000;
const DRAFT_KEY = "sake-ide-draft";
const LEVEL_KEY = "sake-ide-level";
const SPLIT_KEY = "sake-ide-split";

const $ = (sel) => document.querySelector(sel);
const store = {
  get(k) { try { return localStorage.getItem(k); } catch { return null; } },
  set(k, v) { try { localStorage.setItem(k, v); } catch { /* storage may be unavailable */ } },
};

// ---- Ruby workers ----

async function loadRuby(onProgress) {
  const res = await fetch("ruby.gz.wasm");
  if (!res.ok) throw new Error(`could not download Ruby (HTTP ${res.status})`);
  const total = Number(res.headers.get("content-length")) || 10_100_000;
  const reader = res.body.getReader();
  const chunks = [];
  let got = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(value);
    got += value.length;
    onProgress(Math.min(got / total, 1));
  }
  const blob = new Blob(chunks);
  const head = new Uint8Array(await blob.slice(0, 2).arrayBuffer());
  // The host may already have undone the gzip (Content-Encoding); otherwise decompress here.
  const bytes = head[0] === 0x1f && head[1] === 0x8b
    ? await new Response(blob.stream().pipeThrough(new DecompressionStream("gzip"))).arrayBuffer()
    : await blob.arrayBuffer();
  return WebAssembly.compile(bytes);
}

class RubyWorker {
  constructor(module) {
    this.module = module;
    this.seq = 0;
    this.pending = new Map();
    this.start();
  }

  start() {
    this.worker = new Worker("worker.js");
    this.ready = new Promise((resolve, reject) => {
      this.worker.onmessage = (e) => {
        const m = e.data;
        if (m.type === "ready") resolve();
        else if (m.type === "fatal") reject(new Error(m.message));
        else if (m.type === "res") {
          const p = this.pending.get(m.id);
          if (p) { this.pending.delete(m.id); p(m.res); }
        }
      };
      this.worker.onerror = (e) => reject(new Error(e.message || "the Ruby worker failed to start"));
    });
    this.worker.postMessage({ type: "init", module: this.module });
  }

  restart() {
    this.worker.terminate();
    for (const p of this.pending.values()) p({ error: "stopped" });
    this.pending.clear();
    this.start();
  }

  // Resolves with Sake::IDE's answer; on timeout the worker is restarted and { timeout: true } returned.
  async request(req, timeoutMs) {
    await this.ready;
    const id = ++this.seq;
    return new Promise((resolve) => {
      const timer = setTimeout(() => {
        if (!this.pending.has(id)) return;
        this.pending.delete(id);
        this.restart();
        resolve({ timeout: true });
      }, timeoutMs);
      this.pending.set(id, (res) => { clearTimeout(timer); resolve(res); });
      this.worker.postMessage({ type: "req", id, req });
    });
  }
}

let analyzer = null;
let runner = null;
let catalog = null;
let analysis = null; // { doc, res } of the latest finished analysis
let level = Number(store.get(LEVEL_KEY) ?? 1);
if (!(level >= 0 && level <= 4)) level = 1;

// Only the newest analysis matters: a request made while one is running waits and replaces older waiters.
let analyzing = null;
let queued = null;
function analyze(doc) {
  if (!analyzer) return Promise.resolve(null);
  if (analyzing) {
    if (queued) queued.resolve(null);
    return new Promise((resolve) => { queued = { doc, resolve }; });
  }
  analyzing = analyzer.request({ cmd: "analyze", src: doc, level }, ANALYZE_TIMEOUT_MS).then((res) => {
    analyzing = null;
    if (!res.error && !res.timeout) {
      analysis = { doc, res };
      renderTypes(res);
      renderAst(res);
    } else {
      renderAnalysisError(res);
    }
    if (queued) {
      const q = queued;
      queued = null;
      analyze(q.doc).then(q.resolve);
    }
    return res;
  });
  return analyzing;
}

// ---- editor ----

const highlight = HighlightStyle.define([
  { tag: t.keyword, color: "var(--syn-keyword)", fontWeight: "500" },
  { tag: t.tagName, color: "var(--syn-type)", fontWeight: "600" },
  { tag: [t.atom, t.bool], color: "var(--syn-atom)" },
  { tag: t.number, color: "var(--syn-number)" },
  { tag: [t.string, t.special(t.string), t.regexp], color: "var(--syn-string)" },
  { tag: t.comment, color: "var(--syn-comment)", fontStyle: "italic" },
  { tag: [t.definition(t.variableName), t.function(t.variableName)], color: "var(--syn-def)" },
  { tag: t.special(t.variableName), color: "var(--syn-field)" },
  { tag: t.operator, color: "var(--syn-op)" },
]);

const editorTheme = EditorView.theme({
  "&": { height: "100%", backgroundColor: "var(--paper)", color: "var(--ink)" },
  ".cm-scroller": { fontFamily: "var(--mono)", fontSize: "13.5px", lineHeight: "1.6" },
  ".cm-content": { caretColor: "var(--accent)", padding: "10px 0" },
  ".cm-gutters": { backgroundColor: "var(--paper)", color: "var(--ink-faint)", border: "none", paddingRight: "4px" },
  ".cm-activeLine": { backgroundColor: "var(--line-active)" },
  ".cm-activeLineGutter": { backgroundColor: "transparent", color: "var(--ink-soft)" },
  "&.cm-focused .cm-selectionBackground, .cm-selectionBackground, ::selection": { backgroundColor: "var(--selection)" },
  ".cm-cursor": { borderLeftColor: "var(--accent)", borderLeftWidth: "2px" },
  ".cm-tooltip": { backgroundColor: "var(--panel)", color: "var(--ink)", border: "1px solid var(--rule)", borderRadius: "6px", boxShadow: "var(--shadow)" },
  ".cm-tooltip-autocomplete > ul": { fontFamily: "var(--mono)", fontSize: "13px", maxHeight: "18em" },
  ".cm-tooltip-autocomplete > ul > li[aria-selected]": { backgroundColor: "var(--accent)", color: "var(--on-accent)" },
  ".cm-completionDetail": { color: "var(--ink-soft)", fontStyle: "normal", marginLeft: "1em" },
  ".cm-completionInfo": { fontFamily: "var(--mono)", fontSize: "12.5px", padding: "6px 10px", maxWidth: "32em" },
  ".cm-tooltip-lint": { fontFamily: "var(--sans)", fontSize: "13px", maxWidth: "34em" },
  ".cm-diagnostic": { padding: "6px 10px", borderLeftWidth: "4px", whiteSpace: "pre-wrap" },
  ".cm-diagnostic-error": { borderLeftColor: "var(--bad)" },
  ".cm-diagnostic-warning": { borderLeftColor: "var(--warn)" },
  ".cm-lintRange-error": { backgroundImage: "none", textDecoration: "underline wavy var(--bad)", textUnderlineOffset: "3px" },
  ".cm-lintRange-warning": { backgroundImage: "none", textDecoration: "underline wavy var(--warn)", textUnderlineOffset: "3px" },
  ".cm-matchingBracket": { backgroundColor: "var(--line-active)", outline: "1px solid var(--rule)" },
  ".cm-searchMatch": { backgroundColor: "var(--selection)" },
  ".cm-panels": { backgroundColor: "var(--panel)", color: "var(--ink)" },
});

// Completion: after `T.` the operations of T (built-in and your own); after `x.` the type names that
// start a chain `x.T.op`; otherwise variables, functions, types and keywords.
function userTypes() { return analysis?.res?.symbols?.types ?? {}; }

function typeNames() {
  const names = new Set([...Object.keys(catalog?.namespaces ?? {}), ...(catalog?.modules ?? []), ...(catalog?.exceptions ?? []), ...Object.keys(userTypes())]);
  return [...names].sort();
}

function inferredSignature(full) {
  const f = analysis?.res?.functions?.find((x) => x.name === full);
  return f ? `(${f.params.map(([, ty]) => ty).join(", ")}) → ${f.returns}` : null;
}

function opsOf(ns) {
  const out = new Map();
  for (const op of catalog?.namespaces?.[ns] ?? []) {
    if (op.name === "[]") continue; // `T[...]` is the constructor syntax
    out.set(op.name, { label: op.name, type: "function", detail: op.block === "required" ? "{ }" : undefined, info: op.signature, boost: 1 });
  }
  const u = userTypes()[ns];
  if (u) {
    if (u.kind !== "module") out.set("new", { label: "new", type: "function", info: `${ns}.new(${u.fields.join(", ")})`, boost: 3 });
    for (const f of u.fields) {
      out.set(`get_${f}`, { label: `get_${f}`, type: "property", info: `${ns}.get_${f}(x)`, boost: 2 });
      out.set(`set_${f}`, { label: `set_${f}`, type: "property", info: `${ns}.set_${f}(x, v)`, boost: 1 });
    }
    for (const fn of u.functions) {
      const sig = inferredSignature(`${ns}.${fn.name}`);
      out.set(fn.name, { label: fn.name, type: "method", info: `${ns}.${fn.name}(${fn.params.join(", ")})${sig ? `\n${sig}` : ""}`, boost: 4 });
    }
  }
  return [...out.values()];
}

function sakeCompletions(ctx) {
  const word = ctx.matchBefore(/[\w?!]*/);
  const before = ctx.state.sliceDoc(Math.max(0, word.from - 120), word.from);
  const validFor = /^[\w?!]*$/;
  let m;
  if ((m = before.match(/\(\s*([A-Z]\w*(?:\s*\|\s*[A-Z]\w*)+)\s*\)\.$/))) {
    const lists = m[1].split("|").map((s) => opsOf(s.trim()));
    const common = lists[0].filter((o) => lists.every((l) => l.some((x) => x.label === o.label)));
    return { from: word.from, options: common, validFor };
  }
  if ((m = before.match(/(?:^|[^\w])([A-Z]\w*)\.$/))) {
    return { from: word.from, options: opsOf(m[1]), validFor };
  }
  if (/[\w)\]"'?!]\.$/.test(before)) {
    // `x.` continues as a chain `x.T.op(...)`: offer the types, then their operations.
    const options = typeNames().map((n) => ({
      label: n, type: "class", detail: "chain",
      apply: (view, completion, from, to) => {
        view.dispatch({ changes: { from, to, insert: `${n}.` }, selection: { anchor: from + n.length + 1 } });
        startCompletion(view);
      },
    }));
    return { from: word.from, options, validFor };
  }
  if (word.from === word.to && !ctx.explicit) return null;
  if (/^[A-Z]/.test(word.text)) {
    return { from: word.from, options: typeNames().map((n) => ({ label: n, type: "class", detail: userTypes()[n]?.kind })), validFor };
  }
  const syms = analysis?.res?.symbols ?? { functions: [], locals: [] };
  const options = [
    ...(syms.locals ?? []).map((n) => ({ label: n, type: "variable", boost: 3 })),
    ...(syms.functions ?? []).map((f) => ({ label: f.name, type: "function", info: `${f.name}(${f.params.join(", ")})${inferredSignature(f.name) ? `\n${inferredSignature(f.name)}` : ""}`, boost: 2 })),
    ...(catalog?.namespaces?.Kernel ?? []).map((op) => ({ label: op.name, type: "function", info: op.signature })),
    ...(catalog?.keywords ?? []).map((k) => ({ label: k, type: "keyword", boost: -1 })),
  ];
  const seen = new Set();
  return { from: word.from, options: options.filter((o) => !seen.has(o.label) && seen.add(o.label)), validFor };
}

function posOf(doc, line, col) {
  const l = doc.line(Math.min(Math.max(line, 1), doc.lines));
  return Math.min(l.from + Math.max(col, 0), l.to);
}

// Analyze again although the text did not change (Ruby has started, the level changed).
const relint = StateEffect.define();
const refresh = () => view.dispatch({ effects: relint.of(null) });

const sakeLinter = linter(async (view) => {
  const doc = view.state.doc.toString();
  const res = await analyze(doc);
  if (!res || res.error || res.timeout || view.state.doc.toString() !== doc) return [];
  return res.diagnostics.map((d) => {
    const from = posOf(view.state.doc, d.line, d.col);
    const line = view.state.doc.lineAt(from);
    const rest = view.state.sliceDoc(from, line.to).match(/^[@$]?[\w?!]+/);
    const to = rest ? from + rest[0].length : Math.min(from + 1, line.to);
    const hints = d.hints?.length ? `\n${d.hints.map((h) => `hint: ${h}`).join("\n")}` : "";
    const where = d.severity === "warning" ? `\n(reported from level ${d.level}; the level now is ${level})` : "";
    return { from, to: Math.max(to, from), severity: d.severity, message: `${d.message}${hints}${where}` };
  });
}, { delay: 350, needsRefresh: (u) => u.transactions.some((tr) => tr.effects.some((e) => e.is(relint))) });

const typeHover = hoverTooltip((view, pos) => {
  if (!analysis || analysis.doc !== view.state.doc.toString()) return null;
  const doc = view.state.doc;
  let best = null;
  for (const h of analysis.res.hovers) {
    const from = posOf(doc, h.from[0], h.from[1]);
    const to = posOf(doc, h.to[0], h.to[1]);
    if (pos >= from && pos <= to && (!best || to - from < best.to - best.from)) best = { from, to, text: h.type };
  }
  // A def line: the function's inferred signature.
  const line = doc.lineAt(pos);
  const def = line.text.match(/^(\s*def\s+)(?:self\.)?([\w?!]+)/);
  if (def) {
    const nameFrom = line.from + def[0].length - def[2].length;
    if (pos >= nameFrom && pos <= line.from + def[0].length) {
      const f = analysis.res.functions.find((x) => x.line === line.number);
      if (f) best = { from: nameFrom, to: line.from + def[0].length, text: `${f.name}(${f.params.map(([n, ty]) => `${n}: ${ty}`).join(", ")}) → ${f.returns}` };
    }
  }
  if (!best) return null;
  return {
    pos: best.from, end: best.to, above: true,
    create() {
      const dom = document.createElement("div");
      dom.className = "type-tip";
      dom.textContent = best.text;
      return { dom };
    },
  };
}, { hoverTime: 250 });

function draftSaver() {
  let timer = null;
  return EditorView.updateListener.of((u) => {
    if (!u.docChanged) return;
    clearTimeout(timer);
    timer = setTimeout(() => store.set(DRAFT_KEY, u.state.doc.toString()), 400);
  });
}

const initialDoc = store.get(DRAFT_KEY) ?? EXAMPLES.find((e) => e.name === "types")?.source ?? "puts(\"Hello, Sake!\")\n";

const view = new EditorView({
  parent: $("#editor"),
  state: EditorState.create({
    doc: initialDoc,
    extensions: [
      lineNumbers(), highlightActiveLineGutter(), highlightSpecialChars(), history(), drawSelection(), dropCursor(),
      indentOnInput(), bracketMatching(), closeBrackets(), highlightActiveLine(), highlightSelectionMatches(),
      StreamLanguage.define(ruby), syntaxHighlighting(highlight), editorTheme, EditorView.lineWrapping,
      autocompletion({ override: [sakeCompletions], activateOnTyping: true, icons: true }),
      sakeLinter, lintGutter(), typeHover, draftSaver(),
      Prec.highest(keymap.of([{ key: "Mod-Enter", run: () => { runProgram(); return true; } }])),
      keymap.of([...closeBracketsKeymap, ...defaultKeymap, ...searchKeymap, ...historyKeymap, ...completionKeymap, ...lintKeymap, indentWithTab]),
      EditorState.tabSize.of(2),
    ],
  }),
});

function jumpTo(line, col = 0) {
  const pos = posOf(view.state.doc, line, col);
  view.dispatch({ selection: { anchor: pos }, effects: EditorView.scrollIntoView(pos, { y: "center" }) });
  view.focus();
}

// ---- result pane ----

function el(tag, attrs = {}, ...kids) {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (k === "class") e.className = v;
    else if (k.startsWith("on")) e.addEventListener(k.slice(2), v);
    else e.setAttribute(k, v);
  }
  for (const k of kids.flat()) if (k != null) e.append(k.nodeType ? k : String(k));
  return e;
}

// `main.sake:12:` in a message becomes a link to line 12.
function linkLines(text) {
  const frag = document.createDocumentFragment();
  let last = 0;
  for (const m of text.matchAll(/main\.sake:(\d+)(?::(\d+))?/g)) {
    frag.append(text.slice(last, m.index));
    frag.append(el("button", { class: "line-link", type: "button", onclick: () => jumpTo(Number(m[1]), m[2] ? Number(m[2]) - 1 : 0) }, m[0]));
    last = m.index + m[0].length;
  }
  frag.append(text.slice(last));
  return frag;
}

function selectTab(name) {
  for (const b of document.querySelectorAll("[role=tab]")) {
    const on = b.dataset.tab === name;
    b.setAttribute("aria-selected", on);
    $(`#panel-${b.dataset.tab}`).hidden = !on;
  }
  store.set("sake-ide-tab", name);
}

async function runProgram() {
  if (!runner) return;
  selectTab("output");
  const src = view.state.doc.toString();
  const out = $("#run-output");
  const status = $("#run-status");
  out.replaceChildren(el("p", { class: "muted" }, "Running…"));
  status.className = "pill running";
  status.textContent = "running";
  $("#run").disabled = true;
  $("#stop").hidden = false;
  const t0 = performance.now();
  const res = await runner.request({ cmd: "run", src, level, stdin: $("#stdin").value }, RUN_TIMEOUT_MS);
  const ms = Math.round(performance.now() - t0);
  $("#run").disabled = false;
  $("#stop").hidden = true;
  out.replaceChildren();
  if (res.timeout || res.error === "stopped") {
    status.className = "pill bad";
    status.textContent = res.timeout ? "stopped · timeout" : "stopped";
    out.append(el("p", { class: "note" }, res.timeout
      ? `The program ran longer than ${RUN_TIMEOUT_MS / 1000} s and was stopped; Ruby was restarted.`
      : "Stopped; Ruby was restarted."));
    return;
  }
  if (res.error) {
    status.className = "pill bad";
    status.textContent = "internal error";
    out.append(el("pre", { class: "stderr" }, res.error, "\n", (res.backtrace || []).join("\n")));
    return;
  }
  const labels = { 0: "ok", 1: "runtime error", 2: "rejected before running" };
  status.className = `pill ${res.status === 0 ? "good" : "bad"}`;
  status.textContent = `exit ${res.status} · ${labels[res.status] ?? ""} · ${ms} ms`;
  if (res.stdout) out.append(el("pre", { class: "stdout" }, res.stdout));
  if (res.stderr) out.append(el("pre", { class: "stderr" }, linkLines(res.stderr)));
  if (!res.stdout && !res.stderr) out.append(el("p", { class: "muted" }, "(no output)"));
}

function renderAnalysisError(res) {
  $("#types").replaceChildren(el("p", { class: "note" }, res.timeout ? "The analysis took too long and was stopped." : `Internal error in the analysis: ${res.error}`));
}

function problemList(diags) {
  if (!diags.length) return el("p", { class: "ok-line" }, `No problems at level ${level}.`);
  const sorted = [...diags].sort((a, b) => (a.severity === b.severity ? a.line - b.line : a.severity === "error" ? -1 : 1));
  return el("ul", { class: "problems" }, sorted.map((d) => el("li", { class: d.severity },
    el("button", { class: "line-link", type: "button", onclick: () => jumpTo(d.line, d.col) }, `${d.line}:${d.col + 1}`),
    el("span", { class: "msg" }, d.message.replace(/ \[[\w-]+\]$/, "")),
    el("span", { class: "item" }, d.severity === "warning" ? `level ${d.level}` : (d.message.match(/\[([\w-]+)\]$/)?.[1] ?? "static")),
  )));
}

function typeText(ty) {
  return el("code", { class: `ty${/\bnil\b/.test(ty) ? " nilable" : ""}${ty.includes("|") ? " union" : ""}` }, ty);
}

function renderTypes(res) {
  const root = $("#types");
  const errors = res.diagnostics.filter((d) => d.severity === "error");
  const warnings = res.diagnostics.filter((d) => d.severity === "warning");
  const parts = [];
  parts.push(el("section", {}, el("h3", {}, "Problems", el("span", { class: "count" }, `${errors.length} at level ${level}`, warnings.length ? ` · ${warnings.length} above` : "")), problemList(res.diagnostics)));
  if (!res.ast) {
    parts.push(el("p", { class: "muted" }, "Types appear once the program has no static errors."));
    root.replaceChildren(...parts);
    return;
  }
  const s = res.summary || {};
  parts.push(el("section", {}, el("h3", {}, "Run-time checks the typer looked at"),
    el("div", { class: "chips" },
      el("span", { class: "chip good" }, `${s.proven ?? 0} proven`),
      el("span", { class: "chip warn" }, `${s.partial ?? 0} may fail`),
      el("span", { class: "chip bad" }, `${s.error ?? 0} fail`),
      el("span", { class: "chip" }, `${s.unknown ?? 0} unknown`))));
  if (res.functions.length) {
    parts.push(el("section", {}, el("h3", {}, "Functions"),
      el("div", { class: "table-wrap" }, el("table", {},
        el("thead", {}, el("tr", {}, el("th", {}, "function"), el("th", {}, "parameters"), el("th", {}, "returns"))),
        el("tbody", {}, res.functions.map((f) => el("tr", {},
          el("td", {}, el("button", { class: "line-link fn", type: "button", onclick: () => jumpTo(f.line) }, f.name)),
          el("td", {}, f.params.length ? f.params.map(([n, ty], i) => el("span", { class: "param" }, i ? ", " : "", `${n}: `, typeText(ty))) : el("span", { class: "muted" }, "—")),
          el("td", {}, typeText(f.returns)))))))));
  }
  if (res.fields.length) {
    parts.push(el("section", {}, el("h3", {}, "Struct fields"),
      el("div", { class: "table-wrap" }, el("table", {},
        el("tbody", {}, res.fields.map((f) => el("tr", {}, el("td", {}, el("code", {}, `${f.type}.${f.field}`)), el("td", {}, typeText(f.inferred)))))))));
  }
  if (res.arrays.length) {
    parts.push(el("section", {}, el("h3", {}, "Arrays", el("span", { class: "count" }, "by the line that makes them")),
      el("div", { class: "table-wrap" }, el("table", {},
        el("tbody", {}, res.arrays.map((a) => el("tr", {}, el("td", {}, el("code", {}, a.label)), el("td", {}, typeText(a.elem)))))))));
  }
  parts.push(el("p", { class: "muted small" }, "Hover over a name in the editor to see its inferred type."));
  root.replaceChildren(...parts);
}

function renderAst(res) {
  $("#ast").textContent = res.ast ?? "(no SakeAST: the program has static errors)";
}

// ---- controls ----

const LEVELS = [
  ["0", "syntax, names, arguments"],
  ["1", "+ type, rescue"],
  ["2", "+ nil (recommended)"],
  ["3", "+ index-nil, exhaustive"],
  ["4", "+ unrescued"],
];
const levelSel = $("#level");
for (const [v, label] of LEVELS) levelSel.append(el("option", { value: v }, `Level ${v} · ${label}`));
levelSel.value = String(level);
levelSel.addEventListener("change", () => {
  level = Number(levelSel.value);
  store.set(LEVEL_KEY, String(level));
  refresh();
});

const exampleSel = $("#example");
exampleSel.append(el("option", { value: "" }, "Open an example…"));
for (const ex of EXAMPLES) exampleSel.append(el("option", { value: ex.name }, `${ex.name}.sake`));
exampleSel.addEventListener("change", () => {
  const ex = EXAMPLES.find((e) => e.name === exampleSel.value);
  exampleSel.value = "";
  if (!ex) return;
  view.dispatch({ changes: { from: 0, to: view.state.doc.length, insert: ex.source }, selection: { anchor: 0 } });
  view.focus();
});

for (const b of document.querySelectorAll("[role=tab]")) b.addEventListener("click", () => selectTab(b.dataset.tab));
selectTab(store.get("sake-ide-tab") ?? "output");
$("#run").addEventListener("click", runProgram);
$("#stop").addEventListener("click", () => runner?.restart());

// The divider between the panes: drag to resize (columns side by side, rows when narrow).
const split = $("#split");
const workspace = $("#workspace");
const savedSplit = Number(store.get(SPLIT_KEY));
if (savedSplit > 15 && savedSplit < 85) workspace.style.setProperty("--split", `${savedSplit}%`);
split.addEventListener("pointerdown", (e) => {
  split.setPointerCapture(e.pointerId);
  const rect = workspace.getBoundingClientRect();
  const vertical = getComputedStyle(workspace).gridTemplateRows.split(" ").length > 1 && window.matchMedia("(max-width: 820px)").matches;
  const move = (ev) => {
    const frac = vertical ? (ev.clientY - rect.top) / rect.height : (ev.clientX - rect.left) / rect.width;
    const pct = Math.min(80, Math.max(20, frac * 100));
    workspace.style.setProperty("--split", `${pct}%`);
    store.set(SPLIT_KEY, String(Math.round(pct)));
  };
  const up = () => { split.removeEventListener("pointermove", move); split.removeEventListener("pointerup", up); };
  split.addEventListener("pointermove", move);
  split.addEventListener("pointerup", up);
});
split.addEventListener("keydown", (e) => {
  if (!["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown"].includes(e.key)) return;
  const cur = parseFloat(getComputedStyle(workspace).getPropertyValue("--split")) || 52;
  const pct = Math.min(80, Math.max(20, cur + (e.key === "ArrowLeft" || e.key === "ArrowUp" ? -4 : 4)));
  workspace.style.setProperty("--split", `${pct}%`);
  store.set(SPLIT_KEY, String(pct));
  e.preventDefault();
});

// ---- boot ----

(async () => {
  const boot = $("#boot");
  const bar = $("#boot-bar");
  const label = $("#boot-label");
  try {
    const module = await loadRuby((f) => { bar.style.width = `${(f * 100).toFixed(1)}%`; label.textContent = `Downloading Ruby 4.0 (ruby.wasm, 10 MB) · ${Math.round(f * 100)}%`; });
    label.textContent = "Starting Ruby and loading Sake…";
    analyzer = new RubyWorker(module);
    runner = new RubyWorker(module);
    await analyzer.ready;
    catalog = await analyzer.request({ cmd: "catalog" }, ANALYZE_TIMEOUT_MS);
    boot.hidden = true;
    $("#run").disabled = false;
    $("#engine").textContent = "Ruby 4.0 · ruby.wasm";
    refresh();
    await runner.ready;
  } catch (err) {
    label.textContent = `Ruby could not start: ${err.message}`;
    boot.classList.add("failed");
  }
})();
