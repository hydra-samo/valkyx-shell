#    _               _              
#   | |__   __ _ ___| |__  _ __ ___ 
#   | '_ \ / _` / __| '_ \| '__/ __|
#  _| |_) | (_| \__ \ | | | | | (__ 
# (_)_.__/ \__,_|___/_| |_|_|  \___|
# 
# -----------------------------------------------------
# ML4W bashrc loader
# -----------------------------------------------------

# DON'T CHANGE THIS FILE

# You can define your custom configuration by adding
# files in ~/.config/bashrc 
# or by creating a folder ~/.config/bashrc/custom
# with copies of files from ~/.config/bashrc 
# You can also create a .bashrc_custom file in your home directory
# -----------------------------------------------------

# -----------------------------------------------------
# Load modular configuration
# -----------------------------------------------------

for f in ~/.config/bashrc/*; do 
    if [ ! -d $f ]; then
        c=`echo $f | sed -e "s=.config/bashrc=.config/bashrc/custom="`
        [[ -f $c ]] && source $c || source $f
    fi
done

# -----------------------------------------------------
# Load single customization file (if exists)
# -----------------------------------------------------

if [ -f ~/.bashrc_custom ]; then
    source ~/.bashrc_custom
fi
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
# Starship prompt (fish is wired via config.fish; bash needs its own init)
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi
# end iNiR

# OpenIV launcher
alias openiv='$HOME/.local/share/openiv-linux/openiv.sh "$HOME/.local/share/openiv-linux/prefix/drive_c/users/axorasamo/AppData/Local/New Technology Studio/Apps/OpenIV/OpenIV.exe"'

# Added by LM Studio CLI tool (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
