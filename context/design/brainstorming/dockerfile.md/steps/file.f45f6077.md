---
timestamp: 'Wed Oct 29 2025 13:40:04 GMT-0400 (Eastern Daylight Time)'
parent: '[[../20251029_134004.e37ccec0.md]]'
content_id: f45f6077ea9b54c5f5aedbe2d92c08df2bb2c32d9bd03550eb43031920dd7a2c
---

# file: Dockerfile

```dockerfile
# Use a specific version of the official Deno image for reproducibility
FROM denoland/deno:1.42.1

# It's good practice to specify the user. Deno's image provides a non-root 'deno' user.
USER deno

# Set the working directory inside the container
WORKDIR /app

# Expose the port the application will listen on.
# The Requesting concept defaults to PORT 10000.
EXPOSE 10000

# Copy all application files into the working directory.
# CRITICAL FIX: Use --chown to ensure the 'deno' user owns the files.
# This grants the necessary write permissions for the build step.
COPY --chown=deno:deno . .

# Run the custom build step defined in deno.json.
# This step writes to src/concepts/concepts.ts and now has permission to do so.
RUN deno task build

# Cache the main module and all its dependencies.
# This ensures faster startup times for the container as modules are pre-compiled.
RUN deno cache src/main.ts

# Specify the command to run when the container starts.
# Using 'deno task start' is the best practice here, as it encapsulates
# the full run command and necessary permissions from deno.json.
CMD ["deno", "task", "start"]
```

### Explanation of the Change

The only line that has changed is the `COPY` instruction:

**From:**
`COPY . .`

**To:**
`COPY --chown=deno:deno . .`

This flag tells Docker to set the owner and group of all copied files to `deno`. Now, when the `RUN deno task build` command executes as the `deno` user, it has the required permissions to write the `src/concepts/concepts.ts` file, resolving the error.

This approach is preferable to adding an extra `RUN chown -R deno:deno .` command because it doesn't create an additional layer in your Docker image, resulting in a slightly smaller and more efficient build. The rest of the Dockerfile remains correct and follows best practices for a Deno application.
