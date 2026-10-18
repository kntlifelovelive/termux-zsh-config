# ~/.config/zsh/functions/hooks.zsh
# Custom hooks — command timing (Termux).

# Before each command: track start time.
preexec() {
    cmd_start_time=$(date +%s 2>/dev/null) || cmd_start_time=""
}

# After each command: report long-running commands.
precmd() {
    if [[ -n "${cmd_start_time:-}" ]]; then
        local now
        now=$(date +%s 2>/dev/null) || now=""
        if [[ -n "$now" ]]; then
            local duration=$((now - cmd_start_time))
            # Only show if command took more than 5 seconds.
            if [[ $duration -gt 5 ]]; then
                local minutes=$((duration / 60))
                local seconds=$((duration % 60))
                local time_color="\e[1;33m"   # yellow bold
                local label_color="\e[1;34m"  # blue bold
                local reset="\e[0m"
                local time_str=""
                if [[ $minutes -gt 0 ]]; then
                    local minute_word="minute"
                    [[ $minutes -gt 1 ]] && minute_word="minutes"
                    local second_word="second"
                    [[ $seconds -gt 1 ]] && second_word="seconds"
                    time_str="${minutes} ${minute_word} ${seconds} ${second_word}"
                else
                    local second_word="second"
                    [[ $seconds -gt 1 ]] && second_word="seconds"
                    time_str="${seconds} ${second_word}"
                fi
                echo ""
                echo -e "${time_color}\u23f1${label_color} Command run time:${reset} ${time_color}${time_str}${reset}"
                echo ""
            fi
        fi
        unset cmd_start_time
    fi
}
