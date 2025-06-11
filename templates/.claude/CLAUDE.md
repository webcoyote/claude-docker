# Claude Docker Project Context

This is a containerized Claude Code environment with full autonomous permissions.

## Important Instructions

1. **Context Persistence**: Always check for and use `scratchpad.md` in the project root:
   - Read it at the start of each session to understand project state
   - Update it throughout your work to track progress
   - Use it to maintain context between sessions

2. **Task Completion Notifications**: When you complete a major task:
   - Send an SMS notification using the Twilio MCP server
   - Format: "✅ Task complete | Task: [brief description] | Done: [what was accomplished]"
   - Keep it concise - just the essentials

3. **Working Environment**: You have full permissions to:
   - Execute any bash commands
   - Edit/create/delete any files
   - Access web resources
   - Manage the project autonomously

## MCP Server Available
- Twilio MCP server is running and available for SMS notifications
- Use natural language to send SMS messages
- Example: "Send SMS to notify that the task is complete"

Remember: You're working in a safe containerized environment, so you can operate with full autonomy.