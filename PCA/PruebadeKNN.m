clear all, close all, clc
carpeta = '/usagers4/u139017/Proyecto/PointCorrespondance/Prueba_tibias';
archivos = dir(fullfile(carpeta, '*.nii.gz')); % Cambia '*.txt' al patrón deseado

%% AT THE END OF THIS CODE IS ANOTHER METHOD TO VERIFY THE CORRESPONDENCE MAP.

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
    % ################################ PODRIAMOS AGREGAR LO DE LEER NOMBRES
    % PARA SABER A CUALCORRESPONDE.. PERO CREO QUE ASI ESTA BIEN
end

% Elegir como template el que tenga menor número de puntos
[~, idx_template] = min(sizes);
template = clouds{idx_template};
targetN = sizes(idx_template);  % Este será el número estándar para todos

%%
pc2 = clouds{1};
figure,pcshowpair(template, pc2)
title('Comparison template/PointCloud2')
legend({'template','pc2'},'TextColor','w')
legend('Location','southoutside')

%%
[tf2,pc2_rigid] = pcregistercpd(pc2,template, "Transform","Rigid");

% Visualizacion
figure, pcshowpair(template, pc2_rigid)
title('Comparison after rigid transformation')
%%
[idx, dist] = knnsearch(pc2_rigid.Location,template.Location);
%% checar correspondencia

z_vals = pc2.Location(:,3);  % Coordenada Z
z_norm = normalize(z_vals, 'range');  % Normalizar entre 0 y 1

cmap = autumn(256);  % 
color_idx = round(z_norm * 255) + 1;
colors_template = cmap(color_idx,:);  % Nx3 RGB


% colors_template tiene Nx3
colors_mapped = colors_template(idx, :);  % Tamaño: size(movingReg,1) x 3

% Visualiza ambos
figure;

subplot(1,2,1);
pcshow(pc2.Location, colors_template);
title('Template (gradiente por Z)');

subplot(1,2,2);
pcshow(template.Location, colors_mapped);
title('Moving original coloreado por correspondencia');

%% LA PRUEBA DEL INIDCE FALSOOO !!
idx_false = idx;
remplazo = ones(size(idx(6000:end)))';
idx_false(6000:end) = remplazo;

% colors_template tiene Nx3
colors_mapped = colors_template(idx_false, :);  % Tamaño: size(movingReg,1) x 3

% Visualiza ambos
figure;

subplot(1,2,1);
pcshow(pc2.Location, colors_template);
title('Template (gradiente por Z)');

subplot(1,2,2);
pcshow(template.Location, colors_mapped);
title('Moving original coloreado por correspondencia');

%% PC3
pc3 = clouds{3};
[~,pc3_rigid] = pcregistercpd(pc3,template, "Transform","Rigid");
[idx3, ~] = knnsearch(pc3_rigid.Location,template.Location);

z_vals = pc3.Location(:,3);  % Coordenada Z
z_norm = normalize(z_vals, 'range');  % Normalizar entre 0 y 1

cmap = autumn(256);  % 
color_idx_3 = round(z_norm * 255) + 1;
colors_template3 = cmap(color_idx_3,:);  % Nx3 RGB
colors_mapped_3 = colors_template3(idx3, :);

figure;

subplot(1,2,1);
pcshow(pc3.Location, colors_template3);
title('Template (gradiente por Z)');
subplot(1,2,2);
pcshow(template.Location, colors_mapped_3);
title('Moving del pc3');


%% other visual method to verify the correct correspondence between pointclouds.

N = 5500;
cyan = [0 1 1];
% ay = size(idx(N:N+20));
% rep = [];
% 
% for i = 1:ay(1)
%     rep = cat(1, rep, cyan);
% end

color_prueba = colors_template;
color_prueba_3= colors_template3;

color_prueba(idx(N),:) = cyan;
color_prueba_3(idx3(N),:) = cyan;

colors_mapped_3(N,:) = cyan;

figure;
subplot(1,3,1)
pcshow(pc2.Location, color_prueba);
title('PC2 color changed')

subplot(1,3,2)
pcshow(pc3.Location, color_prueba_3);
title('PC3 color changed')

subplot(1,3,3)
pcshow(template.Location, colors_mapped_3);
title('template color changed')
