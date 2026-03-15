#!/usr/bin/env bash
#
# Claude Code Status Line - Three-line format
#
# Line 1: [CWD] | [Branch] | [user/repo]
# Line 2: [Model] | Context: XX% | Cost: $XX
# Line 3: Session: X% | Weekly: X% | Reset: Mon(3d) | Feb 1(5d)
#
# JSON input from Claude Code via stdin

# Configuration
CACHE_DIR="/tmp/ccstatusline"
CACHE_TTL=600  # seconds (10 minutes)

mkdir -p "$CACHE_DIR"

# Read JSON input from stdin
INPUT=$(cat)

# Extract values using jq
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "?"')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
# Shorten home directory to ~
CWD="${CWD/#$HOME/\~}"
# Get git branch from CWD
GIT_CWD=$(echo "$INPUT" | jq -r '.cwd // "."')
BRANCH=$(git -C "$GIT_CWD" branch --show-current 2>/dev/null || echo "")
# Extract user/repo from git remote, fallback to repo dir name
GIT_REPO=$(git -C "$GIT_CWD" remote get-url origin 2>/dev/null | sed -E 's#.+[:/]([^/]+/[^/.]+)(\.git)?$#\1#' || echo "")
if [[ -z "$GIT_REPO" && -n "$BRANCH" ]]; then
    GIT_REPO="no remote"
fi
CONTEXT_REMAINING=$(echo "$INPUT" | jq -r '.context_window.remaining_percentage // 100')

# Session and Weekly usage from Claude Code (try multiple possible field paths)
SESSION_PCT=$(echo "$INPUT" | jq -r '.session.used_percentage // .rate_limits.session.used_percentage // .session.usage_percentage // 0' 2>/dev/null)
WEEKLY_PCT=$(echo "$INPUT" | jq -r '.weekly.used_percentage // .rate_limits.weekly.used_percentage // .weekly.usage_percentage // 0' 2>/dev/null)

# Convert to integer
SESSION_PCT=$(printf "%.0f" "$SESSION_PCT" 2>/dev/null || echo "0")
WEEKLY_PCT=$(printf "%.0f" "$WEEKLY_PCT" 2>/dev/null || echo "0")

# Calculate context usage (inverse of remaining, as integer)
CONTEXT_USAGE=$(printf "%.0f" "$(echo "100 - $CONTEXT_REMAINING" | bc 2>/dev/null)" 2>/dev/null || echo "0")

# Function to check if cache is fresh
is_cache_fresh() {
    local cache_file="$1"
    local now=$(date +%s)

    if [[ -f "$cache_file" ]]; then
        local mtime=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null)
        local age=$((now - mtime))
        [[ $age -lt $CACHE_TTL ]]
    else
        return 1
    fi
}

# Format cost with appropriate precision
format_cost() {
    local cost="$1"
    if (( $(echo "$cost >= 1000" | bc -l 2>/dev/null || echo "0") )); then
        printf '$%s' "$(printf '%.0f' "$cost" | sed -e :a -e 's/\(.*[0-9]\)\([0-9]\{3\}\)/\1,\2/;ta')"
    elif (( $(echo "$cost >= 100" | bc -l 2>/dev/null || echo "0") )); then
        printf '$%.0f' "$cost"
    elif (( $(echo "$cost >= 10" | bc -l 2>/dev/null || echo "0") )); then
        printf '$%.1f' "$cost"
    elif (( $(echo "$cost > 0" | bc -l 2>/dev/null || echo "0") )); then
        printf '$%.2f' "$cost"
    else
        printf '$0'
    fi
}

# Calculate days until next reset
days_until_weekly_reset() {
    local dow=$(date +%u)  # 1=Monday, 7=Sunday
    local days=$(( (8 - dow) % 7 ))
    [[ $days -eq 0 ]] && echo "7" || echo "$days"
}

days_until_monthly_reset() {
    local today=$(date +%d)
    local last_day=$(date -v+1m -v1d -v-1d +%d 2>/dev/null || date -d "$(date +%Y-%m-01) +1 month -1 day" +%d 2>/dev/null)
    echo $(( last_day - today + 1 ))
}

