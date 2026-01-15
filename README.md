# Ralph - Autonomous Coding Agent

Ralph is an autonomous coding agent that implements features from PRDs (Product Requirements Documents) using iterative AI-powered development. It works through user stories one at a time, committing progress, and learning from each iteration. This specific implementation uses the Claude Code CLI.

## Quick Start

Clone Ralph into your project's `.ralph` directory and initialize:

```bash
git clone https://github.com/uesteibar/ralph-starter-kit.git .ralph && .ralph/init.sh
```

This will:
- Remove the starter-kit's `.git` directory (so Ralph becomes part of your project)
- Add `.ralph` to your project's `.gitignore`
- Print setup instructions

## How Ralph Works

### The Big Picture

Ralph is designed for **autonomous, iterative development**. You describe what you want built in a PRD, and Ralph works through it story by story:

1. **You create a PRD** - Either through a guided conversation (`create_prd.sh`) or by converting existing requirements (`convert_prd.sh`)
2. **Ralph picks up the next story** - It reads `prd.json`, finds the highest-priority incomplete story
3. **Ralph implements it** - Makes changes, runs quality checks, commits if passing
4. **Ralph learns** - Records patterns and gotchas in `progress.txt` for future iterations
5. **Repeat** - Each iteration is a fresh context window, but learnings persist

### Worktrees

Ralph uses **git worktrees** to work in isolation without affecting your main branch:

- When you run `ralph.sh`, it creates a worktree at `.ralph/.worktrees/<branch-name>`
- The branch name comes from `prd.json` (e.g., `ralph/my-feature`)
- All work happens in this worktree, keeping your main branch clean
- When done, Ralph opens a PR for you to review

This means you can continue working on `main` while Ralph works on features in parallel.

### Task Archival

When you start a new feature (different `branchName` in `prd.json`), Ralph automatically archives the previous run:

```
archive/
  2024-01-15-ralph-previous-feature/
    prd.json
    progress.txt
```

This preserves the history of what Ralph worked on and learned.

### Progress Tracking

Ralph maintains two types of progress information:

1. **`progress.txt`** - Detailed log of each iteration:
   - What was implemented
   - Files changed
   - Learnings for future iterations

2. **Codebase Patterns** - Reusable patterns discovered during work, consolidated at the top of `progress.txt`:
   ```
   ## Codebase Patterns
   - Use `sql<number>` template for aggregations
   - Always run migrations with `IF NOT EXISTS`
   ```

Each new Ralph iteration reads these patterns first, so it learns from previous work.

## Usage

All commands are run from **your project root** (not from inside `.ralph/`). This allows Claude to see and work with your entire codebase.

### Step 1: Create a PRD

**Option A: Guided conversation**

```bash
.ralph/create_prd.sh
```

This starts an interactive session where Claude helps you define requirements, asks clarifying questions, and generates a structured PRD in `.ralph/tasks/prd-<feature-name>.md`.

**Option B: Convert existing requirements**

If you already have requirements written down:

```bash
.ralph/convert_prd.sh .ralph/tasks/my-requirements.md
```

This converts your markdown file to the `prd.json` format Ralph uses.

### Step 2: Review the PRD

Before running Ralph, review `.ralph/prd.json`:

- Are stories small enough? (Each should be completable in one iteration)
- Are they ordered correctly? (Dependencies first: schema → backend → UI)
- Are acceptance criteria verifiable? (Not vague like "works correctly")

Adjust as needed.

### Step 3: Run Ralph

```bash
.ralph/ralph.sh <number-of-iterations>
```

For example, `.ralph/ralph.sh 10` runs up to 10 iterations.

Ralph will:
1. Create a worktree for the feature branch
2. Work through stories one at a time
3. Commit each completed story
4. Stop when all stories pass or iterations are exhausted
5. Open a PR when complete

### Step 4: Clean Up

After merging (or abandoning) a feature:

```bash
.ralph/ralph.sh cleanup
```

This removes all Ralph worktrees.

## Customization

### CLAUDE.md

This file contains the instructions Ralph follows. Customize it to:

- Add project-specific quality checks (lint, test, typecheck commands)
- Define commit message conventions
- Specify browser testing requirements
- Add any project-specific rules

### create_prd.prompt

This defines how Claude conducts the PRD creation conversation. Customize it to:

- Add your team's PRD template preferences
- Include project-specific sections
- Define your acceptance criteria standards

### convert_prd.prompt

This controls how existing documents are converted to `prd.json`. Customize it to:

- Adjust story sizing rules
- Change priority ordering logic
- Add project-specific fields

## Directory Structure

```
.ralph/
├── CLAUDE.md           # Agent instructions
├── README.md           # This file
├── init.sh             # Initialization script
├── ralph.sh            # Main runner script
├── create_prd.sh       # PRD creation conversation
├── convert_prd.sh      # PRD conversion utility
├── create_prd.prompt   # PRD creation template
├── convert_prd.prompt  # PRD conversion template
├── prd.json            # Current PRD (gitignored)
├── progress.txt        # Progress log (gitignored)
├── tasks/              # PRD markdown files
├── archive/            # Archived runs
└── .worktrees/         # Git worktrees (gitignored)
```

