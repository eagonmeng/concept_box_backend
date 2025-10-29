FROM denoland/deno:2.5.5

# It's good practice to specify the user. Deno's image provides a non-root 'deno' user.
USER deno

# Set the working directory inside the container
WORKDIR /app

# Expose the port the application will listen on.
# The default is 8000 according to the Requesting concept's configuration.
EXPOSE 8000

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