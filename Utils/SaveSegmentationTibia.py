import os
import shutil

"""This script copies tibia masks from a specified input directory to an output directory, since totalsegmentator generates a whole folder for each mask, and we only want the tibia mask, which is named 'tibia.nii.gz' inside each folder. 
It renames the copied files to 'tibia_XXXXXX.nii.gz', where 'XXXXXX' is the number extracted from the folder name."""

# Paths base
input_dir = "/usagers4/u139017/Documents/THIN_MASK"          # ← Replace with your actual path
output_dir = "/usagers4/u139017/Documents/SegmentacionTibias" # ← Replace with your desired output path
os.makedirs(output_dir, exist_ok=True)

count = 0

# Goes for every MaskXXXXXX.nii
for folder_name in os.listdir(input_dir):
    folder_path = os.path.join(input_dir, folder_name)

    # Verify that name starts with MaskXXXXXX.nii
    if os.path.isdir(folder_path) and folder_name.startswith("Mask") and folder_name.endswith(".nii"):
        numero = folder_name[4:10]
        if not numero.isdigit():
            continue  # no valid number in folder name

        tibia_path = os.path.join(folder_path, "tibia.nii.gz")

        if os.path.exists(tibia_path):
            output_name = f"tibia_{numero}.nii.gz"
            output_path = os.path.join(output_dir, output_name)
            shutil.copy(tibia_path, output_path)
            count += 1
        else:
            print(f"⚠️ No tibia was found at {folder_name}")

print(f"✅  {count} tibia masks were copy correctly.")
