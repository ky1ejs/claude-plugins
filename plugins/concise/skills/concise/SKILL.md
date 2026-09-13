---
name: concise
description: "Rewrite text so it leads with the answer, carries no AI tells, and cannot be misread. Use when asked to make something more concise, tighten, trim, punch up, de-slop, or remove AI-sounding writing from a response, spec, plan, commit message, PR description, README, doc, or code comment. Also use inside a subagent to check your own output before returning it, since the plugin's always-on output style does not reach subagents. Not for creative or marketing copy."
---

# Concise & Precise

The full ruleset lives in `${CLAUDE_PLUGIN_ROOT}/output-styles/concise.md`. Read it before any careful rewrite. This file is the procedure.

While the `concise` plugin is enabled, those rules already apply to the main conversation through the output style. This skill exists for three cases:

1. Rewriting text that already exists — the user's, or your own earlier output.
2. Running inside a subagent, where the output style does not apply. Check your final response against the scan below before returning it.
3. Auditing a file — a README, a spec, a set of code comments — rule by rule.

## Pick the treatment first

**Strict** — responses, plans, specs, task lists, commit messages, PR descriptions, code comments, identifiers, log lines, error strings. Every rule applies.

**Light** — notes, docs, READMEs, and other prose a human reads for its own sake. Precision and Cut apply in full. Shape and Tone relax: a paragraph may set up an idea before delivering it, and the writing may have a voice. Still no filler, no marketing adjectives, no slop.

If the text type is ambiguous, ask which, or state the choice in one line and proceed.

## Scan

Six mechanical tells. Each is a word or mark you can point at, no judgment call. Scan for all six before rewriting anything.

1. **Synonym rotation** — one thing wearing several names ("the user", "the caller", "the client"). The reader cannot tell whether that is one thing or three. Pick one name.
2. **Stacked hedges** — "it is important to note that this may potentially help to improve". State the claim or delete it.
3. **Nominalization** — an action frozen into a noun: "perform an analysis of", "provides assistance to". Use the verb.
4. **Marketing adjectives** — seamless, robust, powerful, comprehensive. Delete, or replace with the measurement that earns the claim.
5. **Run-ons** — several ideas joined by semicolons or em dashes. One idea per sentence.
6. **Soft phrasal verbs** — spin up, reach out, dive into, kick off. Use the plain verb.

Then the structural pass: is the answer in the first line, is the voice active, is any sentence over ~20 words, is anything bolded that is not the one thing that matters, does it open with a preamble or close with an offer to help.

## Rewrite

1. Read the whole text once for meaning. Do not start cutting before you know what it must still say afterwards.
2. Go sentence by sentence. Flag each violation.
3. Rewrite each flagged sentence, preserving the meaning exactly.
4. **Check modality before committing to any cut.** Hedges carry the author's confidence, and confidence is content. A shorter sentence that promotes "may have failed" to "failed" is a different claim, not a tighter one. This is the most common way a well-meant rewrite goes wrong, because hedges are exactly what a length cap tempts you to cut.
5. **Never add a fact the source did not state.** A rewrite that reads better because it supplied a cause, a frequency, or a number has stopped being a rewrite.
6. If a cut would lose real precision — a safety condition, a scope qualifier, a number — keep the longer phrasing and say so rather than simplifying it away silently.
7. If the text already complies, say so. Do not force changes onto clean text.

## Output

Default: **the rewritten text, and nothing else.** No preamble, no violation count, no summary of what changed, no offer to explain. The caller usually wants something they can paste.

One permitted addition: if step 6 kept a longer phrasing on purpose, add a single line afterwards, prefixed `Kept as-is:`, naming the phrase and the precision that would have been lost. Omit the line when there is nothing to report.

**On request** — "show the diff", "which rules did it break", "explain the changes", "before and after" — output a table instead:

| Rule | Original | Rewritten |
|---|---|---|
| Nominalization | "perform an analysis of the log" | "analyze the log" |
| Passive voice | "the column is dropped" | "the migration drops the column" |

Follow it with one line on anything you deliberately left alone, and why.

## Do not apply this to

Creative writing, marketing copy, or anything where voice, nuance, or persuasion is the point. The rules are deliberately flat. Say so and stop rather than flattening prose that was doing something else.
