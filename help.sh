#!/bin/bash

# help.sh -- self-contained on-line help for bash scripts
#
# (C) Copyright 2013, Dario Hamidi <dario.hamidi@gmail.com>
# 
# help.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# help.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with help.sh.  If not, see <http://www.gnu.org/licenses/>.
#

# To see help.sh in action try the following in the directory of
# help.sh:
#
## summary of all public commands (i.e. not idented)
#
# (source help.sh; help help.sh)
# 
## summary of all documented commands
#
# (source help.sh; HELP_BOL=no; help help.sh)
# 
## detailed description of a single command
#
# (source help.sh; help help.sh help)
#
 
# Provide your script with a help function:
# 
# function help {
#     (source help.sh; help $0 $@)
# }

#@help
#+FILE [COMMAND] -- briefly describe commands extracted from FILE
#
# This function parses special comments in the shell script FILE in
# order to display a summary of all interactive commands FILE supports.
#
# If COMMAND is given and names a existing command in FILE, a longer
# description of just COMMAND is displayed.
#
# The behavior of `help' can be influenced with these environment
# variables:
#
# - HELP_COL (Default: 25)
#
# the column where the command summary should start
#
# - HELP_BOL (Default: "yes")
#
# if set to "yes", then only comments starting in column 0 are taken
# into account when parsing a command's documentation.
function help {
    #@indent-to
    #+WORD COL -- out spaces to position cursor after WORD in column COL
    function indent-to {
        local word=$1
        declare -i col=$2

        for ((i = ${#word}; i < col; i++))
        do
            echo -n " "
        done
    }

    #@warn
    #+MSG -- outputs MSG on standard error, prefixed with the script name
    function warn {
        local msg=$1

        echo "$0: $msg" >&2
    }

    #@fatal
    #+MSG -- warn MSG, then exit with exit code 1
    function fatal {
        local msg=$1

        warn "$msg"
        exit 1
    }

    local file=$1
    local command=$2

    # command -> long description
    declare -A desc=()
    # command -> summary
    declare -A summary=()

    # does FILE exist?
    [[ -n "$file" && -e "$file" ]] || fatal "'$file' does not exist"

    # parse FILE
    local cur                   # the command currently being parsed
    local OLDIFS="$IFS"
    local IFS="$OLDIFS"
    if [[ "${HELP_BOL:-yes}" == "yes" ]]
    then
        # preserve whitespace
        IFS=''
    fi

    while read line
    do
        # a line beginning with `#@name' introduces command `name'
        # the first `#' after the slash anchors the pattern at the beginning of the string
        if [[ "$line" != "${line/##@}" ]]        
        then
            cur="${line:2}"     # strip the leading `#@'
        # when parsing a command, `#+' defined the summary
        elif [[ -n "$cur" && ( "$line" != "${line/##+}" ) ]]
        then
            summary["$cur"]="${line:2}" # strip the leading `#+'
        # a line beginning with `function' ends the command documentation
        elif [[ "$line" != "${line/#function}" ]]
        then
            cur=""
        # inside a command definition we add all lines beginning with `#'
        elif [[ -n "$cur" && ( "$line" != "${line/##}" ) ]]
        then
            description["$cur"]="${description[$cur]}${line##\#}\n"
        fi
    done <"$file"
    IFS="$OLDIFS"

    # should we output only one detailed description?
    if [[ -n "$command" ]]
    then
        echo "$command -- ${summary[$command]}"
        echo -e "${description[$command]}"
    else
    # output a short summary for each command
        for word in ${!summary[@]}
        do
            echo -n "$word"
            indent-to "$word" ${HELP_COL:-25}
            echo "${summary[$word]}"
        done
    fi
}
