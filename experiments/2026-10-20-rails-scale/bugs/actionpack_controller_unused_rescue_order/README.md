# unused-rescue depends on the order the begin bodies are analyzed

`bin/sake -c --strict c2.sake` (from this directory) warns twice:

    c2.sake:83:3: warning: rescue AbstractController::Error: the begin body raises no exception type that includes AbstractController::Error (AbstractController::DoubleRenderError) [unused-rescue]
    c2.sake:92:3: warning: ... (the same, for t5's begin)

Both bodies do raise DoubleRenderError when run (`/twice` renders twice; the program prints it). In
controller_base.sake (the test, without t5) only line 83 warns. The same `begin ActionDispatch::App.call(set, req)
rescue AbstractController::Error` written in functions that are *called after* the first top-level `request(...)`
call does not warn (tried 8 variants: direct calls, RouteSet.call, Router.serve, App.call, the same helper body).
So the raise set of the call chain (RouteSet -> Journey::Router -> Dispatcher -> generated ControllerSet.dispatch
-> controller process_action -> render -> raise DoubleRenderError.build) seems incomplete the first time it is
computed, before some function in the chain has finished its own analysis. Ruby: no warning concept; the rescue
is reached. Found by part 8 (ActionController); worked around in the test with a bare `rescue => e`.
