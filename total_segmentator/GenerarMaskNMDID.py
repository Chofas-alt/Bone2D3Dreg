import os
import tarfile
import shutil
import pydicom
import matplotlib.pyplot as plt
import numpy as np
import nibabel as nib
import numpy as np
import time

from ipywidgets import interact
from IPython.display import display

from totalsegmentator.python_api import totalsegmentator


"""Scrip to read the NIFTI files generated from DICOM files and generate masks for appendicular bones.
Using TotalSegmentator for this purpose.
If this does not work, please check the TotalSegmentatorCT notebook for more details"""

licencia = 'aca_NO69LYNYUJAMI2'#This license number works, however, replace with your actual license
# Path configuration
input_dir = "/usagers4/u139017/Documents/nii_files_THIN"  
output_base = "/usagers4/u139017/Documents/THIN_MASK"  

a = 0
for filename in os.listdir(input_dir):
    if filename.endswith(".nii.gz"):
        input_path = os.path.join(input_dir, filename)

        base_name = os.path.splitext(filename)[0]       # lowExtCase-100137
        case_number = base_name.split("-")[-1]          # 100137

        output_folder = os.path.join(output_base, f"Mask{case_number}")
        a += 1
        print(a, output_folder)
        totalsegmentator(input_path, output_folder, fast=False, task='appendicular_bones',ml = False, higher_order_resampling= True,
                 remove_small_blobs=True, license_number=licencia)
        time.sleep(0.5)  # To ensure the import order is correct
