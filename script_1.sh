#!/bin/bash
# script_1.sh: Project Setup and Directory Structure

# 1. User Input

# Ask for the Project Name
read -p "Insert the project name (ex: sample_1): " PROJECT_NAME

# Validation: Prevents creating a project with an empty name.
if [ -z "$PROJECT_NAME" ]; then
    echo "Error: The project name cannot be empty."
    exit 1
fi

# Asks for location. Defaults to the current directory (.) if left blank.
echo "Where do you want to create the project folder?"
echo "If it's in this directory - leave blank or use (.)"
read -p "Path: " WORK_DIR

# If input is empty, assign current directory (.)
if [ -z "$WORK_DIR" ]; then WORK_DIR="."; fi

# Construct the full path variable
PROJECT_PATH="${WORK_DIR}/Project_${PROJECT_NAME}"

# 2. Directory Creation 

# Checks if the directory already exists to prevent overwriting.
if [ -d "$PROJECT_PATH" ]; then
    echo "Warning: The folder $PROJECT_PATH already exists."
else
    # Creates main directories
    mkdir -p "$PROJECT_PATH"/{1_raw_data,2_quality_control,3_trimmed_data,4_logs,5_scripts}
    
    # Creates sub-directories for specific tool outputs.
    mkdir -p "$PROJECT_PATH"/2_quality_control/{fastqc_raw,fastqc_trimmed,multiqc_raw}
    mkdir -p "$PROJECT_PATH"/4_logs/{fastqc_raw,fastqc_trimmed,fastp,multiqc_raw}
    
    # Copies this script into the 5_scripts folder ---
    cp "$0" "$PROJECT_PATH/5_scripts/"
    
    # Get the absolute path
    cd "$PROJECT_PATH"
    FULL_PATH=$(pwd)
    
    echo ""
    echo "SUCCESS! Project created at:"
    echo "$FULL_PATH"
    echo ""
fi