## Tips

- **Start small**: Begin with a 3-5 story PRD to get familiar with Ralph
- **Write verifiable criteria**: "Button shows confirmation dialog" not "Good UX"
- **Order by dependency**: Schema changes before UI that uses them
- **Check progress.txt**: Review learnings before running more iterations
- **Use cleanup**: Remove worktrees when done to save disk space

## Troubleshooting

**Ralph keeps failing on a story**
- The story might be too large. Split it into smaller pieces.
- Check `progress.txt` for error messages and learnings.

**Worktree creation fails**
- The branch might already be checked out elsewhere.
- Run `./ralph.sh cleanup` and try again.

**Quality checks fail**
- Ensure your project's lint/test/typecheck commands are discoverable.
- Add them explicitly to `CLAUDE.md` if needed.

# A Ralph

```
⠀⠀⠀⠀⠀⠀⣀⣤⣶⡶⢛⠟⡿⠻⢻⢿⢶⢦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢀⣠⡾⡫⢊⠌⡐⢡⠊⢰⠁⡎⠘⡄⢢⠙⡛⡷⢤⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢠⢪⢋⡞⢠⠃⡜⠀⠎⠀⠉⠀⠃⠀⠃⠀⠃⠙⠘⠊⢻⠦⠀⠀⠀⠀⠀⠀
⠀⠀⢇⡇⡜⠀⠜⠀⠁⠀⢀⠔⠉⠉⠑⠄⠀⠀⡰⠊⠉⠑⡄⡇⠀⠀⠀⠀⠀⠀
⠀⠀⡸⠧⠄⠀⠀⠀⠀⠀⠘⡀⠾⠀⠀⣸⠀⠀⢧⠀⠛⠀⠌⡇⠀⠀⠀⠀⠀⠀
⠀⠘⡇⠀⠀⠀⠀⠀⠀⠀⠀⠙⠒⠒⠚⠁⠈⠉⠲⡍⠒⠈⠀⡇⠀⠀⠀⠀⠀⠀
⠀⠀⠈⠲⣆⠀⠀⠀⠀⠀⠀⠀⠀⣠⠖⠉⡹⠤⠶⠁⠀⠀⠀⠈⢦⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠈⣦⡀⠀⠀⠀⠀⠧⣴⠁⠀⠘⠓⢲⣄⣀⣀⣀⡤⠔⠃⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣜⠀⠈⠓⠦⢄⣀⣀⣸⠀⠀⠀⠀⠁⢈⢇⣼⡁⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢠⠒⠛⠲⣄⠀⠀⠀⣠⠏⠀⠉⠲⣤⠀⢸⠋⢻⣤⡛⣄⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢡⠀⠀⠀⠀⠉⢲⠾⠁⠀⠀⠀⠀⠈⢳⡾⣤⠟⠁⠹⣿⢆⠀⠀⠀⠀⠀⠀
⠀⢀⠼⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠃⠀⠀⠀⠀⠀⠈⣧⠀⠀⠀⠀⠀
⠀⡏⠀⠘⢦⡀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠞⠁⠀⠀⠀⠀⠀⠀⠀⢸⣧⠀⠀⠀⠀
⢰⣄⠀⠀⠀⠉⠳⠦⣤⣤⡤⠴⠖⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢯⣆⠀⠀⠀
⢸⣉⠉⠓⠲⢦⣤⣄⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣠⣼⢹⡄⠀⠀
⠘⡍⠙⠒⠶⢤⣄⣈⣉⡉⠉⠙⠛⠛⠛⠛⠛⠛⢻⠉⠉⠉⢙⣏⣁⣸⠇⡇⠀⠀
⠀⢣⠀⠀⠀⠀⠀⠀⠉⠉⠉⠙⠛⠛⠛⠛⠛⠛⠛⠒⠒⠒⠋⠉⠀⠸⠚⢇⠀⠀
⠀⠀⢧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠇⢤⣨⠇⠀
⠀⠀⠀⢧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⢻⡀⣸⠀⠀⠀
⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⠛⠉⠁⠀⠀⠀
⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⢠⢄⣀⣤⠤⠴⠒⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠘⡆⠀⠀⠀⠀⠀
⠀⠀⠀⡎⠀⠀⠀⠀⠀⠀⠀⠀⢷⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀
⠀⠀⢀⡷⢤⣤⣀⣀⣀⣀⣠⠤⠾⣤⣀⡘⠛⠶⠶⠶⠶⠖⠒⠋⠙⠓⠲⢤⣀⠀
⠀⠀⠘⠧⣀⡀⠈⠉⠉⠁⠀⠀⠀⠀⠈⠙⠳⣤⣄⣀⣀⣀⠀⠀⠀⠀⠀⢀⣈⡇
⠀⠀⠀⠀⠀⠉⠛⠲⠤⠤⢤⣤⣄⣀⣀⣀⣀⡸⠇⠀⠀⠀⠉⠉⠉⠉⠉⠉⠁⠀
```