next_monday() {
    local dow=$(date +%u)
    local days=$(( (8 - dow) % 7 ))
    [[ $days -eq 0 ]] && days=7
    date -v+${days}d +%a 2>/dev/null || date -d "+${days} days" +%a 2>/dev/null
}

next_month_first() {
    date -v+1m -v1d +"%b %-d" 2>/dev/null || date -d "$(date +%Y-%m-01) +1 month" +"%b %-d" 2>/dev/null
}

# Get monthly data with caching (foreground) - for Cost display
MONTHLY_CACHE="$CACHE_DIR/monthly.json"
if is_cache_fresh "$MONTHLY_CACHE"; then
    MONTHLY_DATA=$(cat "$MONTHLY_CACHE")
else
    MONTHLY_DATA=$(npx ccusage monthly --json 2>/dev/null || echo '{"monthly":[]}')
    echo "$MONTHLY_DATA" > "$MONTHLY_CACHE"
fi

# Extract current month cost
MONTHLY_COST=$(echo "$MONTHLY_DATA" | jq -r '.monthly[-1].totalCost // 0' 2>/dev/null || echo "0")

# Calculate reset info
WEEKLY_RESET_DAY=$(next_monday)
WEEKLY_RESET_DAYS=$(days_until_weekly_reset)
MONTHLY_RESET_DAY=$(next_month_first)
MONTHLY_RESET_DAYS=$(days_until_monthly_reset)

# Build Line 1: CWD | Branch | user/repo
LINE1="\033[34m${CWD}\033[0m"
if [[ -n "$BRANCH" ]]; then
    LINE1+=" \033[90m|\033[0m "
    LINE1+="\033[35m${BRANCH}\033[0m"
fi
if [[ -n "$GIT_REPO" ]]; then
    LINE1+=" \033[90m|\033[0m "
    LINE1+="\033[90m${GIT_REPO}\033[0m"
fi

# Build Line 2: Model | Context: XX% | Cost: $XX
LINE2="\033[36m${MODEL}\033[0m"
LINE2+=" \033[90m|\033[0m "
LINE2+="\033[90mContext:\033[0m "
if [[ $CONTEXT_USAGE -gt 90 ]]; then
    LINE2+="\033[31m${CONTEXT_USAGE}%\033[0m"
elif [[ $CONTEXT_USAGE -gt 70 ]]; then
    LINE2+="\033[33m${CONTEXT_USAGE}%\033[0m"
else
    LINE2+="\033[32m${CONTEXT_USAGE}%\033[0m"
fi
LINE2+=" \033[90m|\033[0m "
LINE2+="\033[90mCost:\033[0m "
LINE2+="\033[33m$(format_cost $MONTHLY_COST)\033[0m"

# Build Line 3: Session: X% | Weekly: X% | Reset: Mon(3d) | Feb 1(5d)
LINE3="\033[90mSession:\033[0m "
if [[ $SESSION_PCT -gt 90 ]]; then
    LINE3+="\033[31m${SESSION_PCT}%\033[0m"
elif [[ $SESSION_PCT -gt 70 ]]; then
    LINE3+="\033[33m${SESSION_PCT}%\033[0m"
else
    LINE3+="\033[32m${SESSION_PCT}%\033[0m"
fi
LINE3+=" \033[90m|\033[0m "
LINE3+="\033[90mWeekly:\033[0m "
if [[ $WEEKLY_PCT -gt 90 ]]; then
    LINE3+="\033[31m${WEEKLY_PCT}%\033[0m"
elif [[ $WEEKLY_PCT -gt 70 ]]; then
    LINE3+="\033[33m${WEEKLY_PCT}%\033[0m"
else
    LINE3+="\033[32m${WEEKLY_PCT}%\033[0m"
fi
LINE3+=" \033[90m|\033[0m "
LINE3+="\033[90mReset:\033[0m "
LINE3+="\033[35m${WEEKLY_RESET_DAY}\033[0m\033[90m(${WEEKLY_RESET_DAYS}d)\033[0m"
LINE3+=" \033[90m|\033[0m "
LINE3+="\033[35m${MONTHLY_RESET_DAY}\033[0m\033[90m(${MONTHLY_RESET_DAYS}d)\033[0m"

# Output all lines
printf "%b\n%b\n%b" "$LINE1" "$LINE2" "$LINE3"
