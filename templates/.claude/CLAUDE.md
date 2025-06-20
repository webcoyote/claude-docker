# CORE EXECUTION PROTOCOL
THESE RULES ARE ABSOLUTE AND APPLY AT ALL TIMES.

### 1. STARTUP PROCEDURE
- **FIRST & ALWAYS**: Index the codebase using Serena MCP.
  `uvx --from git+https://github.com/oraios/serena index-project`

### 2. TASK & PLAN ADHERENCE
WHEN OUTSIDE PLAN MODE ADHERE TO THE FOLLOWING PRINCIPLES:
- **NEVER SIMPLIFY THE GOAL**: DO NOT MODIFY, REDUCE, OR SIMPLIFY THE TASK TO MAKE IT ACHIEVABLE. IF THE TASK AS SPECIFIED IS IMPOSSIBLE, YOU MUST TERMINATE.
- **EARLY TERMINATION** is ALWAYS preferable to a flawed or deviated implementation.

### 3. CODING & SCRIPTING MANDATE
- **SIMPLICITY IS LAW**: MAXIMIZE READABILITY WHILE MINIMIZING FUNCTIONS AND CONDITIONAL LOGIC.
- **NO ERROR HANDLING**: DO NOT USE try/except OR ANY FORM OF ERROR SUPPRESSION. Scripts MUST fail loudly and immediately.
- **NO FALLBACKS OR ALTERNATIVE PATHS**.
- **NO EDGE CASE HANDLING**: UNLESS USER PROMPTS FOR IT.
- **RELATIVE PATHS ONLY**: NEVER use absolute paths in code.
- **SURGICAL EDITS**: Change the absolute minimum amount of code necessary to achieve the goal.
- **SKELETON FIRST**: Create a minimal, working script first. Refine ONLY after the skeleton is proven to work.
- **USE `dotenv`** to load `.env` files when required.
- **EARLY TERMINATION** is ALWAYS preferable to a flawed or deviated implementation.
-

### 4. GIT COMMIT & PUSH PROTOCOL
- **COMMIT FREQUENTLY** after completing major steps (milestones).
- **ALWAYS PUSH** to the remote after each commit: `git push -u origin <current-branch>`
- **AFTER PUSHING, SEND A MILESTONE COMPLETION SMS** as per the communication protocol.
- **COMMIT MESSAGE FORMAT**:
    - **Subject**: Imperative mood, capitalized, under 50 chars, no period. (e.g., `feat(thing): Add new thing`)
    - **Body**: Explain *what* and *why*, not how. Wrap at 72 chars. For new scripts, ALWAYS include an example usage command.

### 5. LOGGING & COMMUNICATION PROTOCOL
- **`task_log.md`**: UPDATE PROACTIVELY at every single checklist step. This is your primary on-disk communication channel. Create it if it does not exist.
- **TWILIO SMS IS THE PRIMARY ALERT MECHANISM**:
    - **SEND A TEXT** upon:
        1.  **MILESTONE COMPLETION**: Immediately after each successful `git push`.
        2.  **TASK COMPLETION**: When the entire task is finished.
        3.  **EARLY TERMINATION / HELP NEEDED**: When you are stuck or must terminate.
    - **PREREQUISITE**: This is mandatory ONLY if all `TWILIO_*` environment variables are set. If they are not set, you cannot send texts, but you MUST still follow all other rules.
    - **CRITICAL**: Evaluate `$TWILIO_TO_NUMBER` and store it in a temporary variable BEFORE using it in the send command. NEVER embed the raw `$TWILIO_TO_NUMBER` variable directly in the MCP tool call.

