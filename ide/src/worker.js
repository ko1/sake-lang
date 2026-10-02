// One Ruby VM running Sake (lib/sake/ide.rb). The page sends the compiled ruby.wasm module, then
// requests; each answer is the JSON Sake::IDE.dispatch returns.
import { DefaultRubyVM } from "@ruby/wasm-wasi/dist/browser";
import { SOURCES, LOADER } from "./sake_sources.gen.js";

let dispatch = null;

self.onmessage = async (e) => {
  const m = e.data;
  if (m.type === "init") {
    try {
      const { vm } = await DefaultRubyVM(m.module, { consolePrint: false });
      vm.eval('require "json"; require "js"');
      vm.eval("->(s) { $sake_sources = JSON.parse(s.to_s) }").call("call", vm.wrap(JSON.stringify(SOURCES)));
      vm.eval(LOADER);
      vm.eval('require_relative "/sake/lib/sake/ide"');
      const fn = vm.eval("->(s) { Sake::IDE.dispatch(s) }");
      dispatch = (req) => fn.call("call", vm.wrap(JSON.stringify(req))).toString();
      postMessage({ type: "ready" });
    } catch (err) {
      postMessage({ type: "fatal", message: String(err && err.message || err) });
    }
  } else if (m.type === "req") {
    let res;
    try {
      res = JSON.parse(dispatch(m.req));
    } catch (err) {
      res = { error: String(err && err.message || err) };
    }
    postMessage({ type: "res", id: m.id, res });
  }
};
