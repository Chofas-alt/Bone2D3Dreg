% Pruebas Para obtener vertices/pruebas de downsampling, fastmarching,
% gridstep
clear all, close all, clc

% leer el archivo que usaremos como prueba.
path_nii_100308 ='/usagers4/u139017/Documents/Tibia_Seg_Separada/left/left_tibia_100308.nii.gz';
nii_1 = niftiread(path_nii_100308);

path_nii_100324 ='/usagers4/u139017/Documents/Tibia_Seg_Separada/left/left_tibia_100324.nii.gz';
nii_2 = niftiread(path_nii_100324);



%% MASK TO CLOUD
mask = nii_1;
fv = isosurface(mask, 0.5); % threshold típico para máscaras binarias
ptCloud = pointCloud(fv.vertices);

figure, pcshow(ptCloud);
num = ptCloud.Count;
titulo = sprintf('PointCloud visual, puntos: %d', num);
title(titulo);
%%
ptCloud_2 = mask2cloud_perim(nii_2,true);

%%
ptCloud1Downsampled = pcdownsample(ptCloud,'gridAverage',5);
figure, pcshow(ptCloud1Downsampled);
num = ptCloud1Downsampled.Count;

titulo = sprintf('PointCloud visual, puntos: %d', num);
title(titulo);


%% Comparacion con un downsampling mucho menor
figure,pcshowpair(ptCloud1Downsampled, ptCloud_2)
title('Comparación mascara1 respescto mascara2')


%%
[tform,cloud1_reg] = pcregistercpd(ptCloud_2,ptCloud1Downsampled,"MaxIterations",25);

%% Display the downsampled point clouds after registration.
figure
pcshowpair(cloud1_reg,ptCloud1Downsampled,'MarkerSize',50)
xlabel('X')
ylabel('Y')
zlabel('Z')
title('Point clouds after registration')
legend({'Moving point cloud','Fixed point cloud'},'TextColor','w')
legend('Location','southoutside')