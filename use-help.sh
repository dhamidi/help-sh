#!/bin/bash

#@help
#+describe all commands
function help {
    (source help.sh; help $0 "$@")
}

#@hello
#+NAME -- issue a greeting to NAME
function hello {
    local name=$1
    echo "hello, $name"
}

eval $@
