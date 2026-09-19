#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)

cat <<'BANNER'
+---------------------------------------+
|          CODEX ORCHESTRATOR           |
|       Plan with Sol High.             |
|       Execute with Luna Max.          |
|       Review with Luna Max.           |
+---------------------------------------+
BANNER
printf '%s\n' 'Interactive setup'

confirm() {
    prompt=$1
    default_yes=$2
    if [ "$default_yes" = yes ]; then
        suffix='[Y/n]'
    else
        suffix='[y/N]'
    fi

    while :; do
        printf '%s %s ' "$prompt" "$suffix"
        if ! IFS= read -r answer; then
            printf '\nSetup cancelled: input ended before setup was complete.\n' >&2
            exit 1
        fi

        case "$answer" in
            y|Y|yes|YES|Yes) return 0 ;;
            n|N|no|NO|No) return 1 ;;
            '') [ "$default_yes" = yes ] && return 0 || return 1 ;;
            *) printf '%s\n' 'Please answer yes or no.' ;;
        esac
    done
}

overwrite_paths() {
    source_path=$1
    destination_path=$2
    component_name=$(basename "$source_path")

    if [ -f "$source_path" ]; then
        if [ -e "$destination_path" ] || [ -L "$destination_path" ]; then
            printf '%s\n' "$component_name"
        else
            return
        fi
        return
    fi

    find "$source_path" -type f -print | while IFS= read -r source_file; do
        relative_path=${source_file#"$source_path"/}
        destination_file=$destination_path/$relative_path
        if [ -e "$destination_file" ] || [ -L "$destination_file" ]; then
            printf '%s\n' "$component_name/$relative_path"
        fi
    done
}

print_overwrites() {
    source_path=$1
    destination_path=$2

    overwrite_list=$(overwrite_paths "$source_path" "$destination_path")
    if [ -z "$overwrite_list" ]; then
        return
    fi

    printf '%s\n' 'WARNING: the following existing files will be overwritten:'
    printf '%s\n' "$overwrite_list" | sed 's/^/  - /'
}

merge_conflicts() {
    source_path=$1
    destination_path=$2

    find "$source_path" -type f -print | while IFS= read -r source_file; do
        relative_path=${source_file#"$source_path"/}
        destination_file=$destination_path/$relative_path
        if { [ -e "$destination_file" ] || [ -L "$destination_file" ]; } && [ ! -f "$destination_file" ]; then
            printf '%s\n' "$relative_path"
        fi
    done

    find "$source_path" -type d -print | while IFS= read -r source_directory; do
        if [ "$source_directory" = "$source_path" ]; then
            continue
        fi
        relative_path=${source_directory#"$source_path"/}
        destination_directory=$destination_path/$relative_path
        if { [ -e "$destination_directory" ] || [ -L "$destination_directory" ]; } && [ ! -d "$destination_directory" ]; then
            printf '%s\n' "$relative_path"
        fi
    done
}

select_scope() {
    printf '%s\n' 'Installation scope'
    printf '%s\n' '  1) Global (recommended) - applies to every Codex project for this user'
    printf '%s\n' '  2) Project - installs only into one repository'
    while :; do
        printf '%s' 'Select scope [1-2] (default 1): '
        IFS= read -r answer || { printf '\nSetup cancelled: input ended before setup was complete.\n' >&2; exit 1; }
        case "$answer" in
            1|global|GLOBAL|Global|'') scope=global; return ;;
            2|project|PROJECT|Project) scope=project; return ;;
            *) printf '%s\n' 'Please enter 1 (global) or 2 (project).' ;;
        esac
    done
}

