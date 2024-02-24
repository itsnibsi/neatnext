# neatnext

This Bash script automates the setup process for a Next.js project by installing dependencies, configuring ESLint, Prettier, package.json scripts, VSCode settings, and tidying up the project structure.

## Features

- Checks for the presence of required dependencies.
- Detects the currently used package manager (npm, yarn, or pnpm).
- Installs necessary packages based on the detected package manager.
- Configures ESLint with predefined rules for TypeScript and Tailwind CSS.
- Initializes a .prettierrc.json file with specified Prettier settings.
- Configures package.json scripts to enable debugging.
- Configures VSCode settings for ESLint integration.
- Cleans up the Next.js app by removing unnecessary lines and customizing page content.

## Usage

1. Ensure Bash is installed on your system.
2. Copy the script to the root directory of your Next.js project.
3. `chmod +x neatnext.sh; ./neatnext.sh`
4. Profit!

## Prerequisites

- **jq**: Command-line JSON processor. Install it from [jq's official website](https://stedolan.github.io/jq/download/).

## Note

- This script assumes the project structure follows Next.js conventions.
- Ensure you have appropriate permissions to execute the script and modify project files.

## License

This script is provided under the [MIT License](LICENSE).
