---
name: journal-status
description: Lists what is left to do in a course of the learn site, from the unchecked items and the "To verify" section of its journal. Use when asked about the progress or the open items of a course.
argument-hint: <course folder, for example duckdb>
allowed-tools: Read Grep
---

Report the open items of the course in `src/content/docs/$ARGUMENTS/`.

1. Read `src/content/docs/$ARGUMENTS/journal.md`. If the file doesn't exist, say so and stop.
2. List every line of the "Progress" section that starts with `- [ ]`, in the order of the file.
3. List the bullets of the "To verify" section, if there is one, shortened to one line each.
4. Answer with two short Markdown lists, "Unchecked" and "To verify", and the number of items in each. Don't edit any file.
