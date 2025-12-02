
AUTOMATED QUALITY CONTROL AND TRIMMING PIPELINE FOR NGS DATA
Introduction to Bioinformatics and Computational Biology


AUTHOR: [Leonardo Fonseca]
DATE: December 2025
SYSTEM: Linux (Bash)


1. OVERVIEW

This project consists of a set of bash scripts designed to automate the 
pre-processing of Next-Generation Sequencing (NGS) data. The pipeline handles 
directory setup, quality control (pre and post-processing), and adaptive 
trimming based on data quality metrics.

The workflow allows for reproducible analysis of large datasets (>100 samples)
and includes a decision model that automatically selects optimal trimming 
parameters.


2. PREREQUISITES

The following tools must be installed and accessible in the system PATH or 
via a Conda environment:

- FastQC (v0.11.9+)
- MultiQC (v1.10+)
- FastP (v0.20.0+)

*Note: Script 2 includes an automated check for these tools and can prompt 
the user to activate a Conda environment if they are missing.*


3. REPOSITORY STRUCTURE

The pipeline consists of three main scripts:

   1. script_1.sh  -> Project Setup (Directory structure creation).
   2. script_2.sh  -> Main Pipeline (Orchestrator, Execution, and Logging).
   3. script_3.sh  -> Decision Model (Parameter optimization based on QC).


4. INSTRUCTIONS FOR USE 


STEP 1: Initialize the Project

Run the setup script to create the standardized directory structure.
   
   $ bash script_1.sh

   - Follow the prompts to enter the Project Name and Location.
   - This will create folders: 1_raw_data, 2_quality_control, 3_trimmed_data, 4_logs and 5_scripts.

STEP 2: Data & Script Placement 

Before running the analysis, you must manually move your files into the 
created structure:

   1. Copy your raw .fastq.gz files into:  [Project_Name]/1_raw_data/
   2. Copy script_2.sh and script_3.sh into: [Project_Name]/5_scripts/

STEP 3: Run the Pipeline

Navigate to the project root or the scripts folder and execute the main pipeline.

   $ cd [Project_Name]
   $ bash 5_scripts/script_2.sh

   - The script will detect the project root automatically.
   - You will be prompted to choose the Trimming Mode (Default, Optimized, Manual).
   - You can choose to process all samples or a single specific sample.


5. SCRIPT DETAILS & LOGIC


A. script_1.sh

Creates a reproducible directory tree. It ensures that raw data, scripts, 
logs, and results are kept separate.
   - Inputs: Project Name (interactive).
   - Outputs: Folder structure.

B. script_2.sh (Main Pipeline)

The core orchestrator. It features a "Global Logging" system using file 
descriptors (`exec`) to capture all screen output and errors into a log file.

Workflow:
   1. Environment Check (Threads & Conda).   
   2. Phase 1: Diagnostic FastQC and MultiQC on raw data.
   3. Phase 2: Decision Menu. If "Optimized" is selected, it calls script_3.sh.
   4. Phase 3: FastP Processing. Supports batch processing or single-sample runs.
      Features a "Kill Switch" (`set -e`) to stop execution on critical errors.
   5. Phase 4: Final FastQC and MultiQC on trimmed data.

C. script_3.sh (Decision Model)

An auxiliary script that analyzes FastQC reports to recommend trimming parameters.
Logic:
   1. Asks user for Read Type: Short Reads (SR) vs Long Reads (LR).
   2. Parses FastQC 'summary.txt' inside ZIP files.
   3. Scoring System:
      - FAIL status = 2 points
      - WARN status = 1 point
   4. Decision Levels:
      - Score 0-1: LIGHT Trimming (Basic adapter removal).
      - Score 2-3: MODERATE Trimming (Balanced quality filtering).
      - Score 4+: AGGRESSIVE Trimming (Strict cutting of low quality ends).
   5. Output: Saves parameters to '4_logs/fastp/.fastp_params.conf'.


6. OUTPUTS AND LOGS

Results are organized as follows:

- 2_quality_control/ : HTML reports from FastQC and MultiQC.
- 3_trimmed_data/    : Cleaned FASTQ files ready for alignment.
- 4_logs/            :
    |-- pipeline_execution_[date].log  : FULL record of the entire run.
    |-- fastp/model_execution_full.log : Record of Script 3 analysis.
    |-- fastp/parameter_decisions.log  : History of parameter choices.
    |-- fastp/[Sample]_full.log        : Individual FastP logs.

