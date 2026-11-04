




# iNiR launcher PATH
case ":$PATH:" in
  *:"$HOME/.local/bin":*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
# end iNiR launcher PATH


# Added by LM Studio CLI tool (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
