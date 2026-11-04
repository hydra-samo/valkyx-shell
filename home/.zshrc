#            _
#    _______| |__  _ __ ___
#   |_  / __| '_ \| '__/ __|
#  _ / /\__ \ | | | | | (__
# (_)___|___/_| |_|_|  \___|
#
# -----------------------------------------------------
# ML4W zshrc loader
# -----------------------------------------------------

# DON'T CHANGE THIS FILE

# You can define your custom configuration by adding
# files in ~/.config/zshrc
# or by creating a folder ~/.config/zshrc/custom
# with you own zshrc configuration
# -----------------------------------------------------

if [ -d ~/.config/zshrc/custom ]; then
    for f in ~/.config/zshrc/custom/*(N); do source $f; done
fi
for f in ~/.config/zshrc/*(N); do source $f; done

# opencode
export PATH=$HOME/.opencode/bin:$PATH

export NVM_DIR="$HOME/.config/nvm"
# nvm lazy-load: sourcing nvm.sh costs ~190ms on every interactive shell.
# Stub the binaries instead; nvm loads itself on first real invocation.
_nvm_load() {
  unset -f _nvm_load node npm npx yarn pnpm nvm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm()  { _nvm_load >/dev/null 2>&1; nvm "$@"; }
node() { _nvm_load >/dev/null 2>&1; command node "$@"; }
npm()  { _nvm_load >/dev/null 2>&1; command npm "$@"; }
npx()  { _nvm_load >/dev/null 2>&1; command npx "$@"; }
yarn() { _nvm_load >/dev/null 2>&1; command yarn "$@"; }
pnpm() { _nvm_load >/dev/null 2>&1; command pnpm "$@"; }

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"



# kimi-code
export PATH="$HOME/.kimi-code/bin:$PATH"
export FIGMA_API_KEY="your_figma_api_key_here"

# Open Computer Use toggle
export PATH="$HOME/.config/opencode/bin:$PATH"

# Added by cua-driver-rs installer — see https://github.com/trycua/cua
export PATH="$HOME/.local/bin:$PATH"




# iNiR launcher PATH
case ":$PATH:" in
  *:"$HOME/.local/bin":*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
# end iNiR launcher PATH


# iNiR environment
export INIR_VENV="$HOME/.local/state/quickshell/.venv"
export ILLOGICAL_IMPULSE_VIRTUAL_ENV="$INIR_VENV"
# Apply terminal color sequences (Material You from wallpaper)
if [ -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt ]; then
  cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
fi
# Starship prompt (fish is wired via config.fish; zsh needs its own init)
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
# end iNiR

# opencode quick session access
alias ocs="opencode session list"

# Experiential Labs gateway key (source of truth: ~/.config/opencode/explabs.env, mode 600)
export EXPLABS_API_KEY=$(sed -n 's/^EXPLABS_API_KEY=//p' ~/.config/opencode/explabs.env)

# HYDRA dotfiles (bare repo of $HOME)

# HYDRA fetch on every new terminal session (image logo in kitty, ASCII elsewhere)
# Skip: tmux panes (already shown), dumb/console terminals, non-interactive/non-tty shells
if [[ -o interactive ]] && [[ -t 0 ]] && [[ -z "$TMUX" ]] && [[ "$TERM" != dumb ]] && command -v hydra-fetch >/dev/null 2>&1; then
    clear
    hydra-fetch
fi

# Added by LM Studio CLI tool (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
