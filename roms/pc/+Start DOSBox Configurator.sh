#!/bin/bash

# Set the current directory to the directory of the script
cd "$(dirname "$0")" || exit

# Source necessary libraries
source "DOSBox Settings.lib"
source "DOSBox Functions.lib"

# Function to display a menu for selecting a game
function select_game() {
    while true; do
        local i=0
        local game_options=()
        local game_files=()

        # Populate game options and files
        while read -r line; do
            ((i++))
            game_files[$i]="$line"
            if file_exists "$line.init"; then
                if file_exists "$line.conf"; then
                    game_options+=($i "[C] $line")
                else
                    game_options+=($i "[I] $line")
                fi
            else
                game_options+=($i "[ ] $line")
            fi
        done < <(ls -1 "$GAMEDIR/")

        # Display game menu
        GAME=$(dialog --ascii-lines --backtitle "$TITLE" --title " Game menu " --menu "Select a game from the list:" 30 80 22 "${game_options[@]}" 2>&1 1>/dev/tty)

        # Check user's choice
        if [ $? -eq 0 ]; then
            select_option "${game_files[$GAME]}"
        else
            break
        fi
    done
}

# Function to display options for a selected game
function select_option() {
    local GAME="$1"
    while true; do
        local options=("--ascii-lines" "--backtitle" "$TITLE" "--title" " $GAME")
        options+=("--menu" "Select action:" 30 80 22 "Game" "")

        # Add game-specific options
        options+=(" SelectExe" "Select file to run")
        if file_exists "$GAME.init"; then options+=(" ShowCMD" "Show game startup commands"); fi
        options+=(" EditCMD" "Manually edit game startup commands")
        if file_exists "$GAME.debug"; then options+=(" Debug" "Enable debug (pause before exit)")
        else options+=(" Debug" "Disable debug (no pause before exit)"); fi
        options+=("DOSBox" "")
        if file_exists "$GAME.conf"; then options+=(" ShowConf" "Show custom configuration"); fi
        options+=(" EditConf" "Manually edit customized DOSBox configuration")
        if is_disabled "$GAME.conf" "xms"; then options+=(" ToggleXMS" "Enable XMS (Extended Memory)")
        else options+=(" ToggleXMS" "Disable XMS (Extended Memory)"); fi
        if is_disabled "$GAME.conf" "ems"; then options+=(" ToggleEMS" "Enable EMS (Expanded Memory Manager)")
        else options+=(" ToggleEMS" "Disable EMS (Expanded Memory Manager)"); fi
        options+=("Cleanup" "")
        options+=(" RemoveConf" "Remove game configurations")

        # Display the menu
        OPT=$(dialog "${options[@]}" 2>&1 1>/dev/tty)
        if [ $? -eq 0 ]; then
            case $OPT in
                " SelectExe") select_exe "$GAME";;
                " ShowCMD") show_cmd "$GAME";;
                " EditCMD") edit_cmd "$GAME";;
                " Debug") toggle_debug "$GAME";;
                " ShowConf") show_conf "$GAME";;
                " EditConf") edit_conf "$GAME";;
                " ToggleXMS") toggle_option "$GAME.conf" "xms";;
                " ToggleEMS") toggle_option "$GAME.conf" "ems";;
                " RemoveConf") remove_conf "$GAME";;
            esac
        else
            break
        fi
    done
}

# Function to select the main executable for a game
function select_exe() {
    local GAME="$1"
    local i=0
    local exe_options=()
    local exe_files=()

    # Populate executable options and files
    while read -r line; do
        ((i++))
        line=$(basename "$line")
        exe_files[$i]="$line"
        exe_options+=($i "$line")
    done < <(find "$GAMEDIR/$GAME" -maxdepth 1 -iname '*.exe' -o -iname '*.bat' -o -iname '*.com')

    # Display the menu
    OPT=$(dialog --ascii-lines --backtitle "$TITLE" --title " $GAME " --menu "Select main executable from list:" 30 80 17 "${exe_options[@]}" 2>&1 1>/dev/tty)
    if [ $? -eq 0 ]; then
        set_cmd "$GAME" "${exe_files[$OPT]}"
    fi
}

# Function to set the startup command for a game
function set_cmd() {
    local GAME="$1"
    local CMD="$2"
    if [ ${CMD: -4} == ".bat" ]; then
        CMD="call $CMD"
    fi
    echo "$CMD" > "$GAME.init"
    show_dialog "$GAME" "$GAME startup command has been set to:\n\n$CMD"
}

# Function to show the startup command for a game
function show_cmd() {
    local GAME="$1"
    if [[ -e "$GAME.init" ]]; then
        CONTENT=$(cat "$GAME.init")
        show_dialog "Game startup command list" "$CONTENT"
    else
        show_error "Game startup command list" "Startup command list for '$GAME' has not been specified yet!"
    fi
}

# Function to edit the startup command for a game
function edit_cmd() {
    edit_file "$1.init"
}

# Function to toggle debug mode for a game
function toggle_debug() {
    local GAME="$1"
    [[ -e "$GAME.debug" ]] && rm "$GAME.debug" || touch "$GAME.debug"
}

# Function to show the custom DOSBox configuration for a game
function show_conf() {
    local GAME="$1"
    if [[ -e "$GAME.conf" ]]; then
        CONTENT=$(cat "$GAME.conf")
        show_dialog "Custom DOSBox Configuration" "$CONTENT"
    else
        show_error "Custom DOSBox Configuration" "Custom DOSBox configuration for game '$GAME' has not been created (default will be used)!"
    fi
}

# Function to edit the custom DOSBox configuration for a game
function edit_conf() {
    edit_file "$1.conf"
}

# Function to remove configurations for a game
function remove_conf() {
    local GAME="$1"
    if show_confirm "Delete configuration" "Delete configuration for '$GAME' (this will only remove files created by this script)?"; then
        rm -f "$GAME.init" "$GAME.conf" "$GAME.debug"
        show_dialog "Configuration removed" "Game configuration for '$GAME' has been removed!"
    fi
}

# Call the main function to start the script
select_game
