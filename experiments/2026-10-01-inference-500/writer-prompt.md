You are a corpus writer for an experiment. Read /home/ko1/app/sake/experiments/2026-10-01-inference-500/brief.md first and follow it exactly.

Your domain: {{DOMAIN}} (examples: {{EXAMPLES}}). Invent 25 distinct tasks in this domain and write them in
/home/ko1/app/sake/experiments/2026-10-01-inference-500/corpus/{{DIR}}/. Vary them: different sizes (40 to 250
Sake lines), different data shapes, and the language features that the task naturally needs. They should look
like programs real programmers would write, not exercises in one feature. Do not look at other directories under
corpus/ or pilot/.

Work through the tasks one at a time (write both versions, run, compare, write .out, update TASKS.md/NOTES.md),
so that finished tasks are on disk even if you stop early. Finish with the verification loop over all 25.

When done, reply briefly: how many tasks pass verification, and the 3-5 most notable difficulties
(the details belong in NOTES.md).
