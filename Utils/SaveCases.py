import os
import zipfile
import tempfile
import SimpleITK as sitk
from tqdm import tqdm
import dicom2nifti


"""This script decompresses .zip files containing DICOMs, searches for specific folders, and converts the DICOM images with a specific name — since in this case we are only interested in the lower extremity — into NIfTI format (.nii)."""

#La cosa es que a veces la carpeta de interes... que se va a cambiar por THIN_ST_L-EXT
# guarda la pierna entera como 2 .nii diferentes, y a veces guarda la pierna entera como un .nii, y queremos que
# siempre se guarde como un .nii, y que si hay 2 .nii diferentes, se guarden como una sola tmb. En la misma carpeta... 

# # Ruta a donde están todos los .zip
# zips_dir = "/run/media/u139017/Elements/NMDID"  
# output_dir = "/usagers4/u139017/Documents/nii_files_THIN"
# os.makedirs(output_dir, exist_ok=True)
# print(f"Los archivos se guardarán en: {output_dir}")


# target_folders = ['BONE_L-EXT_3X3', 'BONE_LWR_EXT_3X3']
# count = 1

# for zip_file in tqdm(os.listdir(zips_dir)):
#     if not zip_file.endswith(".zip"):
#         continue

#     zip_path = os.path.join(zips_dir, zip_file)
    
#     with tempfile.TemporaryDirectory() as tmpdir:
#         try:
#             # Descomprimir el .zip en temporal
#             with zipfile.ZipFile(zip_path, 'r') as zip_ref:
#                 zip_ref.extractall(tmpdir)

#             # Buscar carpeta tipo: omi/incomingdir/case-xxxxx/standard_head_neck/BONE...
#             for dirpath, dirnames, filenames in os.walk(tmpdir):
#                 if any(dirpath.endswith(target) for target in target_folders):
#                     try:
#                         reader = sitk.ImageSeriesReader()
#                         dicom_names = reader.GetGDCMSeriesFileNames(dirpath)
#                         reader.SetFileNames(dicom_names)
#                         image = reader.Execute()

#                         # Nombre de salida
#                         case_id = zip_file.replace(".zip", "").replace("case-", "lowExtCase-")
#                         output_filename = f"{case_id}.nii"
#                         output_path = os.path.join(output_dir, output_filename)

#                         sitk.WriteImage(image, output_path)
#                         break  # Ya procesó este zip

#                     except Exception as e:
#                         print(f"Error leyendo DICOM en {dirpath}: {e}")
#         except Exception as e:
#             print(f"No se pudo procesar {zip_file}: {e}")


# Paths
zips_dir = "/run/media/u139017/Elements/NMDID2" # Change this to your actual path or the original dataset path
output_dir = "/usagers4/u139017/Documents/nii_files" # Change this to your desired output path
os.makedirs(output_dir, exist_ok=True)
print(f"The archives will save in: {output_dir}")

# Folder names to look for
target_folders = ['THIN_ST_L-EXT', 'THIN_ST_LOWER_EX']

for zip_file in tqdm(os.listdir(zips_dir)):
    if not zip_file.endswith(".zip"):
        continue

    zip_path = os.path.join(zips_dir, zip_file)

    with tempfile.TemporaryDirectory() as tmpdir:
        try:
            # Unzip
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                zip_ref.extractall(tmpdir)

            # Search for target folders
            matched_folder = None
            for dirpath, dirnames, filenames in os.walk(tmpdir):
                if any(dirpath.endswith(target) for target in target_folders):
                    matched_folder = dirpath
                    break

            if matched_folder:
                try:
                    # Rename the folder with the specific name with the case ID
                    case_id = zip_file.replace(".zip", "").replace("case-", "lowExtCase-")
                    output_filename = f"{case_id}.nii.gz"
                    output_path = os.path.join(output_dir, output_filename)

                    # Create output directory if it doesn't exist
                    os.makedirs(os.path.dirname(output_path), exist_ok=True)

                    # Convert DICOM → NIfTI
                    dicom2nifti.convert_directory(matched_folder, os.path.dirname(output_path))

                    # Renname the resulting NIfTI file
                    for f in os.listdir(os.path.dirname(output_path)):
                        if f.endswith(".nii") or f.endswith(".nii.gz"):
                            os.rename(os.path.join(os.path.dirname(output_path), f), output_path)
                            break

                except Exception as e:
                    print(f"❌ Error converting {zip_file}: {e}")
            else:
                print(f"⚠️ Didn't found file {zip_file}")

        except Exception as e:
            print(f"❌ error {zip_file}: {e}")

