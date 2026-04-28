# Multi Skill Review Template

[ROLE]
Agent: ~/.config/aiconfig/agents/{{agent}}.md
Skills: {{skills}}

[TASK]
{{task}}

[CONTEXT]
{{files}}

[OUTPUT]
- Findings (risk: high/medium/low)
- Fix Plan
- Verify Commands

说明：`{{skills}}` 使用逗号分隔，例如 `common/code-review,special/bash-devops`。调用时可展开为多个 `~/.config/aiconfig/skills/<name>.md` 路径。
