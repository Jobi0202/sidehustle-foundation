# Master Agent Bootstrap Trigger

Copy this into a new Master Agent (Cowork) session, replace <slug>:

```
Master Agent: bootstrap side-hustle <slug>
Specs liegen in: Product Manager/Ideas/<slug>/
```

Master Agent reads specs, creates repo from template, populates /specs/, sets branch protection, replies with Builder-Prompt + setup checklist.
