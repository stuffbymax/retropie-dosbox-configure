#!/bin/bash

# Set the current directory to the directory of the script
cd "$(dirname "$0")" || exit

# Source necessary libraries
source "DOSBox Settings.lib"
source "DOSBox Functions.lib"

# Function to handle DOS game launching
function launch_game() {
    local params=("$@")
    
    # Check if any parameters are provided
    if [[ -z "${params[0]}" ]]; then
        params=(-conf "$DIR/dosbox.conf")
    elif [[ "${params[0]}" == *.sh ]]; then
        # Execute shell script if provided
        bash "${params[@]}"
        exit
    else
        # Extract base name from the provided .init file
        local BASE=$(basename -s .init "$1")
        
        # Check if the .init file exists
        if [[ ! -e "$1" ]]; then
            echo "CMD-file specified ($1) does not exist!" >&2
            exit 1
        fi
        
        params=(-conf "$DIR/dosbox.conf")
        
        # Include game-specific configuration if exists
        if [[ -e "$DIR/$BASE.conf" ]]; then
            params+=(-conf "$DIR/$BASE.conf")
        fi
        
        # Check if the game folder exists
        if [[ ! -d "$GAMEDIR/$BASE" ]]; then
            echo "Game folder ($GAMEDIR/$BASE) does not exist!" >&2
            exit 1
        fi
        
        # Generate DOSBox autoexec configuration
        generate_autoexec_config "$1" "$BASE"
        
        params+=(-conf "$CONFIG")
    fi
    
    # Launch DOSBox with the provided parameters
    "/opt/retropie/emulators/dosbox/bin/dosbox" "${params[@]}"
}

# Function to generate autoexec configuration for DOSBox
function generate_autoexec_config() {
    local init_file="$1"
    local base_name="$2"
    
    echo "[autoexec]" > "$CONFIG"
    echo "mount e \"$GAMEDIR/$base_name\" -label Game" >> "$CONFIG"
    echo "e:" >> "$CONFIG"
    cat "$init_file" >> "$CONFIG"
    echo >> "$CONFIG"
    
    # Add pause command if debug file exists
    if [[ -e "$DIR/$base_name.debug" ]]; then
        echo "pause" >> "$CONFIG"
    fi
    
    echo "exit" >> "$CONFIG"
}

# Call the function to launch the game
launch_game "$@"
