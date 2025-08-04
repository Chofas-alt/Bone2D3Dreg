import os
import nibabel as nib
import numpy as np
from scipy.ndimage import label, center_of_mass
import matplotlib.pyplot as plt

"""
Since some of the masks have small artifacts, this script first removes small components, 
then separates the two largest components into left/right tibias."""

# Path config:
input_folder = "/usagers4/u139017/Documents/SegmentacionTibias"
output_folder = "/usagers4/u139017/Documents/Tibia_Seg_Separada"


# Creates subfolders for left/right tibias
left_folder = os.path.join(output_folder, "left")
right_folder = os.path.join(output_folder, "right")
os.makedirs(left_folder, exist_ok=True)
os.makedirs(right_folder, exist_ok=True)

for filename in os.listdir(input_folder):
    if filename.startswith("tibia_") and filename.endswith(".nii.gz"):
        print(f"Procesando... {filename}")
        path = os.path.join(input_folder, filename)
        nii = nib.load(path)
        data = nii.get_fdata()

        #  1: Remove small blobs
        labeled, num = label(data)
        component_sizes = [(i+1, np.sum(labeled == (i+1))) for i in range(num)]

        # Threshold to keep only large components
        min_voxels = 5000
        component_sizes = [c for c in component_sizes if c[1] >= min_voxels]
        print(f"Componentes grandes encontrados: {len(component_sizes)}")

        if len(component_sizes) < 2:
            print(f"  {filename}: Solo {len(component_sizes)} componentes grandes. Saltando...")
            continue

        # Takes the two largest components
        component_sizes.sort(key=lambda x: x[1], reverse=True)
        keep_labels = [component_sizes[0][0], component_sizes[1][0]]

        cleaned_mask = np.isin(labeled, keep_labels).astype(np.uint8)

        # Relabel cleaned mask
        labeled_clean, _ = label(cleaned_mask)

        #  2: Separate left/right by centroid X coordinate
        centroids = center_of_mass(cleaned_mask, labeled_clean, [1, 2])
        order = sorted([1, 2], key=lambda i: centroids[i - 1][0])  # X coord

        # Since the original image is mirrored, larger X = left tibia
        idx_left = order[1]
        idx_right = order[0]

        left_mask = (labeled_clean == idx_left).astype(np.uint8)
        right_mask = (labeled_clean == idx_right).astype(np.uint8)

        # Save NIFTIs
        base = filename.replace("tibia_", "").replace(".nii.gz", "")
        nib.save(nib.Nifti1Image(left_mask, nii.affine), os.path.join(left_folder, f"left_tibia_{base}.nii.gz"))
        nib.save(nib.Nifti1Image(right_mask, nii.affine), os.path.join(right_folder, f"right_tibia_{base}.nii.gz"))

        # Preview slice
        z_mid = data.shape[2] // 2
        orig_slice = data[:, :, z_mid]
        left_slice = left_mask[:, :, z_mid]
        right_slice = right_mask[:, :, z_mid]

        overlay = np.zeros(orig_slice.shape + (3,), dtype=np.uint8)
        overlay[..., 0] = (left_slice > 0) * 255   # red
        overlay[..., 1] = (right_slice > 0) * 255  # green

        plt.figure(figsize=(5, 5))
        plt.imshow(orig_slice, cmap='gray')
        plt.imshow(overlay, alpha=0.5)
        plt.axis('off')
        plt.title(f"{base} - corte Z medio")
        plt.tight_layout()

        plt.savefig(os.path.join(left_folder, f"preview_{base}.png"), dpi=150)
        plt.close()

print(":) Segmentación, limpieza y visualización terminadas.")