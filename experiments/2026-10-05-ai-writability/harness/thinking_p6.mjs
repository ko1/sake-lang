// Where P6 solver agents spend output tokens: node thinking_p6.mjs TRANSCRIPT_DIR MAP.tsv
// Per API call: hidden thinking = output tokens (usage) minus the tokens of its visible content (text and
// tool input); visible tool input is further split into code written (Edit/Write, or a heredoc/script that
// writes under code/) and everything else. Visible tokens are counted with @anthropic-ai/tokenizer (Claude 2
// generation; an approximation). Each call is labelled by its action:
//   docs (reads Sake docs), read (reads code/, SPEC.md, change.md, tests), edit (changes code/),
//   probe (writes or runs a scratch Mini program), suite (runs the regression tests), wait (polls or waits for a
//   background harness run: sleep, until, pgrep, ps, Monitor, reading a task output), reply (no tool), other.
// Prints one JSON line per agent: {agent, label: [calls, thinking, code_written, other_visible]}.
import fs from "node:fs";
import { countTokens } from "@anthropic-ai/tokenizer";
const [dir, map] = process.argv.slice(2);
const writesCode = (t, s) => ["Edit", "Write", "MultiEdit"].includes(t.name) && /\/code\//.test(s) ||
  t.name === "Bash" && /\/code\b|code\//.test(s) && /(cat >|<<|python3|sed -i|perl -i|ruby -i)/.test(s) && !/try_mini/.test(s);
const label = (tools) => {
  let l = tools.length ? "other" : "reply";
  for (const t of tools) {
    const s = JSON.stringify(t.input || {});
    if (writesCode(t, s)) return "edit";
    if (/try_mini\.rb\S*\s+\S+\s+--run/.test(s)) l = "probe";
    else if (/try_mini/.test(s)) l = l === "probe" ? l : "suite";
    else if (l !== "other") continue;
    else if (["Monitor", "TaskOutput", "BashOutput"].includes(t.name) || /\bsleep\b|\buntil\b|pgrep|ps -eo|tasks\/\w+\.output/.test(s)) l = "wait";
    else if (/\/scratch\//.test(s)) l = "probe"; // the scratch/ program dir, not the sake-scratch codebase
    else if (/\/docs\b|docs\//.test(s)) l = "docs";
    else if (/\/code\b|code\/|SPEC\.md|change\.md|tests\/|attempt/.test(s)) l = "read";
  }
  return l;
};
for (const line of fs.readFileSync(map, "utf8").trim().split("\n")) {
  const [name, id] = line.split("\t");
  const msgs = new Map();
  for (const l of fs.readFileSync(`${dir}/${id}.output`, "utf8").split("\n")) {
    let m; try { m = JSON.parse(l); } catch { continue; }
    if (m.type !== "assistant" || !m.message?.usage) continue;
    const e = msgs.get(m.message.id) || { out: 0, text: "", code: "", other: "", tools: [] };
    e.out = Math.max(e.out, m.message.usage.output_tokens || 0);
    for (const c of m.message.content || []) {
      if (c.type === "text") e.text += c.text;
      if (c.type === "tool_use") {
        const s = JSON.stringify(c.input);
        if (writesCode(c, s)) e.code += s; else e.other += s;
        e.tools.push(c);
      }
    }
    msgs.set(m.message.id, e);
  }
  const agg = {};
  for (const e of msgs.values()) {
    const code = countTokens(e.code), other = countTokens(e.other) + countTokens(e.text);
    const a = (agg[label(e.tools)] ||= [0, 0, 0, 0]);
    a[0] += 1; a[1] += Math.max(0, e.out - code - other); a[2] += code; a[3] += other;
  }
  console.log(JSON.stringify({ agent: name, ...agg }));
}
