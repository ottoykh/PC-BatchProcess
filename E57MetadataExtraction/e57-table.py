import os
import pye57
import csv
import numpy as np

def extract_metadata(folder_path):
    if not folder_path:
        print("No folder selected.")
        return

    try:
        e57_files = [f for f in os.listdir(folder_path) if f.endswith(".e57")]
        if not e57_files:
            print("No .e57 files found in the selected folder.")
            return

        csv_file_path = os.path.join(folder_path, "metadata_extraction.csv")
        with open(csv_file_path, mode='w', newline='') as csv_file:
            writer = csv.writer(csv_file)
            writer.writerow(["File", "Scan Position", "Point Count", "Rotation Matrix", "Translation"])

            for filename in e57_files:
                e57_file_path = os.path.join(folder_path, filename)
                e57 = pye57.E57(e57_file_path)
                header = e57.get_header(0)

                scan_position = e57.scan_position(0)
                point_count = header.point_count
                rotation_matrix = header.rotation_matrix
                translation = header.translation

                scan_position_str = ', '.join(map(str, scan_position.flatten()))
                rotation_matrix_str = '\n'.join(['\t'.join(map(str, row)) for row in rotation_matrix])
                translation_str = ', '.join(map(str, translation.flatten()))

                writer.writerow([filename, scan_position_str, point_count, rotation_matrix_str, translation_str])

                print(f"Metadata extracted for {filename}.")

        print("Metadata extraction completed successfully. CSV file created.")
    except Exception as e:
        print(f"An error occurred: {str(e)}")

if __name__ == '__main__':
    folder_path = r"D:\20241230-flame"  # Change this to your desired folder path
    extract_metadata(folder_path)