// Where solver agents spend output tokens: node thinking.mjs TRANSCRIPT_DIR MAP.tsv
// Per API call: output tokens (usage) minus the tokens of its visible content (text, tool input) = hidden
// thinking (the transcript keeps thinking blocks without their text). Visible tokens are counted with
// @anthropic-ai/tokenizer (Claude 2 generation; an approximation for the current model).
// Each call is labelled by its action: spec (reading the task), docs (reading Sake docs), write (writing or
// editing solution.*), run (try.rb), other. Prints per run: label -> [calls, thinking, visible].
import fs from "node:fs";
import { countTokens } from "@anthropic-ai/tokenizer";
const [dir, map] = process.argv.slice(2);
const label = (tools) => {
  for (const t of tools) {
    const s = JSON.stringify(t.input || {});
    if (["Write", "Edit"].includes(t.name) || /solution\.(sake|rb)/.test(s) && /cat >|<<|Write/.test(s)) return "write";
    if (/try\.rb/.test(s)) return "run";
    if (/docs\/|cheatsheet/.test(s)) return "docs";
    if (/spec\.md|public\//.test(s)) return "spec";
  }
  return tools.length ? "other" : "answer";
};
for (const line of fs.readFileSync(map, "utf8").trim().split("\n")) {
  const [name, id] = line.split("\t");
  const msgs = new Map();
  for (const l of fs.readFileSync(`${dir}/${id}.output`, "utf8").split("\n")) {
    let m; try { m = JSON.parse(l); } catch { continue; }
    if (m.type !== "assistant" || !m.message?.usage) continue;
    const e = msgs.get(m.message.id) || { out: 0, vis: "", tools: [] };
    e.out = Math.max(e.out, m.message.usage.output_tokens || 0);
    for (const c of m.message.content || []) {
      if (c.type === "text") e.vis += c.text;
      if (c.type === "tool_use") { e.vis += JSON.stringify(c.input); e.tools.push(c); }
    }
    msgs.set(m.message.id, e);
  }
  const agg = {};
  for (const e of msgs.values()) {
    const vis = countTokens(e.vis), k = label(e.tools);
    const a = (agg[k] ||= [0, 0, 0]);
    a[0] += 1; a[1] += Math.max(0, e.out - vis); a[2] += vis;
  }
  console.log(JSON.stringify({ agent: name, ...agg }));
}
