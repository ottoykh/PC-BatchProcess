import os
import pye57

def extract_metadata(folder_path):
    if not folder_path:
        print("No folder selected.")
        return

    try:
        e57_files = [f for f in os.listdir(folder_path) if f.endswith(".e57")]
        if not e57_files:
            print("No .e57 files found in the selected folder.")
            return

        for filename in e57_files:
            e57_file_path = os.path.join(folder_path, filename)
            e57 = pye57.E57(e57_file_path)
            header = e57.get_header(0)
            output_lines = [
                f"File: {filename}",
                f"Scan Position: {e57.scan_position(0)}",
                f"Point Count: {header.point_count}",
                f"Rotation Matrix:\n{header.rotation_matrix}",
                f"Translation:\n{header.translation}",
                "Header Information:",
            ]
            output_lines.extend(header.pretty_print())
            output_file_path = os.path.splitext(e57_file_path)[0] + "_metadata.txt"
            with open(output_file_path, 'w') as output_file:
                output_file.write("\n".join(output_lines))

            print(f"Metadata extracted for {filename}.")
        print("Metadata extraction completed successfully.")
    except Exception as e:
        print(f"An error occurred: {str(e)}")

if __name__ == '__main__':
    folder_path = r"D:\20241230-flame"
    extract_metadata(folder_path)