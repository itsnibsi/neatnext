#!/bin/bash

command_is_installed() {
  local command_name="$1"
  local command_path=$(command -v "$command_name")
  if [ -z "$command_path" ]; then
    return 1
  fi
}

check_dependencies() {
  if ! command_is_installed jq; then
    echo "Error: jq is not installed. Visit https://stedolan.github.io/jq/download/ for installation instructions."
    return 1
  fi
}

detect_package_manager() {
  if [ -f "package-lock.json" ]; then
    echo "npm"
  elif [ -f "yarn.lock" ]; then
    echo "yarn"
  elif [ -f "pnpm-lock.yaml" ]; then
    echo "pnpm"
  else
    echo "unknown"
  fi
}

current_package_manager=$(detect_package_manager)

install_packages() {
  dependencies=( "@typescript-eslint/parser" "@typescript-eslint/eslint-plugin" "eslint-config-prettier" "eslint-plugin-prettier" "eslint-plugin-tailwindcss" "@tailwindcss/forms" )

  case $current_package_manager in
    "npm")
      npm install --save-dev "${dependencies[@]}"
      ;;
    "yarn")
      yarn add --dev "${dependencies[@]}"
      ;;
    "pnpm")
      pnpm add -D "${dependencies[@]}"
      ;;
  esac
}

# Path variables
configure_eslint() {
  local eslintrc_path=".eslintrc.json"
  if [ -e "$eslintrc_path" ]
  then
    jq '.extends = ["next/core-web-vitals", "plugin:tailwindcss/recommended", "prettier"] |
    .overrides = [{
      "files": ["*.ts", "*.tsx", "*.js"],
      "parser": "@typescript-eslint/parser"
    }] |
    .plugins = ["@typescript-eslint", "prettier"] |
    .rules = {
      "no-unused-vars": "off",
      "@typescript-eslint/no-unused-vars": ["error", {"argsIgnorePattern": "^_"}],
      "import/order": ["warn", {
        "groups": [["builtin", "external"], "internal", "parent", ["sibling", "index"], "object"],
        "newlines-between": "always",
        "alphabetize": {"order": "asc", "caseInsensitive": true}
      }],
      "@typescript-eslint/explicit-module-boundary-types": "off",
      "@typescript-eslint/no-non-null-assertion": "off",
      "@typescript-eslint/no-inferrable-types": "off",
      "prettier/prettier": ["error", {
        "singleQuote": true,
        "trailingComma": "all",
        "printWidth": 120,
        "tabWidth": 2,
        "semi": false,
        "arrowParens": "avoid",
        "bracketSpacing": true,
        "endOfLine": "auto",
        "useTabs": false,
        "jsxBracketSameLine": true,
        "jsxSingleQuote": true,
        "quoteProps": "as-needed"
      }],
      "tailwindcss/enforces-shorthand": "error",
      "react/jsx-sort-props": ["error"]
    } |
    .settings = {
      "tailwindcss": {"callees": ["cn"]}
    }
  ' "$eslintrc_path" > "$eslintrc_path.tmp"
  mv "$eslintrc_path.tmp" "$eslintrc_path"
  else
    echo "Error: $eslintrc_path does not exist."
    return 1
  fi
}

# Initialize a .prettierrc.json file with some json object
configure_prettier() {
  local prettierrc_path=".prettierrc.json"
  local prettierrc_json='{
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 120,
  "tabWidth": 2,
  "semi": false,
  "arrowParens": "avoid",
  "bracketSpacing": true,
  "endOfLine": "auto",
  "useTabs": false,
  "jsxBracketSameLine": true,
  "jsxSingleQuote": true,
  "quoteProps": "as-needed"
}'

  if [ -e "$prettierrc_path" ]
  then
    jq --argjson new_config "$prettierrc_json" '. + $new_config' "$prettierrc_path" > "$prettierrc_path.tmp"
    mv "$prettierrc_path.tmp" "$prettierrc_path"
  else
    echo "Error: Couldn't configure prettier."
    return 1
  fi
}

configure_package() {
  local package_path="package.json"
  if [ -e "$package_path" ]; then
    jq '.scripts.dev = "NODE_OPTIONS='"'"'--inspect'"'"' " + .scripts.dev' "$package_path" > "$package_path.tmp"
    mv "$package_path.tmp" "$package_path"
  else
    echo "Error: $package_path does not exist."
    exit 1
  fi
}

configure_vscode() {
  local vscode_settings_path=".vscode/settings.json"
  mkdir -p "$(dirname "$vscode_settings_path")"

  if [ -e "$vscode_settings_path" ]; then
    jq '.["eslint.validate"] = ["javascript", "javascriptreact", "typescript", "typescriptreact"] |
    .["eslint.format.enable"] = true |
    .["editor.codeActionsOnSave"]["source.fixAll.eslint"] = "always" |
    .["[typescript]"]["editor.defaultFormatter"] = "dbaeumer.vscode-eslint" |
    .["[typescriptreact]"]["editor.defaultFormatter"] = "dbaeumer.vscode-eslint"' "$vscode_settings_path" > "$vscode_settings_path.tmp"
    mv "$vscode_settings_path.tmp" "$vscode_settings_path"
  else
    cat > "$vscode_settings_path" <<EOF
{
  "eslint.validate": [
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact"
  ],
  "eslint.format.enable": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "always"
  },
  "[typescript]": {
    "editor.defaultFormatter": "dbaeumer.vscode-eslint"
  },
  "[typescriptreact]": {
    "editor.defaultFormatter": "dbaeumer.vscode-eslint"
  }
}
EOF
  fi
}

tidy_nextjs_app() {
  local dir_name=$(basename "$PWD")

  sed -i '4,$ d' app/globals.css
  sed -i "s/title: .*/title: { default: '$dir_name', template: '%s | $dir_name' },/" app/layout.tsx
  sed -i "s/description: .*/description: '$dir_name',/" app/layout.tsx
  cat > app/page.tsx <<EOF
export default function Page() {
  return <h1>${dir_name}</h1>
}
EOF
}

# Main execution starts here
if check_dependencies; then
  configure_package
  install_packages
  configure_eslint
  configure_prettier
  configure_vscode
  tidy_nextjs_app
fi
