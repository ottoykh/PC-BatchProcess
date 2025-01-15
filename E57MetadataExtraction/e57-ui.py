import os
import numpy as np
import pye57
import tkinter as tk
from tkinter import filedialog, messagebox


def extract_metadata(folder_path):
    if not folder_path:
        messagebox.showwarning("Warning", "No folder selected.")
        return

    try:
        e57_files = [f for f in os.listdir(folder_path) if f.endswith(".e57")]
        if not e57_files:
            messagebox.showinfo("Info", "No .e57 files found in the selected folder.")
            return

        for filename in e57_files:
            e57_file_path = os.path.join(folder_path, filename)

            # Load the E57 file
            e57 = pye57.E57(e57_file_path)

            # Get the scan header
            header = e57.get_header(0)

            # Extract metadata
            metadata = {
                "File": filename,
                "Point Count": header.point_count,
                "Rotation Matrix": header.rotation_matrix,
                "Translation": header.translation,
                "Scan Position": e57.scan_position(0),
                "Header Information": header.pretty_print(),
            }

            # Prepare output text
            output_lines = [f"{key}: {value}" for key, value in metadata.items()]

            # Define output file path
            output_file_path = os.path.splitext(e57_file_path)[0] + "_metadata.txt"

            # Write metadata to text file
            with open(output_file_path, 'w') as output_file:
                output_file.write("\n".join(output_lines))

        messagebox.showinfo("Success", "Metadata extraction completed successfully.")
    except Exception as e:
        messagebox.showerror("Error", f"An error occurred: {str(e)}")


def select_folder():
    folder_path = filedialog.askdirectory()
    extract_metadata(folder_path)


# Create the main window
root = tk.Tk()
root.title("E57 Metadata Extractor")
root.geometry("400x150")

# Create a button to select a folder
btn_select_folder = tk.Button(root, text="Select Folder", command=select_folder)
btn_select_folder.pack(pady=40)

# Entry point for the application
if __name__ == '__main__':
    root.mainloop()