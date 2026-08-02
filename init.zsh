# Compatibility loader for plugin managers preferring init.zsh.

source "${${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}:A:h}/cobalt-spark.plugin.zsh"
