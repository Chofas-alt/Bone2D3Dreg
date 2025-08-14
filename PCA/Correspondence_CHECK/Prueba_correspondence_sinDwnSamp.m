% Supón que tienes varias máscaras en un folder
clear all, close all, clc

carpeta = '/usagers4/u139017/Proyecto/PointCorrespondance/Prueba_tibias';

% Obtiene una lista de archivos en la carpeta
archivos = dir(fullfile(carpeta, '*.nii.gz')); %
%%   PARA LEER Y GUARDAR EN UNA ESTRUCTURA LAS POINT CLOUDS
clouds = {};
sizes = [];
names = strings(1, numel(archivos)); 

for i = 1:length(archivos)
    mask = niftiread(archivos(i).name);
    [cloud, n] = mask2cloudDownsample(mask, false, 3.5); % Downsampling inicial
    clouds{i} = cloud;
    sizes(i) = n;
    names(i) = archivos(i).name;
    % ################################ Saving names with same index in case
    % wwe need to save the .poly objects
end
%% AQUI DOWNSAMPLEAMOS AL MENOR... vamos a ver como se ven. 

moved_clouds = {};

% We are choosin as template the pointcloud with least points
[~, idx_template] = min(sizes);
template = clouds{idx_template};
targetN = sizes(idx_template);  % 

% % Rehacer las demás nubes con ese targetNumPoints si quieres: We didnt
% use this part, since the downsample was random and created a lot of
% missing data.
% for i = 1:length(clouds)
%     if names(i) == names(idx_template)
%         continue;  % ya está bien
%     end
%     mask = niftiread(archivos(i).name);
%     [cloud_fixed, ~] = mask2cloudDownsample(mask, false, 3.5, targetN);
%     moved_clouds{i} = cloud_fixed;
%     % ahora cloud_fixed tiene los puntos en correspondencia potencial
% end

%%
pc2 = clouds{3};

%% 
figure,pcshowpair(template, pc2)
title('Comparison template/PointCloud2')
legend({'template','pc2'},'TextColor','w')
legend('Location','southoutside')
%%
[tf2,pc2_rigid] = pcregistercpd(pc2,template, "Transform","Rigid");
%%
% Visualizacion
figure, pcshowpair(template, pc2_rigid)
title('Comparison after rigid transformation')
legend({'template','pc2'},'TextColor','w')
legend('Location','southoutside')
%% 
[idx, dist] = knnsearch(template.Location, pc2_rigid.Location);
%% To check correspondence we  generate a gradiente by the value z, and a color map based on thar value.
%then we use the idx (the index that maps each coordanate from the point cloud of interest to the template)
z_vals = template.Location(:,3);  % Coordenada Z
z_norm = normalize(z_vals, 'range');  % Normalizar entre 0 y 1

cmap = autumn(256);  % 
color_idx = round(z_norm * 255) + 1;
colors_template = cmap(color_idx,:);  % Nx3 RGB


% colors_template tiene Nx3
colors_mapped = colors_template(idx, :);  % Tamaño: size(movingReg,1) x 3

% Visualize
figure;

subplot(1,2,1);
pcshow(template.Location, colors_template);
title('Template colored based on axis z');

subplot(1,2,2);
pcshow(pc2.Location, colors_mapped);
title('Original Point Cloud colored using the correspondence');

%% IN here we created a false index, to use the same number for the last points :)

idx_false = idx;
remplazo = ones(size(idx(7000:end)))';
idx_false(7000:end) = remplazo;

% colors_template tiene Nx3
colors_mapped = colors_template(idx_false, :);  % Tamaño: size(movingReg,1) x 3

% Visualiza ambos
figure;
subplot(1,2,1);
pcshow(template.Location, colors_template);
title('Template');

subplot(1,2,2);
pcshow(pc2.Location, colors_mapped);
title('Point Cloud colored using false Idx');

