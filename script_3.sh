#!/bin/bash
# script_3.sh: Decision Model 

# 1. Path Configuration and Detection

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Logic to determine if running inside the Project Structure or Standalone.
# It checks for '1_raw_data' nearby.
if [ -d "$SCRIPT_DIR/1_raw_data" ]; then
    PROJECT_ROOT="$SCRIPT_DIR"
    IS_PROJECT=true
elif [ -d "$SCRIPT_DIR/../1_raw_data" ]; then
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    IS_PROJECT=true
else
    # Fallback to current directory check
    CURRENT_PWD=$(pwd)
    if [ -d "$CURRENT_PWD/1_raw_data" ]; then
        PROJECT_ROOT="$CURRENT_PWD"
        IS_PROJECT=true
    else
        IS_PROJECT=false
        PROJECT_ROOT="$SCRIPT_DIR"
    fi
fi

# Set output directories based on mode
if [ "$IS_PROJECT" = true ]; then
    CONFIG_DIR="${PROJECT_ROOT}/4_logs/fastp"
else
    CONFIG_DIR="."
fi

READ_TYPE_FILE="${CONFIG_DIR}/.read_type.conf"
DECISION_LOG="${CONFIG_DIR}/parameter_decisions.log"

# 2. Read Type Configuration

# NEED_TO_ASK is forced to true so every run is independent.
NEED_TO_ASK=true

if [ "$NEED_TO_ASK" = true ]; then
    echo ""
    echo "MODEL CONFIGURATION (script_3.sh)"
    echo "Is the dataset Short Reads (SR) or Long Reads (LR)?"
    # Ask about the samples
    echo "1) Short Reads (SR)"
    echo "2) Long Reads (LR)"
    # It forces the script to read from the Keyboard.
    read -p "   Choose [1-2]: " READ_CHOICE < /dev/tty
    
    if [ "$READ_CHOICE" == "2" ]; then READ_TYPE="LR"; else READ_TYPE="SR"; fi
    
    # Save the choice 
    if [ "$IS_PROJECT" = true ]; then
        mkdir -p "$CONFIG_DIR"
        echo "$READ_TYPE" > "${READ_TYPE_FILE}"
    fi
fi

# 3. FastQC Parsing and Scoring

INPUT_DIR=$1
if [ -z "$INPUT_DIR" ]; then echo "Error: Missing FastQC directory"; exit 1; fi

# Find the first available zip report
ZIP_FILE=$(find "$INPUT_DIR" -name "*_fastqc.zip" | head -n 1)

if [ -z "$ZIP_FILE" ]; then
    echo "Warning: No FastQC report found. Assuming MODERATE."
    QUALITY_LEVEL="MODERATE"
    # Set default lengths if no data
    if [ "$READ_TYPE" == "SR" ]; then SEQ_LENGTH=150; else SEQ_LENGTH=1000; fi
    FAIL_COUNT="N/A"
    WARN_COUNT="N/A"
else
    # 'unzip -p' streams content without extracting files to disk.
    # We count occurrences of FAIL and WARN in the summary.
    FAIL_COUNT=$(unzip -p "$ZIP_FILE" "*/summary.txt" | grep -c "FAIL")
    WARN_COUNT=$(unzip -p "$ZIP_FILE" "*/summary.txt" | grep -c "WARN")
    
    # Extract Sequence Length from fastqc_data.txt
    RAW_LEN=$(unzip -p "$ZIP_FILE" "*/fastqc_data.txt" | grep "Sequence length" | awk '{print $3}')
    SEQ_LENGTH=${RAW_LEN##*-}

    # Scoring Logic:
    # Fail = +2 points | Warn = +1 point
    SCORE=0
    [ "$FAIL_COUNT" -ge 1 ] && SCORE=$((SCORE + 2))
    [ "$FAIL_COUNT" -ge 3 ] && SCORE=$((SCORE + 1)) # Extra penalty for many fails
    [ "$WARN_COUNT" -ge 2 ] && SCORE=$((SCORE + 1))

    if [ "$SCORE" -ge 4 ]; then QUALITY_LEVEL="AGGRESSIVE"
    elif [ "$SCORE" -ge 2 ]; then QUALITY_LEVEL="MODERATE"
    else QUALITY_LEVEL="LIGHT"; fi
fi

# 4. Parameter Generation

# Rules for Short Reads 
if [ "$READ_TYPE" == "SR" ]; then
    case $QUALITY_LEVEL in
        "LIGHT")      MIN_LEN=$((SEQ_LENGTH / 3)); [ "$MIN_LEN" -lt 30 ] && MIN_LEN=30
                      PARAMS="-q 15 -u 40 -n 10 -l $MIN_LEN" ;;
        "MODERATE")   MIN_LEN=$((SEQ_LENGTH / 2)); [ "$MIN_LEN" -lt 50 ] && MIN_LEN=50
                      PARAMS="-q 20 -u 30 -n 5 -l $MIN_LEN" ;;
        "AGGRESSIVE") MIN_LEN=$((SEQ_LENGTH * 2 / 3)); [ "$MIN_LEN" -lt 75 ] && MIN_LEN=75
                      PARAMS="-q 25 -u 20 -n 0 -f 5 -t 5 -l $MIN_LEN" ;;
    esac
else
    # Rules for Long Reads 
    case $QUALITY_LEVEL in
        "LIGHT")      PARAMS="-q 7 -u 50 -l 500" ;;
        "MODERATE")   PARAMS="-q 10 -u 40 -l 1000" ;;
        "AGGRESSIVE") PARAMS="-q 12 -u 30 -l 2000" ;;
    esac
fi

# 5. Output and Logging

if [ "$IS_PROJECT" = true ]; then
    mkdir -p "$CONFIG_DIR"
    # Saves parameters to a hidden file for Script 2 to read
    echo "$PARAMS" > "${CONFIG_DIR}/.fastp_params.conf"
    
    # Appends to history log
    LOG_MSG="Timestamp: $(date '+%Y-%m-%d %H:%M:%S') | Type: $READ_TYPE | Len: $SEQ_LENGTH bp | Fail: $FAIL_COUNT | Decision: $QUALITY_LEVEL | Params: $PARAMS"
    echo "$LOG_MSG" >> "$DECISION_LOG"
    
    echo "Analysis: $QUALITY_LEVEL ($READ_TYPE)"
else
    # Standalone mode: Print to screen
    echo "Recommendation: $QUALITY_LEVEL"
    echo "Parameters: $PARAMS"
fi
