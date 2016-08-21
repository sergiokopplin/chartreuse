BULLETTRAIN_PROMPT_ORDER=(
  time
  dir
  git
)

BULLETTRAIN_PROMPT_CHAR="»"

BULLETTRAIN_TIME_BG=white
BULLETTRAIN_TIME_FG=black

BULLETTRAIN_DIR_BG=green
BULLETTRAIN_DIR_FG=black

BULLETTRAIN_GIT_COLORIZE_DIRTY=false
BULLETTRAIN_GIT_COLORIZE_DIRTY_FG_COLOR=black
BULLETTRAIN_GIT_COLORIZE_DIRTY_BG_COLOR=yellow
BULLETTRAIN_GIT_BG=white
BULLETTRAIN_GIT_FG=black
BULLETTRAIN_GIT_PROMPT_CMD="\$(git_prompt_info)"

ZSH_THEME_GIT_PROMPT_PREFIX="\ue0a0 "
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY=" %F{red}✘%F{black}"
ZSH_THEME_GIT_PROMPT_CLEAN=" %F{green}✔%F{black}"
ZSH_THEME_GIT_PROMPT_DELETED=" %F{red}✖%F{black}"

# ------------------------------------------------------------------------------
# SEGMENT DRAWING
# A few functions to make it easy and re-usable to draw segmented prompts
# ------------------------------------------------------------------------------

CURRENT_BG='NONE'
SEGMENT_SEPARATOR=''

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

# ------------------------------------------------------------------------------
# PROMPT COMPONENTS
# Each component will draw itself, and hide itself if no information needs
# to be shown
# ------------------------------------------------------------------------------

# Based on http://stackoverflow.com/a/32164707/3859566
function displaytime {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  [[ $D > 0 ]] && printf '%dd' $D
  [[ $H > 0 ]] && printf '%dh' $H
  [[ $M > 0 ]] && printf '%dm' $M
  printf '%ds' $S
}

# Git
prompt_git() {
  local ref dirty mode repo_path git_prompt
  repo_path=$(git rev-parse --git-dir 2>/dev/null)

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    if [[ $BULLETTRAIN_GIT_COLORIZE_DIRTY == true && -n $(git status --porcelain --ignore-submodules) ]]; then
      BULLETTRAIN_GIT_BG=$BULLETTRAIN_GIT_COLORIZE_DIRTY_BG_COLOR
      BULLETTRAIN_GIT_FG=$BULLETTRAIN_GIT_COLORIZE_DIRTY_FG_COLOR
    fi
    prompt_segment $BULLETTRAIN_GIT_BG $BULLETTRAIN_GIT_FG

    eval git_prompt=${BULLETTRAIN_GIT_PROMPT_CMD}
    echo -n ${git_prompt}$(git_prompt_status)
  fi
}

# Dir: current working directory
prompt_dir() {
  local dir=''
  dir="${dir}%4(c:...:)%3c"

  prompt_segment $BULLETTRAIN_DIR_BG $BULLETTRAIN_DIR_FG $dir
}

prompt_time() {
  prompt_segment $BULLETTRAIN_TIME_BG $BULLETTRAIN_TIME_FG %D{%T}
}

# Prompt Character
prompt_char() {
  local bt_prompt_char
  bt_prompt_char=""

  if [[ ${#BULLETTRAIN_PROMPT_CHAR} -eq 1 ]]; then
    bt_prompt_char="${BULLETTRAIN_PROMPT_CHAR}"
  fi

  bt_prompt_char="%(!.%F{red}#.%F{green}${bt_prompt_char}%f)"

  echo -n $bt_prompt_char
}

# ------------------------------------------------------------------------------
# MAIN
# Entry point
# ------------------------------------------------------------------------------

build_prompt() {
  RETVAL=$?
  for segment in $BULLETTRAIN_PROMPT_ORDER
  do
    prompt_$segment
  done
  prompt_end
}

NEWLINE='
'
PROMPT=''
PROMPT="$PROMPT$NEWLINE"
PROMPT="$PROMPT"'%{%f%b%k%}$(build_prompt)'
PROMPT="$PROMPT$NEWLINE"
PROMPT="$PROMPT"'%{${fg_bold[default]}%}'
PROMPT="$PROMPT"'$(prompt_char) %{$reset_color%}'
