# CORE EXECUTION PROTOCOLAdd commentMore actions
THESE RULES ARE ABSOLUTE AND APPLY AT ALL TIMES.

### 1. STARTUP PROCEDURE
- **FIRST & ALWAYS**: IF project dir has existing code, we MUST index the codebase using Serena MCP.
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
- **DEFINE ALL CONSTANTS AT TOP&**: Always define constants for hard coded vars, PLACE THESE AT THE TOP.

### 3A. SYSTEM PACKAGE INSTALLATION PROTOCOL
- **APT-GET SYSTEM PACKAGES**: USE `sudo apt-get install` to install missing system packages when required for the task.
- **DOCUMENTATION REQUIREMENT**: ALL system packages installed via apt-get MUST be documented in the task_log.md under "SYSTEM PACKAGES INSTALLED".

### 3B. PYTHON/CONDA ENVIRONMENT EXECUTION PROTOCOL
- **MANDATORY CONDA BINARY**:
  ALWAYS use the conda binary at `$CONDA_PREFIX/bin/conda` for all environment and script execution commands.

- **SCRIPT EXECUTION FORMAT**:
  ALWAYS execute Python scripts using the following format:
  ```bash
  ${CONDA_EXE:-conda} run --live-stream -n ENVIRONMENT_NAME python -u your_script.py [args]
  /vol/biomedic3/vj724/miniconda3/bin/conda run --live-stream -n ENVIRONMENT_NAME python -u your_script.py [args]
  ```
  - Replace `ENVIRONMENT_NAME` with the target conda environment.
  - Replace `your_script.py [args]` with the script and its arguments.

- **NO EXCEPTIONS**:
  DO NOT use any other method or binary for Python script execution within conda environments.
  DO NOT omit the `--live-stream` or `-u` flags under any circumstances.

### 3C. PYTHON OUTPUT REPRODUCIBILITY

- **ARGUMENT PARSING REQUIREMENT**:  
  All scripts MUST use the `argparse` module for command-line argument handling. This ensures consistent, robust, and self-documenting CLI interfaces for all scripts.

- **MANDATORY OUTPUT DIRECTORY PROTOCOL**:  
  Every PYTHON script that produces an output **MUST** output to a dedicated directory, never directly to a file.  
  - If the script would otherwise output a single file (e.g., a CSV or TXT), it **MUST** be refactored to output a directory containing that file as well as all required reproducibility metadata.
  - The output directory **MUST** contain:
    1. The scripts output.
    2. `timestamp.txt` — the date and time the script was called.
    3. `git_commit_hash.txt` — the current git commit id.
    4. Copies of all config files used for the run.
    5. `reproduce.txt` — the exact command used to run the script, generated using the `create_reproduce_command` function from the shared `sys_utils` module.
  - **Direct file outputs are strictly forbidden.** All outputs must be directories containing both the main result and the reproducibility files.

- **GIT STATE ASSERTION**:  
  Any PYTHON script that creates output **MUST** assert the following before running:
  1. If the input file or directory does **not** contain the keywords `test` or `demo` in its name, the script **MUST NOT** run unless git state is clean.
  2. Use the `check_git_state_clean` function from the shared `sys_utils` module to enforce this. If the check fails, the script must exit with an error.

- **USAGE**:  
  Assume the utility functions are available to be imported from `sys_utils`.  
  **Import and use in your scripts as follows:**
  ```python
  from sys_utils import check_git_state_clean, create_reproduce_command
  
  # Example: Check git state before running assuming test or demo not in input.
  is_clean, details = check_git_state_clean()
  if not is_clean:
      print("Git state is not clean:", details)
      sys.exit(1)
  
  # Example: Create a reproduce.txt file after parsing args
  create_reproduce_command(parser, output_file, dvc_file_path)
  ```

- **ENFORCEMENT**:  
  Scripts must fail loudly and immediately if these requirements are not met.

### 4. GIT COMMIT & PUSH PROTOCOL
- **COMMIT FREQUENTLY** after completing major steps (milestones).
- **ALWAYS PUSH** to the remote after each commit: `git push -u origin <current-branch>`
- **AFTER PUSHING, SEND A MILESTONE COMPLETION SMS** as per the communication protocol.
- **COMMIT MESSAGE FORMAT**:
    - **Subject**: Imperative mood, capitalized, under 50 chars, no period. (e.g., `feat(thing): Add new thing`)
    - **Body**: Explain *what* and *why*, not how. Wrap at 72 chars. For new scripts, ALWAYS include an example usage command.

### 5. LOGGING & COMMUNICATION PROTOCOL
- **`task_log.md`**: UPDATE PROACTIVELY at every single checklist step. This is your primary on-disk communication channel. Create it if it does not exist.
- **COMPREHENSIVE DOCUMENTATION REQUIREMENT**: `task_log.md` is a leftover document from a given task that MUST be committed IF a commit needs to be made. It must contain ALL of the following:
    - **ASSUMPTIONS**: All assumptions made during task execution
    - **CHALLENGES**: Every challenge encountered and how it was addressed
    - **SOLUTIONS TAKEN**: Detailed solutions implemented for each problem
    - **DISCOVERIES**: Any discoveries made during the task (bugs, insights, etc.)
    - **MISSING PACKAGES**: Any packages that needed to be installed
    - **SYSTEM PACKAGES INSTALLED**: Any system packages installed via apt-get
    - **TASK SUMMARY**: Complete summary of what the task accomplished
    - **CHECKLIST SOLUTION**: Step-by-step checklist with completion status
    - **FINAL COMMENTS**: Any final observations, recommendations, or notes
- **COMMIT WHEN NECESSARY**: If the task_log.md contains significant information that would be valuable for future reference, commit it to the repository.
- **SEND USER TEXT AS CHECKLIST ITEM**: ALWAYS add 'Send user text' as an explicit checklist item to assure the user the text will be sent.
- **TWILIO SMS IS THE PRIMARY "CALL-BACK" MECHANISM**:
    - **SEND A TEXT AT THE END OF EVERY CHECKLIST**: A checklist represents a significant task. A text signals that this task is complete and your attention is needed.
    - **WHEN TO SEND**:
        1.  **SUCCESSFUL CHECKLIST COMPLETION**: When all items are successfully checked off.
        2.  **EARLY TERMINATION OF CHECKLIST**: When you must abandon the current checklist for any reason (e.g., you are stuck, the plan is flawed).
    - **MESSAGE CONTENT**: The text MUST contain a brief summary of the outcome (what was achieved or why termination occurred) so you are up-to-speed when you return.
    - **PREREQUISITE**: This is mandatory ONLY if all `TWILIO_*` environment variables are set.
    - **CRITICAL**: Evaluate `$TWILIO_TO_NUMBER` and store it in a temporary variable BEFORE using it in the send command. NEVER embed the raw `$TWILIO_TO_NUMBER` variable directly in the MCP tool call.
    - **MESSAGE DELIVERY VERIFICATION**: After sending ANY SMS, ALWAYS verify delivery status using:
        ```bash
        curl -X GET "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Messages/[MESSAGE_SID].json" -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN"
        ```
        Check the "status" field in the response. If status is "failed", retry with progressively shorter messages:
        1. First retry: "Task complete - [brief outcome]"
        2. Second retry: "Task done - [status]"
        3. Final retry: "Task complete"
        Continue until a message has status "delivered" or "sent".