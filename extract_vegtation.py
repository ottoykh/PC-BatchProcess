import os
import subprocess

input_dir = "G:/LAS/"
output_dir = "G:/LAS/"

input_file_list_path = "G:/LAS/input.txt"

with open(input_file_list_path, 'r') as f:
    input_files = [line.strip() for line in f if line.strip()]

for input_file in input_files:
    input_path = os.path.join(input_dir, input_file)
    output_file = input_file.replace("_Scanner1_", "_Scanner1_output_")
    output_path = os.path.join(output_dir, output_file)

    # CloudCompare command
    command = [
        "G:/CloudCompare/CloudCompare.exe",
        "-SILENT",
        "-O", input_path,
        "-SET_ACTIVE_SF", "LAST",
        "-FILTER_SF", "3", "5",
        "-C_EXPORT_FMT", "LAS",
        "-SAVE_CLOUDS", "FILE", output_path
    ]

    subprocess.call(command)

print("Batch processing completed.")
