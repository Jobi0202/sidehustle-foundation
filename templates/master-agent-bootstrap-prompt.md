# Master Agent Bootstrap Trigger

Copy this into a new Master Agent (Cowork) session, replace `<slug>` and adjust spec path if non-default:

```
Master Agent: bootstrap side-hustle <slug>
Specs liegen in: Product Manager/Ideas/<slug>/
```

Master Agent's response is exactly one Builder-Prompt (filled-in template). NO GitHub-API calls happen on Master Agent's side.

Jo pastes the Builder-Prompt into Claude Code Desktop. Builder does the rest via `gh` CLI.
