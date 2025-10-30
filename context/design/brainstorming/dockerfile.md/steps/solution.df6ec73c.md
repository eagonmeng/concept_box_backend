---
timestamp: 'Wed Oct 29 2025 13:40:04 GMT-0400 (Eastern Daylight Time)'
parent: '[[../20251029_134004.e37ccec0.md]]'
content_id: df6ec73cbf77053e1db0e7f45f39f27b8a94e4011b99c0690307941b2967c319
---

# solution:

You've encountered a classic Docker permission issue. The error `PermissionDenied: Permission denied (os error 13): writefile 'src/concepts/concepts.ts'` is the key clue.

### Root Cause

1. When you use `COPY . .` in a Dockerfile, the files are copied into the image and are owned by the `root` user by default.
2. Your Dockerfile correctly switches to a non-root user (`USER deno`) for enhanced security.
3. The `deno task build` command, running as the `deno` user, tries to write to the `src/concepts/concepts.ts` file.
4. Since that file is owned by `root`, the non-root `deno` user is denied permission to write to it, causing the build to fail.

### The Fix

The solution is to ensure the `deno` user owns the application files. The most efficient way to do this is to change the ownership during the `COPY` instruction using the `--chown` flag.

Here is the updated `Dockerfile`:
