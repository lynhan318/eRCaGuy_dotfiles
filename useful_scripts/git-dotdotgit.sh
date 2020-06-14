#!/bin/bash

# This file is part of eRCaGuy_dotfiles: https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles

# Status: Work in Progress (WIP)

# Author: Gabriel Staples
# www.ElectricRCAircraftGuy.com 

# DESCRIPTION:
# I want to archive a bunch of small git repos inside a single, larger repo, which I will back up on 
# GitHub until I have time to manually pull out each small, nested repo into its own stand-alone
# GitHub repo. To do this, however, `git` in the outer, parent repo must NOT KNOW that the inner
# git repos are git repos! The easiest way to do this is to just rename all inner, nested `.git` 
# folders to anything else, such as to `..git`, so that git won't recognize them as stand-alone
# repositories, and so that it will just treat their contents like any other normal directory
# and allow you to back it all up! Thus, this project is born. It will allow you to quickly
# "toggle" the naming of any folder from `.git` to `..git`, or vice versa. Hence the name of this
# project: "git-dotdotgit". 
# See my answer here: 
# https://stackoverflow.com/questions/47008290/how-to-make-outer-repository-and-embedded-repository-work-as-common-standalone-r/62368415#62368415

# INSTALLATION INSTRUCTIONS:
# 1. Create a symlink in ~/bin to this script so you can run it from anywhere as `git dotdotgit` OR
#    as `git-dotdotgit` OR as `gs_git-dotdotgit` OR as `git gs_dotdotgit`. Note that "gs" is my initials. 
#    I do these versions with "gs_" in them so I can find all scripts I've written really easily 
#    by simply typing "gs_" + Tab + Tab, or "git gs_" + Tab + Tab. 
#       cd /path/to/here
#       mkdir -p ~/bin
#       ln -si "${PWD}/git-dotdotgit.sh" ~/bin/git-dotdotgit     # required
#       ln -si "${PWD}/git-dotdotgit.sh" ~/bin/git-gs_dotdotgit  # optional; replace "gs" with your initials
#       ln -si "${PWD}/git-dotdotgit.sh" ~/bin/gs_git-dotdotgit  # optional; replace "gs" with your initials
# 2. Now you can use this command directly anywhere you like in any of these 5 ways:
#   1. `git dotdotgit`  <=== my preferred way to use this program
#   2. `git-dotdotgit`
#   3. `git gs_dotdotgit`
#   4. `git-gs_dotdotgit`
#   3. `gs_git-dotdotgit`

# FUTURE WORK/TODO:
# 1. NA

# References:
# 1. https://stackoverflow.com/questions/47008290/how-to-make-outer-repository-and-embedded-repository-work-as-common-standalone-r/62368415#62368415

VERSION="0.1.0"
AUTHOR="Gabriel Staples"

EXIT_SUCCESS=0
EXIT_ERROR=1

# SCRIPT_NAME="$(basename "$0")"
SCRIPT_NAME="git dotdotgit"
NAME_AND_VERSION_STR="'$SCRIPT_NAME' version $VERSION"

