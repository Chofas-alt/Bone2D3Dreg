clear all, close all, clc;
%%
%Read all images and convert into a pointcloud.
carpeta = '/usagers4/u139017/Proyecto/PointCorrespondance/LEFT_TIBIAS';
archivos = dir(fullfile(carpeta, '*.nii.gz')); 
n = size(archivos);
n_tibias = n(1);
%%
clouds = {};
sizes = [];
names = strings(1, numel(archivos)); 

for i = 1:length(archivos)
    mask = niftiread(archivos(i).name);
    [cloud, n] = mask2cloudDownsample(mask, false, 5); % Downsampling inicial
    clouds{i} = cloud;
    sizes(i) = n;
    names(i) = archivos(i).name;
    fprintf('%d\n',round(i));
end

% Choose the template with least points
[~, idx_template] = min(sizes);
template = clouds{idx_template};
targetN = sizes(idx_template);  

%%
align_clouds = {};
corrIdx = {};

for i = 1:length(archivos)
    if names(i) == names(idx_template)
        continue;  % ya está bien
    end
    pc = clouds{i};
    [~,pc_rigid] = pcregistercpd(pc,template, "Transform","Rigid");
    align_clouds{i} = pc_rigid; 
    [idx, ~] = knnsearch(pc_rigid.Location,template.Location);
    corrIdx{i} = idx;
    fprintf('%d\n',round(i));
end

%% Pasar a vector?
mat_pos = zeros(targetN,3,n_tibias);
nubes_ordenadas = {};
for i = 1:n_tibias
    if i ~= idx_template
        nube = align_clouds{i};
    else 
        for j = 1:targetN
            mat_pos(j,:,idx_template) = [template.Location(j,1),template.Location(j,2), template.Location(j,3)]; %ASI DE UNA VEZ PONEMOS CUAL ES CUAL.
        end
        nubes_ordenadas{i} = pointCloud(mat_pos(:,:,i));
        continue %%PARA NO PERDER LOS INDICES DE A QUE SUJETO SE REFIERE CADA UNO ;)
    end

    for j = 1:targetN
        mat_pos(j,:,i) = [nube.Location(corrIdx{i}(j),1),nube.Location(corrIdx{i}(j),2), nube.Location(corrIdx{i}(j),3)];
    end
    
    nubes_ordenadas{i} = pointCloud(mat_pos(:,:,i));
end


%%
figure;
subplot(2,3,1)
pcshow(clouds{1}.Location);
title('PC2')

subplot(2,3,2)
pcshow(clouds{3}.Location);
title('PC3')

subplot(2,3,3)
pcshow(template.Location);
title('template')

subplot(2,3,4)
pcshow(nubes_ordenadas{1}.Location);
title('PC2 ALIGN')

subplot(2,3,5)
pcshow(nubes_ordenadas{9}.Location);
title('PC3 ALIGN')

subplot(2,3,6)
pcshow(nubes_ordenadas{idx_template}.Location);
title('template')

%% A ver COMO PODEMOS LLEGAR AL PCA
% Suponiendo que ya tienes mat_pos: (N_puntos, 3, N_sujetos)

[N_pts, ~, N_subj] = size(mat_pos); %Aqui sacamos el tama;o 
% 1) Pasar cada sujeto a un vector columna de tamaño (3*N_pts, 1)

P = zeros(3*N_pts, N_subj); %aqui ya generamos el vector aplanado/flatten/como le queramos decir
for i = 1:N_subj
    coords = squeeze(mat_pos(:,:,i));  % (N_pts, 3)
    P(:,i) = coords(:);                % vectorizar en columna
end

% 2) Calcular la media de todos los sujetos
p_mean = mean(P, 2);  % (3*N_pts, 1)

% 3) Restar la media
X = P - p_mean;

% 4) Matriz de covarianza empírica
S = (X * X.') / N_subj;   % (3*N_pts, 3*N_pts)
%%
Smat = cov(X'); %%% pero aqui nos queda de 23por23

%%
% 5) Descomposición en valores y vectores propios (PCA)
[Q, L] = eig(S);
[eigvals, idx] = sort(diag(L), 'descend');
Q = Q(:, idx);       % eigenvectores ordenados
eigvals = eigvals(:);

% 6) Proporción de varianza por modo
var_explained = eigvals / sum(eigvals);

% 7) Scores para cada sujeto
B = Q' * X;  % (3*N_pts, N_subj)

%% Para visualizar una variación de un modo específico (ej. primer modo)
modo = 2;
num_sd = 2; % 1 es la desviacion real de los datos, entre mas grande mas exageramos los cambios
shape_plus  = p_mean + num_sd*sqrt(eigvals(modo)) * Q(:,modo);
shape_minus = p_mean - num_sd*sqrt(eigvals(modo)) * Q(:,modo);

% Convertir de vuelta a (N_pts, 3)
shape_plus_coords  = reshape(shape_plus,  [N_pts, 3]);
shape_minus_coords = reshape(shape_minus, [N_pts, 3]);

