# Concise & Precise

Makes Claude lead with the answer, cut AI tells, and write with controlled-language precision — automatically, in every response.

## What it ships

| Component | Path | What it does |
|---|---|---|
| Output style | `output-styles/concise.md` | The always-on ruleset. Sent with every request while the plugin is enabled. |
| Skill | `skills/concise/SKILL.md` | `/concise` — rewrites existing text against the same rules. Also usable inside subagents. |

The output style sets `force-for-plugin: true`, so it applies as soon as the plugin is enabled, with no need to select it in `/config`. It sets `keep-coding-instructions: true`, so Claude's normal software-engineering behavior stays intact — this changes how Claude writes, not how it works.

## Install

```
/plugin install concise@ky1ejs-plugins
```

Works in the Claude Code CLI and the Desktop app immediately. For [Claude Code on the web](https://code.claude.com/docs/en/claude-code-on-the-web), where `/plugin` is unavailable in cloud sessions, commit the plugin into your repo's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "ky1ejs-plugins": {
      "source": { "source": "github", "repo": "ky1ejs/claude-plugins" }
    }
  },
  "enabledPlugins": { "concise@ky1ejs-plugins": true }
}
```

## The rules

Four groups, 31 rules. See [`output-styles/concise.md`](./output-styles/concise.md) for the full text.

- **Shape** — answer first, no preamble, no recap, no closer, numbered steps, one next action, capped lists.
- **Precision** — one word one meaning, active voice, one instruction per sentence, ~20-word sentences, verbs not nominalizations, plain verbs not phrasal ones, keep modality.
- **Cut** — filler, stacked hedges, marketing adjectives, sycophancy, metaphor nouns, rule-of-three scaffolding, generic conclusions, decoration, idioms.
- **Tone** — matter-of-fact on failure, own errors in one sentence, report honestly.

### Two treatments

**Strict** covers responses, plans, specs, task lists, commit messages, PR descriptions, code comments, identifiers, and error strings.

**Light** covers notes, docs, and READMEs — prose a human reads for its own sake. Precision and Cut still apply in full; Shape and Tone relax so the writing can have a voice. Succinct, with room for character.

### What it will not do

Three guardrails matter more than brevity, and the style states them explicitly:

1. **Brevity governs presentation, not work.** It never shortens analysis, search, verification, or the number of files read.
2. **Some things stay complete.** Error output, stack traces, security findings, destructive-action confirmations, and stated assumptions are never trimmed.
3. **Hedges that carry real uncertainty stay.** Cutting "may have failed" down to "failed" manufactures confidence. That is a false claim, not a shorter one.

Ask to be walked through something and you get a full answer — the shape rules hold, the length cap lifts.

## Rewriting existing text

```
/concise
```

Point it at a response, a file, a spec, or a commit message. It returns the rewritten text alone. Ask for "the diff" or "which rules did it break" and it returns a before/after table instead.

Do not use it on creative or marketing copy. The rules are deliberately flat, and the skill will say so rather than flatten prose that was doing something else.

## Regular Claude chat

The output style reaches Claude Code only — the **Code** tab in Desktop, the CLI, and the web. The **Chat** tab is claude.ai, a separate surface with its own mechanisms.

[`chat/instructions.txt`](./chat/instructions.txt) is a condensed version of the ruleset, 1,725 characters, for **Settings > Instructions for Claude**. That field is account-wide and applies to every conversation automatically, across Desktop, web and mobile, without being selected. It is the closest equivalent to `force-for-plugin`.

Claude.ai has two other personalization surfaces, and neither is always-on:

- **Styles**, picked per chat from the picker under the composer. Useful as an off-switch, since Instructions cannot be toggled per conversation. Build one from [`output-styles/concise.md`](./output-styles/concise.md) — its body works as style text, minus the frontmatter. The two stack: Instructions still apply underneath whichever style is active.
- **Skills**, invoked on demand. Zip [`skills/concise/`](./skills/concise/) and upload it under Settings > Capabilities to get the rewrite workflow in chat.

The condensed text keeps the "brevity governs presentation, not thinking" clause and the never-shorten list, even though they cost characters. In Claude Code the harness reinforces them; in plain chat they are the only thing holding the line, and they are the first clauses a length trim would take.

## Turning it off

Disable the plugin. `force-for-plugin` overrides your `outputStyle` setting while the plugin is on, so the setting alone will not switch it off.

In regular chat, clear the text from Settings > Instructions for Claude.

## Known limit

Output styles apply to the main conversation and to forks, [not to subagents](https://code.claude.com/docs/en/output-styles#how-output-styles-work), which run their own system prompt. Where subagent output matters, invoke the `concise` skill inside the subagent, or list it in the agent's `skills` frontmatter.

## Prior art

Built from three sources:

- [i-have-adhd](https://github.com/ayghri/i-have-adhd) — answer-first shape, one next action, no preamble or closer.
- [unslop](https://github.com/cursor/plugins/blob/main/pstack/skills/unslop/SKILL.md) — the catalogue of AI tells.
- [asd-ste100-skill](https://github.com/danyuchn/asd-ste100-skill) — the controlled-language precision rules, from the aerospace [ASD-STE100](https://www.asd-ste100.org/) standard.