HELP_STR="
$NAME_AND_VERSION_STR
  - Rename all \".git\" subdirectories in the current directory to \"..git\" so that they can be 
    easily added to a parent git repo as if they weren't git repos themselves 
    (\".git\" <--> \"..git\").
  - Why? See: https://stackoverflow.com/a/62368415/4561887

Usage: '$SCRIPT_NAME [positional_parameters]'
  Positional Parameters:
    '-h' OR '-?'        = print this help menu
    '-v' OR '--version' = print the author and version
    '--on'              = rename all \".git\" subdirectories --> \"..git\"
    '--on_dryrun'       = dry run of the above
    '--off'             = rename all \"..git\" subdirectories --> \".git\"
        So, once you do '$SCRIPT_NAME --off' Now you can then do 
        'cd path/to/parent/repo && mv ..git .git && git add -A' to add all files and folders to 
        the parent git repo, and then 'git commit' to commit them. Prior to running
        '$SCRIPT_NAME', git would not have allowed this since it won't natively let 
        you add sub-repos to a repo, and it recognizes sub-repos by the existence of their
        \".git\" directories.  
    '--off_dryrun'      = dry run of the above
    '--list'            = list all \".git\" and \"..git\" subdirectories

Common Usage Example:
  - To rename all '.git' subdirectories to '..git' **except for** the one immediately in the current 
    directory, so as to not disable the parent repo's .git dir, run this:

        git dotdotgit --on && mv ..git .git

This program is part of: https://github.com/ElectricRCAircraftGuy/eRCaGuy_dotfiles
"

print_help() {
    echo "$HELP_STR"
}

print_version() {
    echo "$NAME_AND_VERSION_STR"
    echo "Author = $AUTHOR"
    echo "See '$SCRIPT_NAME -h' for more info."
}

parse_args() {
    if [ $# -lt 1 ]; then
        echo "ERROR: Not enough arguments supplied ($# supplied, 1 required)"
        print_help
        exit $EXIT_ERROR
    fi

    if [ $# -gt 1 ]; then
        echo "ERROR: Too many arguments supplied ($# supplied, 1 required)"
        print_help
        exit $EXIT_ERROR
    fi

    # Help menu
    # Note: if running this command as `git dotdotgit` rather than `git-dotdotgit`, you can NOT
    # pass it a '--help' parameter, because `git` intercepts this parameter and tries to print its
    # own help or man pages for the given command. Nevertheless, let's leave in the '--help' option
    # for those who wish to run the command with the '-' in it vs without the '-' in it. 
    if [ "$1" == "-h" ] || [ "$1" == "-?" ] || [ "$1" == "--help" ]; then
        print_help
        exit $EXIT_SUCCESS
    fi

    # Version
    if [ "$1" == "-v" ] || [ "$1" == "--version" ]; then
        print_version
        exit $EXIT_SUCCESS
    fi

    # All other commands

    # WARNING: default to the SAFE STATE, which is to do a dry run, *NOT* the unsafe state, which
    # is to do real renames!
    DRY_RUN="true" 
    if [ "$1" == "--on" ] || [ "$1" == "--on_dryrun" ] || \
       [ "$1" == "--off" ] || [ "$1" == "--off_dryrun" ] || \
       [ "$1" == "--list" ]; then

        CMD="$1"
        if [ "$CMD" == "--on_dryrun" ]; then
            CMD="--on"
        elif [ "$CMD" == "--off_dryrun" ]; then
            CMD="--off"
        elif [ "$CMD" == "--on" ] || [ "$CMD" == "--off" ]; then
            # disable the dry run setting for real runs
            DRY_RUN="false"
        fi
    else 
        echo "ERROR: Invalid Parameter. You entered \"$1\". Valid parameters are shown below."
        print_help
        exit $EXIT_ERROR
    fi
} # parse_args()

# Actually do the renaming here (".git" <--> "..git")
dotdotgit() {
    # BORROWED FROM MY "eRCaGuy_dotfiles/useful_scripts/find_and_replace.sh" script:

    # Obtain a long multi-line string of paths to all dirs whose names match the `find_regex`
    # regular expression; there will be one line per filename path. It is important that we run
    # the `find` command ONLY ONCE, since it takes the longest amoung of time of all of the 
    # commands we use in this script! So, we must run it once & store its output into a variable.
    dirnames="$(find . -type d | grep -E "$find_regex" | sort -V)"
    # echo -e "===============\ndirnames = \n${dirnames}\n===============" # for debugging

    # Convert the long `dirnames` string to a Bash array, separated by new-line chars; see:
    # 1. https://stackoverflow.com/questions/24628076/bash-convert-n-delimited-strings-into-array/24628676#24628676
    # 2. https://unix.stackexchange.com/questions/184863/what-is-the-meaning-of-ifs-n-in-bash-scripting/184867#184867
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to new line
    dirnames_array=($dirnames) # split long string into array, separating by IFS (newline chars)
    IFS=$SAVEIFS   # Restore IFS

    # Get the length of the bash array; see here:
    # https://stackoverflow.com/questions/1886374/how-to-find-the-length-of-an-array-in-shell/1886483#1886483
    num_dirs="${#dirnames_array[@]}"
    echo "number of directories found = $num_dirs"

    dir_num=0
    num_dirs_renamed=0
    for dirname in ${dirnames_array[@]}; do
        dir_num=$((dir_num + 1))

        parentdir="$(dirname "$dirname")"
        dir="$(basename "$dirname")"

        if [ "$DRY_RUN" == "true" ]; then
            printf "DRY RUN: %3u: %s\n" $dir_num \
            "mv \"${parentdir}/${dir}\" \"${parentdir}/${rename_to}\""
        elif [ "$DRY_RUN" == "false" ]; then
            num_dirs_renamed=$((num_dirs_renamed + 1))
            printf "%3u: %s\n" $dir_num \
            "mv \"${parentdir}/${dir}\" \"${parentdir}/${rename_to}\""
            # Now actually DO the renames since it is NOT a dry run!
            mv "${parentdir}/${dir}" "${parentdir}/${rename_to}"
        fi
    done

    echo "number of directories actually renamed = $num_dirs_renamed"
}

main() {
    # echo "CMD = $CMD" # for debugging

    if [ "$CMD" == "--on" ]; then
        echo "Renaming all \"/.git\" directories --> \"/..git\""
        # WARNING: DO *NOT* FORGET THE `/` AT THE BEGINNING AND THE `$` AT THE END!
        find_regex="/\.git$" # matches "/.git" at the end of a line
        rename_to="..git"
        dotdotgit
    elif [ "$CMD" == "--off" ]; then
        echo "Renaming all \"/..git\" directories back to --> \"/.git\""
        # WARNING: DO *NOT* FORGET THE `/` AT THE BEGINNING AND THE `$` AT THE END!
        find_regex="/\.\.git$" # matches "/..git" at the end of a line
        rename_to=".git"
        dotdotgit
    elif [ "$CMD" == "--list" ]; then
        echo "listing all \".git\" and \"..git\" directories:"
        # Do not forget the `/` at the beginning and the `$` at the end.
        # - matches "/.git" and "/..git" at the end of a line
        find . -type d | grep --color=always -E "/(\.|\.\.)git$" 
    fi

    echo "Done!"
} # main()


# ----------------------------------------------------------------------------------------------------------------------
# Program entry point
# ----------------------------------------------------------------------------------------------------------------------

parse_args "$@"
# time main # run main, while also timing how long it takes
main