pc_plus  = pointCloud(shape_plus_coords);
pc_minus = pointCloud(shape_minus_coords);
pc_mean  = pointCloud(reshape(p_mean, [N_pts, 3]));

% Ahora puedes usar pcshow(pc_plus) o similar para ver la variación

figure,
subplot(1,3,1), pcshow(pc_minus), title('MINUUS')
subplot(1,3,2), pcshow(pc_mean), title('Mean')
subplot(1,3,3), pcshow(pc_plus), title('plus')

%%
%% --- PCA ---
[N_pts, ~, N_subj] = size(mat_pos);

% Vectorizar todos los sujetos
P = reshape(mat_pos, [N_pts*3, N_subj]);

% Media
p_mean = mean(P, 2);

% Centrar datos
X = P - p_mean;

% Covarianza empírica
S = (X * X.') / N_subj;

% Eigen-descomposición
[Q, L] = eig(S);
[eigvals, idx] = sort(diag(L), 'descend');
Q = Q(:, idx);
%%
% --- Animación ---
num_sd = 2;       % número de desviaciones estándar
n_frames = 60;    % frames por ciclo
modes_to_show = 3;

for modo = 1:modes_to_show
    figure('Name', sprintf('Modo %d', modo), 'Color', 'w');
    
    for alpha = linspace(-num_sd, num_sd, n_frames)
        % Reconstrucción de la forma
        shape_t = p_mean + alpha * sqrt(eigvals(modo)) * Q(:,modo);
        verts_t = reshape(shape_t, [N_pts, 3]);
        
        % Crear malla aproximada desde puntos
        shp = alphaShape(verts_t, 12); % 5 = radio aproximado, ajustar si sale raro
        [F, V] = boundaryFacets(shp);
        
        % Graficar
        trisurf(F, V(:,1), V(:,2), V(:,3), ...
            'FaceColor', [0.8 0.8 1], 'EdgeColor', 'none');
        axis equal; camlight; lighting gouraud;
        title(sprintf('Modo %d, alpha = %.2f SD', modo, alpha), 'FontSize', 14);
        drawnow;
    end
end
%%
num_sd = 2;
n_frames = 60;
modes_to_show = 3;

for modo = 1:modes_to_show
    figure('Name', sprintf('Modo %d - PointCloud', modo));
    
    for f = 1:n_frames
        alpha = linspace(-num_sd, num_sd, n_frames);
        
        % Reconstrucción del modo
        shape_t = p_mean + alpha(f) * sqrt(eigvals(modo)) * Q(:,modo);
        verts_t = reshape(shape_t, [N_pts, 3]);
        
        % Mostrar como point cloud
        scatter3(verts_t(:,1), verts_t(:,2), verts_t(:,3), 15, 'filled');
        axis equal; 
        camlight; lighting gouraud;
        title(sprintf('Modo %d (%.2f SD)', modo, alpha(f)), 'FontSize', 14);
        drawnow;
    end
end

%%

%% --- Parámetros ---
num_sd = 2;       % desviaciones estándar
n_frames = 30;    % frames por ciclo
modes_to_show = 3;
output_folder = 'PCA_pointcloud_gifs';

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

[N_pts, ~, N_subj] = size(mat_pos);

% Vectorizar todos los sujetos
P = reshape(mat_pos, [N_pts*3, N_subj]);

% Media y centrar
p_mean = mean(P, 2);
X = P - p_mean;

% Covarianza y PCA
S = (X * X.') / N_subj;
[Q, L] = eig(S);
[eigvals, idx] = sort(diag(L), 'descend');
Q = Q(:, idx);

%% --- Generar GIFs ---
for modo = 1:modes_to_show
    gif_filename = fullfile(output_folder, sprintf('Modo_%d_pointcloud.gif', modo));
    
    figure('Color', 'w');
    
    for f = 1:n_frames
        alpha = linspace(-num_sd, num_sd, n_frames);
        
        % Reconstrucción de la forma
        shape_t = p_mean + alpha(f) * sqrt(eigvals(modo)) * Q(:,modo);
        verts_t = reshape(shape_t, [N_pts, 3]);
        
        % Mostrar como point cloud
        scatter3(verts_t(:,1), verts_t(:,2), verts_t(:,3), 15, 'filled');
        axis equal; grid on;
        xlabel('X'); ylabel('Y'); zlabel('Z');
        title(sprintf('Modo %d (%.2f SD)', modo, alpha(f)), 'FontSize', 14);
        view(3); camlight; lighting gouraud;
        drawnow;
        
        % Captura y guardar frame
        frame = getframe(gcf);
        [im, cmap] = rgb2ind(frame2im(frame), 256);
        if f == 1
            imwrite(im, cmap, gif_filename, 'gif', 'LoopCount', inf, 'DelayTime', 0.1);
        else
            imwrite(im, cmap, gif_filename, 'gif', 'WriteMode', 'append', 'DelayTime', 0.1);
        end
    end
end
