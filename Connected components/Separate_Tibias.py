

################################################################################################################################3
import os
import nibabel as nib
import numpy as np
from scipy.ndimage import label, center_of_mass
import matplotlib.pyplot as plt

# Path config:
input_folder = "/usagers4/u139017/Documents/SegmentacionTibias"
output_folder = "/usagers4/u139017/Documents"

# Creates subfolders for left/right tibias
left_folder = os.path.join(output_folder, "left_tibia")
right_folder = os.path.join(output_folder, "right_tibia")
os.makedirs(left_folder, exist_ok=True)
os.makedirs(right_folder, exist_ok=True)

for filename in os.listdir(input_folder):
    if filename.startswith("tibia_") and filename.endswith(".nii.gz"):
        print(f" Procesando... {filename}")
        path = os.path.join(input_folder, filename)
        nii = nib.load(path)
        data = nii.get_fdata()

        # Connected components
        labeled, num = label(data)
        if num != 2:
            print(f"  {filename}: Se encontraron {num} componentes. Saltando...")
            continue

        # Centroids and sorting by X coordinate
        centroids = center_of_mass(data, labeled, range(1, num+1))
        order = sorted(range(num), key=lambda i: centroids[i][0])  # eje X
        idx_left = order[1] + 1  # mayor X → tibia izquierda
        idx_right = order[0] + 1 # menor X → tibia derecha

        left_mask = (labeled == idx_left).astype(np.uint8)
        right_mask = (labeled == idx_right).astype(np.uint8)

        # Base name for saving
        base = filename.replace("tibia_", "").replace(".nii.gz", "")

        # saves NIFTIs
        nib.save(nib.Nifti1Image(left_mask, nii.affine), os.path.join(left_folder, f"left_tibia_{base}.nii.gz"))
        nib.save(nib.Nifti1Image(right_mask, nii.affine), os.path.join(right_folder, f"right_tibia_{base}.nii.gz"))

        # Middle Slice for preview
        z_mid = data.shape[2] // 2
        orig_slice = data[:, :, z_mid]
        left_slice = left_mask[:, :, z_mid]
        right_slice = right_mask[:, :, z_mid]

        overlay = np.zeros(orig_slice.shape + (3,), dtype=np.uint8)
        overlay[..., 0] = (left_slice > 0) * 255   # red
        overlay[..., 1] = (right_slice > 0) * 255  # green

        # Save preview of left tibia
        plt.figure(figsize=(5, 5))
        plt.imshow(orig_slice, cmap='gray')
        plt.imshow(overlay, alpha=0.5)
        plt.axis('off')
        plt.title(f"{base} - corte Z medio")
        plt.tight_layout()

        plt.savefig(os.path.join(left_folder, f"preview_{base}.png"), dpi=150)
        plt.close()

print(" All ready and saved.")