select_plan() {
    printf '%s\n' 'Choose Profile to install'
    # Keep the original profiles first for existing numeric selections.
    printf '%s\n' '  1) Pro (4 subagents) - GPT-5.6 Sol (high) orchestrates; GPT-5.6 Luna (max) executes and reviews'
    printf '%s\n' '  2) Plus (compatibility alias, 4 subagents) - GPT-5.6 Sol (high) orchestrates; GPT-5.6 Luna (max) executes and reviews'
    printf '%s\n' '  3) Pro (max 2 subagents) - GPT-5.6 Sol (high) orchestrates; GPT-5.6 Luna (max) executes and reviews'
    printf '%s\n' '  4) Plus (compatibility alias, max 2 subagents) - GPT-5.6 Sol (high) orchestrates; GPT-5.6 Luna (max) executes and reviews'

    while :; do
        printf '%s' 'Select plan [1-4] (default 1): '
        if ! IFS= read -r answer; then
            printf '\nSetup cancelled: input ended before setup was complete.\n' >&2
            exit 1
        fi

        case "$answer" in
            1|pro|PRO|Pro|'') plan=pro; return ;;
            2|plus|PLUS|Plus) plan=plus; return ;;
            3|pro-max-2-subagents) plan=pro-max-2-subagents; return ;;
            4|plus-max-2-subagents) plan=plus-max-2-subagents; return ;;
            *) printf '%s\n' 'Please enter a listed plan number or name.' ;;
        esac
    done
}

copy_component() {
    name=$1
    source_path=${2:-$script_dir/$name}
    destination_path=$target_dir/$name
    component_installed=no

    if [ ! -e "$source_path" ]; then
        printf 'Error: setup source is missing: %s\n' "$source_path" >&2
        exit 1
    fi

    if [ -e "$destination_path" ] || [ -L "$destination_path" ]; then
        if [ "$name" = AGENTS.md ]; then
            if [ -L "$destination_path" ] || [ ! -f "$destination_path" ]; then
                printf 'Skipped %s: target must be a regular file, not a symbolic link.\n' "$name" >&2
                return 0
            fi
            instructions=$(cat "$source_path")
            existing_instructions=$(cat "$destination_path")
            case "$existing_instructions" in
                *"$instructions"*)
                    printf 'Skipped %s: instructions already present.\n' "$name"
                    return 0
                    ;;
            esac
            printf '\n\n' >> "$destination_path"
            cat "$source_path" >> "$destination_path"
            printf 'Appended instructions to %s. Existing contents preserved.\n' "$name"
            component_installed=yes
            return 0
        fi
        if [ ! -L "$destination_path" ] && [ -d "$source_path" ] && [ -d "$destination_path" ]; then
            linked_path=$(find "$destination_path" -type l -print -quit)
            if [ -n "$linked_path" ]; then
                printf 'Skipped %s: the existing target contains a symbolic link (%s).\n' \
                    "$name" "$linked_path" >&2
                return 0
            fi
            conflict_list=$(merge_conflicts "$source_path" "$destination_path")
            if [ -n "$conflict_list" ]; then
                printf 'Skipped %s: source and target types conflict at:\n' "$name" >&2
                printf '%s\n' "$conflict_list" | sed 's/^/  /' >&2
                return 0
            fi
        elif [ ! -L "$destination_path" ] && {
            { [ -d "$source_path" ] && [ ! -d "$destination_path" ]; } ||
            { [ -f "$source_path" ] && [ ! -f "$destination_path" ]; };
        }; then
            printf 'Skipped %s: source and target types are incompatible.\n' "$name" >&2
            return 0
        fi

        if [ -L "$destination_path" ]; then
            printf '%s\n' 'WARNING: the following symbolic link will be replaced:'
            printf '  - %s\n' "$name"
        else
            print_overwrites "$source_path" "$destination_path"
        fi
        if ! confirm "Update $name? New files will be added; only paths listed above will be replaced." no; then
            printf 'Skipped %s (existing target left unchanged).\n' "$name"
            return 0
        fi

        if [ -L "$destination_path" ]; then
            rm "$destination_path"
            cp -R "$source_path" "$destination_path"
        elif [ -d "$source_path" ] && [ -d "$destination_path" ]; then
            cp -R "$source_path"/. "$destination_path"/
        elif [ -f "$source_path" ] && [ -f "$destination_path" ]; then
            cp "$source_path" "$destination_path"
        fi
        printf 'Updated %s.\n' "$name"
    else
        cp -R "$source_path" "$destination_path"
        printf 'Installed %s.\n' "$name"
    fi
    component_installed=yes
}

