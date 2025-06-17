# Claude Docker Project Context

This is a containerized Claude Code environment with full autonomous permissions.

## Important Instructions

1. **Context Persistence**: Always check for and use `scratchpad.md` in the project root:
   - Read it at the start of each session to understand project state
   - Update it throughout your work to track progress
   - Use it to maintain context between sessions

2. **Task Completion Notifications**: ALWAYS send SMS when you complete significant work:
   - **When to notify**: After completing any substantial task, debugging session, or reaching a milestone
   - **How to send**: Use `twilio__send_text` command with the message
   - **Message format**: "✅ [PROJECT] | [TASK] | [RESULT]"
   - **Examples**: 
     - "✅ MyApp | Bug fix complete | Fixed login validation issue"
     - "✅ Website | Feature added | User dashboard now responsive"
     - "✅ API | Tests passing | All 15 unit tests now green"

3. **Working Environment**: You have full permissions to:
   - Execute any bash commands
   - Edit/create/delete any files
   - Access web resources
   - Manage the project autonomously

## Available Tools
- **Twilio SMS**: `twilio__send_text` command available for notifications
- **Full Bash Access**: All commands available with --dangerously-skip-permissions
- **Context Persistence**: Use scratchpad.md for session memory
- **Python/Conda**: Custom conda installation mounted (if configured)

## Python/Conda Environment
- When running Python commands or managing conda environments, use the mounted conda binary (if available) or fall back to system `conda`
- ALWAYS use this exact format when running scripts in conda environments:
```bash
${CONDA_EXE:-conda} run --live-stream -n ENVIRONMENT_NAME python -u your_script.py [args]
```
- ALWAYS ensure the --live-stream and -u flags are enabled for real-time output and logs
- Check available environments: `${CONDA_EXE:-conda} env list`
- The conda installation preserves original paths so your existing environments and packages are accessible

## SMS Notification Examples
```
twilio__send_text "✅ Docker Setup | Authentication fixed | Zero-friction login now working"
twilio__send_text "✅ Bug Hunt | Memory leak resolved | App now stable under load"
twilio__send_text "✅ Deployment | Production ready | Tests pass, security reviewed"
```

Remember: You're working in a safe containerized environment, so you can operate with full autonomy.