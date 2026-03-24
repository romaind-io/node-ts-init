#!/bin/bash
set -e

trap 'printf "\e[?25h"; exit' INT TERM EXIT
printf "\e[?25l"

BLUE="\033[1;34m"
DEFAULT="\033[0m"
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
CHECKMARK="${GREEN}✔${DEFAULT}"
SPINNER="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

run_task() {
    local desc=$1
    shift
    local cmd="$@"
    local EL="\033[K"
    printf " %-40b │ %-15b" "$desc" "${YELLOW}Waiting...${DEFAULT}"
    bash -c "$cmd" &> /dev/null &
    local pid=$!
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r %-40b │ %-15b${EL}" "$desc" "${YELLOW}${SPINNER:$i:1} Working...${DEFAULT}"
        sleep 0.1
    done
    wait $pid
    if [ $? -eq 0 ]; then
        printf "\r %-40b │ %-15b${EL}\n" "$desc" "${CHECKMARK}${GREEN} Done${DEFAULT}"
    else
        printf "\r %-40b │ %-15b${EL}\n" "$desc" "${RED}Failed${DEFAULT}"
        exit 1
    fi
}

SCRIPT_PATH=$(realpath "$0")

clear
echo -e "${BLUE}Initializing Node-TS Project in place${DEFAULT}\n"
printf " %-40s | %-15s\n" "Action" "Status"
echo "——————————————————————————————————————————+————————————————"

run_task "Setup VSCode configuration" "mkdir -p .vscode && \
cat <<EOF > .vscode/extensions.json
{
    \"recommendations\": [
        \"dbaeumer.vscode-eslint\",
        \"esbenp.prettier-vscode\",
        \"ms-vscode.vscode-typescript-next\"
    ]
}
EOF
cat <<EOF > .vscode/settings.json
{
    \"editor.codeActionsOnSave\": {
        \"source.fixAll.eslint\": \"explicit\",
        \"source.fixAll.prettier\": \"explicit\",
        \"source.organizeImports\": \"explicit\",
        \"source.removeUnusedImports\": \"explicit\",
        \"source.sort.json\": \"explicit\"
    },
    \"editor.defaultFormatter\": \"esbenp.prettier-vscode\",
    \"editor.detectIndentation\": false,
    \"editor.formatOnSave\": true,
    \"editor.rulers\": [80]
}
EOF"

run_task "Creating .env file" "touch .env"

run_task "Setup Prettier configuration" "cat <<EOF > .prettierignore
build
node_modules
.env
package-lock.json
EOF
cat <<EOF > .prettierrc
{
    \"arrowParens\": \"always\",
    \"bracketSpacing\":true,
    \"objectWrap\": \"preserve\",
    \"printWidth\": 80,
    \"proseWrap\": \"preserve\",
    \"semi\": true,
    \"singleQuote\": true,
    \"tabWidth\": 2,
    \"trailingComma\": \"none\",
    \"useTabs\": false
}
EOF"

run_task "Setup ESLint configuration" "cat <<EOF > eslint.config.mjs
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
export default tseslint.config(
    eslint.configs.recommended,
    ...tseslint.configs.recommended,
);
EOF"

run_task "Setup Typescript configuration" "cat <<EOF > tsconfig.json
{
    \"compilerOptions\": {
        \"module\": \"nodenext\",
        \"moduleResolution\": \"nodenext\",
        \"target\": \"esnext\",
        \"rootDir\": \"src\",
        \"outDir\": \"build\",
        \"strict\": true,
        \"esModuleInterop\": true,
        \"skipLibCheck\": true
    },
    \"include\": [\"src/**/*.ts\"]
}
EOF"

run_task "Setup Vitest configuration" "cat <<EOF > vitest.config.mjs
import { defineConfig } from 'vitest/config'
export default defineConfig({ test: {} })
EOF"

run_task "Creating source folder" "mkdir -p src && touch src/main.ts"

run_task "Get Node version (.nvmrc)" "node -v | cut -d'.' -f1 > .nvmrc"

run_task "Setup package.json" "cat <<EOF > package.json
{
    \"type\": \"module\",
    \"scripts\": {
        \"build\": \"tsc\",
        \"start\": \"node build/main.js\",
        \"test\": \"vitest\"
    }
}
EOF"

run_task "Resolving dependencies (npm)" "npm i -D @eslint/js @types/node eslint prettier tsx typescript typescript-eslint vitest"

run_task "Setup Git repository" "git init -q"

echo -e "\n${GREEN}Project has been initialized!${DEFAULT}\n"
echo -e "Auto-destruction of the init file!\n"

rm -- "$SCRIPT_PATH"