merge_global_config() {
    source_config=$1
    destination_config=$2
    if [ ! -f "$destination_config" ]; then
        cp "$source_config" "$destination_config"
        return
    fi
    cp "$destination_config" "$destination_config.bak"
    limit=4
    grep -Eq 'max_concurrent_threads_per_session[[:space:]]*=[[:space:]]*2' "$source_config" && limit=2
    tmp_file=$destination_config.tmp.$
    awk -v limit="$limit" '
        BEGIN { section=""; agents_found=0; a_enabled=0; a_limit=0; a_model=0; a_effort=0 }
        function emit_missing_agents() {
            if (!a_enabled) print "enabled = true"
            if (!a_limit) print "max_concurrent_threads_per_session = " limit
            if (!a_model) print "default_subagent_model = \"gpt-5.6-luna\""
            if (!a_effort) print "default_subagent_reasoning_effort = \"max\""
        }
        /^\[[^]]+\][[:space:]]*(#.*)?$/ {
            if (section=="agents") emit_missing_agents()
            section=$0; sub(/^\[/,"",section); sub(/\].*$/,"",section)
            if (section=="agents") agents_found=1
            print; next
        }
        section=="" && /^[[:space:]]*model[[:space:]]*=/ { print "model = \"gpt-5.6-sol\""; next }
        section=="" && /^[[:space:]]*model_reasoning_effort[[:space:]]*=/ { print "model_reasoning_effort = \"high\""; next }
        section=="" && /^[[:space:]]*approval_policy[[:space:]]*=/ { print "approval_policy = \"on-request\""; next }
        section=="" && /^[[:space:]]*sandbox_mode[[:space:]]*=/ { print "sandbox_mode = \"workspace-write\""; next }
        section=="agents" && /^[[:space:]]*enabled[[:space:]]*=/ { print "enabled = true"; a_enabled=1; next }
        section=="agents" && /^[[:space:]]*max_concurrent_threads_per_session[[:space:]]*=/ { print "max_concurrent_threads_per_session = " limit; a_limit=1; next }
        section=="agents" && /^[[:space:]]*default_subagent_model[[:space:]]*=/ { print "default_subagent_model = \"gpt-5.6-luna\""; a_model=1; next }
        section=="agents" && /^[[:space:]]*default_subagent_reasoning_effort[[:space:]]*=/ { print "default_subagent_reasoning_effort = \"max\""; a_effort=1; next }
        { print }
        END {
            if (section=="agents") emit_missing_agents()
            if (!agents_found) {
                print ""; print "[agents]"; print "enabled = true"; print "max_concurrent_threads_per_session = " limit
                print "default_subagent_model = \"gpt-5.6-luna\""; print "default_subagent_reasoning_effort = \"max\""
            }
        }
    ' "$destination_config" > "$tmp_file"
    prefix=$destination_config.prefix.$
    : > "$prefix"
    grep -Eq '^[[:space:]]*model[[:space:]]*=' "$destination_config" || printf '%s\n' 'model = "gpt-5.6-sol"' >> "$prefix"
    grep -Eq '^[[:space:]]*model_reasoning_effort[[:space:]]*=' "$destination_config" || printf '%s\n' 'model_reasoning_effort = "high"' >> "$prefix"
    grep -Eq '^[[:space:]]*approval_policy[[:space:]]*=' "$destination_config" || printf '%s\n' 'approval_policy = "on-request"' >> "$prefix"
    grep -Eq '^[[:space:]]*sandbox_mode[[:space:]]*=' "$destination_config" || printf '%s\n' 'sandbox_mode = "workspace-write"' >> "$prefix"
    cat "$prefix" "$tmp_file" > "$destination_config"
    rm -f "$prefix" "$tmp_file"
    printf 'Merged global config. Backup: %s\n' "$destination_config.bak"
}

