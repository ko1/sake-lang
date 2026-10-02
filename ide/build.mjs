// Builds the IDE into dist/: index.html, app.js (the page), worker.js (Ruby and Sake), ruby.gz.wasm.
// usage: npm run build   (in ide/; npm install first)
import { build } from "esbuild";
import fs from "node:fs/promises";
import path from "node:path";
import zlib from "node:zlib";

const here = path.dirname(new URL(import.meta.url).pathname);
const root = path.resolve(here, "..");
const dist = path.join(here, "dist");
await fs.mkdir(dist, { recursive: true });

// Sake's Ruby sources, keyed by the absolute path the loader resolves require_relative to.
const lib = path.join(root, "lib");
const sources = { "/sake/lib/sake.rb": await fs.readFile(path.join(lib, "sake.rb"), "utf8") };
for (const f of (await fs.readdir(path.join(lib, "sake"))).filter((f) => f.endsWith(".rb")).sort()) {
  sources[`/sake/lib/sake/${f}`] = await fs.readFile(path.join(lib, "sake", f), "utf8");
}
const loader = await fs.readFile(path.join(here, "src/sake_loader.rb"), "utf8");
await fs.writeFile(path.join(here, "src/sake_sources.gen.js"),
  `export const SOURCES = ${JSON.stringify(sources)};\nexport const LOADER = ${JSON.stringify(loader)};\n`);

// The example programs of docs/examples, with their first comment line as a description.
const exDir = path.join(root, "docs/examples");
const examples = [];
for (const f of (await fs.readdir(exDir)).filter((f) => f.endsWith(".sake")).sort()) {
  examples.push({ name: f.replace(/\.sake$/, ""), source: await fs.readFile(path.join(exDir, f), "utf8") });
}
await fs.writeFile(path.join(here, "src/examples.gen.js"), `export const EXAMPLES = ${JSON.stringify(examples)};\n`);

const common = { bundle: true, minify: true, format: "iife", target: "es2022", logLevel: "warning", legalComments: "none" };
await build({ ...common, entryPoints: [path.join(here, "src/main.js")], outfile: path.join(dist, "app.js") });
await build({ ...common, entryPoints: [path.join(here, "src/worker.js")], outfile: path.join(dist, "worker.js") });
await fs.copyFile(path.join(here, "src/index.html"), path.join(dist, "index.html"));

const wasm = path.join(here, "node_modules/@ruby/4.0-wasm-wasi/dist/ruby+stdlib.wasm");
// gzip bytes under a .wasm name: the page decompresses them (hosts serve .wasm, not .gz).
const gz = path.join(dist, "ruby.gz.wasm");
const fresh = await fs.stat(gz).then((g) => fs.stat(wasm).then((w) => g.mtimeMs > w.mtimeMs), () => false);
if (!fresh) await fs.writeFile(gz, zlib.gzipSync(await fs.readFile(wasm), { level: 9 }));

for (const f of await fs.readdir(dist)) console.log(`${f}\t${((await fs.stat(path.join(dist, f))).size / 1024).toFixed(0)} KiB`);
