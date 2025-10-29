---
timestamp: 'Wed Oct 29 2025 12:53:14 GMT-0400 (Eastern Daylight Time)'
parent: '[[../20251029_125314.63750356.md]]'
content_id: b7a17059e951bc4cb8eb69e5d58f705d6629a33649d4c36223b4267a38b03029
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
# The default is 10000 according to the Requesting concept's configuration.
EXPOSE 10000

# Copy all application files into the working directory.
# This includes the 'src', 'deno.json', and any other necessary files.
COPY . .

# Run the custom build step defined in deno.json.
# This is a critical step that generates necessary import files (e.g., @concepts).
# The 'deno task' command will use the permissions defined in deno.json.
RUN deno task build

# Cache the main module and all its dependencies.
# This ensures faster startup times for the container as modules are pre-compiled.
RUN deno cache src/main.ts

# Specify the command to run when the container starts.
# Using 'deno task start' is the best practice here, as it encapsulates
# the full run command and necessary permissions from deno.json.
CMD ["deno", "task", "start"]
```

### Explanation of Key Decisions

1. **Base Image (`FROM denoland/deno:1.42.1`)**: We use a specific version tag instead of `latest`. This ensures that your builds are reproducible and won't break unexpectedly when a new version of Deno is released.
2. **User (`USER deno`)**: The official Deno Docker image provides a non-root user named `deno`. Running as a non-root user is a critical security best practice for containers.
3. **Build Step (`RUN deno task build`)**: Your `deno.json` defines a crucial `build` task that runs `src/utils/generate_imports.ts`. This script appears to scan your `src/concepts` directory to create the `@concepts` import alias. This step must be run before caching or running the application, and this Dockerfile ensures it is.
4. **Caching (`RUN deno cache src/main.ts`)**: After the build step has created the necessary files, this command downloads and compiles `src/main.ts` and all of its dependencies. This significantly speeds up the actual application startup time when the container is run.
5. **Runtime Command (`CMD ["deno", "task", "start"]`)**: Instead of hardcoding the `deno run` command from the documentation, we use `deno task start`. This is more maintainable because the source of truth for how to run the application remains in your `deno.json` file. It also correctly applies all the necessary permissions (`--allow-net`, `--allow-env`, etc.) without needing to repeat them in the Dockerfile.
6. **Environment Variables**: Your application configuration (like database connection strings) should be managed via environment variables, not hardcoded. You can pass them to the container during runtime using the `-e` or `--env-file` flag with `docker run`. For example:
   ```bash
   docker run -p 10000:10000 --env-file ./.env my-concept-app
   ```