install_global() {
    profile_dir=$1
    codex_home=$HOME/.codex
    if [ -n "${CODEX_HOME:-}" ]; then codex_home=$CODEX_HOME; fi
    agents_home=$HOME/.agents
    legacy_skill=$agents_home/skills/astra-orchestrator
    if [ -e "$legacy_skill" ] || [ -L "$legacy_skill" ] || { [ -f "$codex_home/AGENTS.md" ] && grep -q 'astra-orchestrator' "$codex_home/AGENTS.md"; }; then
        printf '%s\n' 'Error: legacy global orchestration found. Follow guides/migration.md before installing; no files changed.' >&2
        exit 1
    fi
    mkdir -p "$codex_home/agents" "$agents_home/skills"
    merge_global_config "$profile_dir/codex/config.toml" "$codex_home/config.toml"
    cp -R "$profile_dir/codex/agents"/. "$codex_home/agents"/
    cp -R "$profile_dir/agents/skills"/. "$agents_home/skills"/
    if [ -f "$codex_home/AGENTS.md" ]; then
        if ! grep -q 'sol-orchestrator' "$codex_home/AGENTS.md"; then
            printf '\n\n' >> "$codex_home/AGENTS.md"
            cat "$script_dir/AGENTS.md" >> "$codex_home/AGENTS.md"
        fi
    else
        cp "$script_dir/AGENTS.md" "$codex_home/AGENTS.md"
    fi
    if [ -f "$codex_home/AGENTS.override.md" ]; then
        printf '%s\n' 'WARNING: AGENTS.override.md exists in CODEX_HOME, so Codex will prefer it over the installed global AGENTS.md.'
    fi
    printf 'Global setup complete in %s and %s.\n' "$codex_home" "$agents_home"
    printf '%s\n' 'Restart Codex and invoke $sol-orchestrator. Project-level config can still override global settings.'
}

scope=global
select_scope
plan=pro
select_plan

if [ "$scope" = global ]; then
    if confirm 'Install Sol High + Luna Max globally for this user?' yes; then
        install_global "$script_dir/profiles/$plan"
    else
        printf '%s\n' 'Global installation skipped.'
    fi
    exit 0
fi

printf '%s' 'Target repository path: '
IFS= read -r target_path || exit 1
if [ -z "$target_path" ] || [ ! -d "$target_path" ]; then
    printf 'Error: target must be an existing directory: %s\n' "$target_path" >&2
    exit 1
fi
target_dir=$(CDPATH= cd -- "$target_path" && pwd -P)
if [ "$target_dir" = "$script_dir" ]; then
    printf '%s\n' 'Error: target repository must be different from the setup source directory.' >&2
    exit 1
fi
legacy_skill=$target_dir/.agents/skills/astra-orchestrator
if [ -e "$legacy_skill" ] || [ -L "$legacy_skill" ] || { [ -f "$target_dir/AGENTS.md" ] && grep -q 'astra-orchestrator' "$target_dir/AGENTS.md"; }; then
    printf '%s\n' 'Error: legacy orchestration found. Follow guides/migration.md before installing; no files changed.' >&2
    exit 1
fi

installed=0
for component in .codex .agents AGENTS.md; do
    if confirm "Install $component?" yes; then
        if [ "$component" = .codex ]; then
            copy_component "$component" "$script_dir/profiles/$plan/codex"
        elif [ "$component" = .agents ]; then
            copy_component "$component" "$script_dir/profiles/$plan/agents"
        else
            copy_component "$component"
        fi
        if [ "$component_installed" = yes ]; then
            installed=$((installed + 1))
        fi
    else
        printf 'Skipped %s.\n' "$component"
    fi
done

printf '\nSetup complete. %s component(s) installed in %s (plan: %s).\n' "$installed" "$target_dir" "$plan"
printf '%s\n' 'Restart Codex in the trusted target project and invoke $sol-orchestrator. See guides/ for validation and migration.'
