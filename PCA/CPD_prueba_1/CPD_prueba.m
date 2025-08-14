% Primera prueba usando el metodo de CPD como funcion implementada de
% MATLAB.
clear all, close all, clc

path_nii_100308 ='/usagers4/u139017/Documents/Tibia_Seg_Separada/left/left_tibia_100308.nii.gz';
path_nii_100324 ='/usagers4/u139017/Documents/Tibia_Seg_Separada/left/left_tibia_100324.nii.gz';
path_nii_105710 ='/usagers4/u139017/Documents/Tibia_Seg_Separada/left/left_tibia_105710.nii.gz';


nii_1 = niftiread(path_nii_100308);
nii_2 = niftiread(path_nii_105710);
nii_3 = niftiread(path_nii_100324);


%% Utilizando la funcion que creamos, convertimos de volumen binario a nube de punts de las superficie.
ptCloud_1 = mask2cloud(nii_1);
ptCloud_2 = mask2cloud(nii_2);
ptCloud_3 = mask2cloud(nii_3);

%% ya que convertimos las imagenes, vamos a visualizar sus pares.

figure(1),pcshowpair(ptCloud_1, ptCloud_2)
title('Comparación mascara1 respescto mascara2')

figure(2), pcshowpair(ptCloud_1,ptCloud_3)
title('Comparacion mask1 respecto mask3')

%% Vamos a ahcer la prueba haciendo un downsampling, ya que eso recomienda la referencia
ptCloud1Downsampled = pcdownsample(ptCloud_1,'gridAverage',2);
ptCloud2Downsampled = pcdownsample(ptCloud_2,'gridAverage',2);
ptCloud3Downsampled = pcdownsample(ptCloud_3,'gridAverage',2);

%% Visual del downsampling 1 y 2
figure(3),pcshowpair(ptCloud1Downsampled, ptCloud2Downsampled)


%% HACER EL CPD
[tform,cloud1_reg] = pcregistercpd(ptCloud1Downsampled,ptCloud2Downsampled);

%% Display the downsampled point clouds after registration.
figure(4)
pcshowpair(cloud1_reg,ptCloud2Downsampled,'MarkerSize',50)
xlabel('X')
ylabel('Y')
zlabel('Z')
title('Point clouds after registration')
legend({'Moving point cloud','Fixed point cloud'},'TextColor','w')
legend('Location','southoutside')