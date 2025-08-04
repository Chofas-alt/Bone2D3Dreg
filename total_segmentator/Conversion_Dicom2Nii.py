import os
import zipfile
import tempfile
import SimpleITK as sitk
from tqdm import tqdm
import numpy as np

"""Script to read and convert DICOM files from zipped folders into NIfTI format.
Since the DICOM files of some subjects are split into multiple series,
this script merges them into a single 3D volume in the Z direction, however, we di not 
use this anymore."""

# Path congfig
zips_dir = "/usagers4/u139017/Proyecto/total_segmentator/NMDIDPRUEBA"
output_dir = "/usagers4/u139017/Documents/nii_files_THIN"


os.makedirs(output_dir, exist_ok=True)
print(f"Los archivos se guardarán en: {output_dir}")

target_folders = ['THIN_ST_L-EXT', 'THIN_ST_LOWER_EX']

def cargar_series_y_fusionar(dirpath):
    """Carga una o más series DICOM de una carpeta y las fusiona en Z."""
    reader = sitk.ImageSeriesReader()
    series_IDs = reader.GetGDCMSeriesIDs(dirpath)

    if not series_IDs:
        raise Exception("No se encontraron series DICOM en esta carpeta.")

    images = []
    for series_id in series_IDs:
        dicom_names = reader.GetGDCMSeriesFileNames(dirpath, series_id)
        reader.SetFileNames(dicom_names)
        image = reader.Execute()
        images.append(image)

    if len(images) == 1:
        return images[0]

    # Fusionar varias series en eje Z (si es necesario)
    sitk_volumes = []
    for img in images:
        arr = sitk.GetArrayFromImage(img)
        temp = sitk.GetImageFromArray(arr)
        temp.CopyInformation(img)  # cada uno tiene su info
        sitk_volumes.append(temp)

    final_image = sitk.JoinSeries(sitk_volumes)

    # Corregir spacing en Z (eje 2)
    spacing = list(images[0].GetSpacing())
    spacing.append(spacing[2])  # mismo espaciado en Z
    final_image.SetSpacing(spacing)

    # Mantener origin y direction
    final_image.SetOrigin(images[0].GetOrigin())
    final_image.SetDirection(images[0].GetDirection())

    return final_image


# Procesamiento por archivo zip
for zip_file in tqdm(os.listdir(zips_dir)):
    if not zip_file.endswith(".zip"):
        continue

    zip_path = os.path.join(zips_dir, zip_file)

    with tempfile.TemporaryDirectory() as tmpdir:
        try:
            # Descomprimir el zip en carpeta temporal
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                zip_ref.extractall(tmpdir)

            # Buscar carpeta DICOM relevante
            found = False
            for dirpath, dirnames, filenames in os.walk(tmpdir):
                if any(dirpath.endswith(target) for target in target_folders):
                    try:
                        print(f"→ Procesando {zip_file} desde: {dirpath}")
                        image = cargar_series_y_fusionar(dirpath)

                        # Nombre de salida
                        case_id = zip_file.replace(".zip", "").replace("case-", "lowExtCase-")
                        output_filename = f"{case_id}.nii.gz"
                        output_path = os.path.join(output_dir, output_filename)

                        sitk.WriteImage(image, output_path)
                        found = True
                        break  # ya procesamos este zip

                    except Exception as e:
                        print(f" Error leyendo DICOM en {dirpath}: {e}")
                        found = True  # para no seguir buscando
                        break

            if not found:
                print(f"No se encontró carpeta THIN en {zip_file}")

        except Exception as e:
            print(f"No se pudo procesar {zip_file}: {e}")
