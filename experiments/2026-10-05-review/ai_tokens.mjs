// AI tokenizer counts of the Sake and Ruby versions (whole files, comments included, as a model reads them).
// usage: node ai_tokens.mjs CORPUS_DIR   (needs, in NODE_PATH or a node_modules nearby:
//   @anthropic-ai/tokenizer (Anthropic's public tokenizer of the Claude 2 generation; current Claude
//   models use a different, unpublished one) and js-tiktoken (OpenAI's o200k_base and cl100k_base))
import fs from "node:fs";
import path from "node:path";
import { countTokens } from "@anthropic-ai/tokenizer";
import { getEncoding } from "js-tiktoken";

const dir = process.argv[2];
const o200 = getEncoding("o200k_base"), cl100 = getEncoding("cl100k_base");
const strip = (src) => src.split("\n").filter((l) => !l.trim().startsWith("#") && l.trim() !== "").join("\n");
const sum = { sake: {}, ruby: {} };
const per = [];
for (const d of fs.readdirSync(dir).sort()) {
  const sub = path.join(dir, d);
  if (!fs.statSync(sub).isDirectory()) continue;
  for (const f of fs.readdirSync(sub).filter((f) => f.endsWith(".sake")).sort()) {
    const rb = path.join(sub, f.replace(/\.sake$/, ".rb"));
    if (!fs.existsSync(rb)) continue;
    const row = {};
    for (const [lang, file] of [["sake", path.join(sub, f)], ["ruby", rb]]) {
      const full = fs.readFileSync(file, "utf8");
      const code = strip(full);
      const c = { claude2: countTokens(code), o200k: o200.encode(code).length, cl100k: cl100.encode(code).length, claude2_full: countTokens(full) };
      for (const [k, v] of Object.entries(c)) sum[lang][k] = (sum[lang][k] || 0) + v;
      row[lang] = c;
    }
    per.push(row.sake.o200k / row.ruby.o200k);
  }
}
per.sort((a, b) => a - b);
const q = (p) => per[Math.floor(p * (per.length - 1))].toFixed(2);
console.log(`## AI tokens: ${dir} (${per.length} programs)\n`);
console.log("| tokenizer | Sake | Ruby | Sake / Ruby |\n|---|---|---|---|");
for (const [k, label] of [["claude2", "Anthropic tokenizer (Claude 2 generation), code only"], ["claude2_full", "same, whole file with comments"],
  ["o200k", "o200k_base (GPT-4o), code only"], ["cl100k", "cl100k_base (GPT-4), code only"]]) {
  console.log(`| ${label} | ${sum.sake[k]} | ${sum.ruby[k]} | ${(sum.sake[k] / sum.ruby[k]).toFixed(3)} |`);
}
console.log(`\nPer program, Sake / Ruby (o200k_base): min ${q(0)}, quartiles ${q(0.25)} / ${q(0.5)} / ${q(0.75)}, max ${q(1)}`);
