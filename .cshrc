

########################################## Environment ############################################

set history = 16384
set autologout = 0

setenv LANG C
setenv TZ MEZ-1MESZ

if (! $?LD_LIBRARY_PATH) then
    setenv LD_LIBRARY_PATH ${HOME}/local/lib
    else
    setenv LD_LIBRARY_PATH ${LD_LIBRARY_PATH}:${HOME}/local/lib
endif

####################################### Alias-Definitionen #########################################

unset watch who savehist prompt
unsetenv MINICOM COLORTERM XCURSOR_THEME FROM_HEADER LS_COLORS LS_OPTIONS
unalias cwdcmd .. ... cd.. d dir helpcommand l la ls md o p path r rd remount startx v vdir

alias s         "${HOME}/scripts/alogin"
alias c         "clear"
alias h         "history"
alias r         'eval `resize -c` >& /dev/null'
alias p         'ps -ef | sort -b'
alias ll        'ls -ltr \!*'
alias soc       "source ~/.cshrc"
alias hdbstudio "/usr/sap/hdbstudio/hdbstudio -data ${HOME}/.hdbstudio"
alias o 'tasset \!* ok'
alias r 'tasset \!* restart'

if ($?LOGNAME) then
    setenv USER $LOGNAME
else
    setenv USER `whoami`
endif

set prompt = "${USER}@`hostname`:${cwd}% "
alias setprompt  'set prompt="${USER}@`hostname`:${cwd}% "'
alias cd "cd \!*; setprompt"

#alias ssh "ssh -t 'printf "\033k%s\033\\" \!*'"

#echo $DISPLAY >> tettttt
#sed -i 's/\(setenv DISPLAY\) \([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}:[0-9]\{1,4\}\(\.[0-9]\)\?/\1 '$DISPLAY'/g' .Xdefaults
#xrdb -merge .Xdefaults
