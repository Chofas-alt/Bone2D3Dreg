close all, clear all, clc

%Read all images and convert into a pointcloud.
% Be aware of having the folder on the MATLAB path
carpeta = '/usagers4/u139017/Proyecto/PointCorrespondance/LEFT_TIBIAS';
archivos = dir(fullfile(carpeta, '*.nii.gz')); 
n = size(archivos);
n_tibias = n(1);

%% Convert to PointCLouds and Choosing template
clouds = {};
sizes = [];
names = strings(1, numel(archivos));  %in case of saving the poly align object with the correspondence id

for i = 1:length(archivos)
    mask = niftiread(archivos(i).name);
    [cloud, n] = mask2cloudDownsample(mask, false, 4); % Downsampling 
    clouds{i} = cloud;
    sizes(i) = n;
    names(i) = archivos(i).name; %All datas are savend in cells to have more structured data.
    fprintf('%d\n',round(i)); 
end

% Choose the template with least points
[~, idx_template] = min(sizes);
template = clouds{idx_template};
targetN = sizes(idx_template);   %We are using this later.


%% Via CPD we align the meshes with the rigid transformation
%Also we obtain the correspondence index using knn and the align clouds

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


%% Convert the align_clouds into a sorted matrix based on the correspondence index
mat_pos = zeros(targetN,3,n_tibias);
nubes_ordenadas = {};
for i = 1:n_tibias
    if i ~= idx_template
        nube = align_clouds{i};
    else 
        for j = 1:targetN
            mat_pos(j,:,idx_template) = [template.Location(j,1),template.Location(j,2), template.Location(j,3)]; % xyz coordinates
        end
        nubes_ordenadas{i} = pointCloud(mat_pos(:,:,i));
        continue %% This way we continue the same order as the archives names ;)
    end

    for j = 1:targetN
        mat_pos(j,:,i) = [nube.Location(corrIdx{i}(j),1),nube.Location(corrIdx{i}(j),2), nube.Location(corrIdx{i}(j),3)];
    end
    
    nubes_ordenadas{i} = pointCloud(mat_pos(:,:,i)); %we convert into sorted point cloud too, to help visualization.
end


%% --- PCA --- TO obtain eigenvectors and eigenvalues
[N_pts, ~, N_subj] = size(mat_pos); 

% Flatten/ squeeze to vectorized the matrix
P = reshape(mat_pos, [N_pts*3, N_subj]);

% Obtain the media for each point
p_mean = mean(P, 2);

% Centralized data
X = P - p_mean;
% %% visualize mean
% figure,
% pc_mean  = pointCloud(reshape(p_mean, [N_pts, 3]));
% pcshow(pc_mean), title('Mean shape')
% %%

% Obtain the empirical covariance matrix
S = (X * X.') / N_subj;

% Eigen-decomposition 
%Where Q is the matrix with eigenvectors. L is the diagional matrix with
%all eigenvalues
[Q, L] = eig(S);
[eigvals, idx] = sort(diag(L), 'descend');
Q = Q(:, idx);

%%
eigvals = eigvals(:);

% Obtain the explained variance for each mode
var_explained = eigvals / sum(eigvals);

% Scores for each subject
B = Q' * X;  % (3*N_pts, N_subj)
%%
figure;
pareto(var_explained), title('Explained variance for each mode')
%% Quick visualization



% --- Animación ---
num_sd = 3;       % 1 represents the natural standard deviation of the data; increasing this parameter exaggerates the shape changes for visualization.
n_frames = 120;    % frames per cycle
modes_to_show = 3;

for modo = 1:modes_to_show
    figure('Name', sprintf('Modo %d', modo), 'Color', 'w');
    
    for alpha = linspace(-num_sd, num_sd, n_frames)
        % Reconstruction
        shape_t = p_mean + alpha * sqrt(eigvals(modo)) * Q(:,modo);
        verts_t = reshape(shape_t, [N_pts, 3]);
        
        % Create mesh
        shp = alphaShape(verts_t, 12); % 12, can be tunned for better visualization
        [F, V] = boundaryFacets(shp);
        
        % Graficar
        trisurf(F, V(:,1), V(:,2), V(:,3), ...
            'FaceColor', [0.8 0.8 1], 'EdgeColor', 'none');
        axis equal; camlight; lighting gouraud;
        title(sprintf('Modo %d, alpha = %.2f SD', modo, alpha), 'FontSize', 14);
        drawnow;
    end
end

%% GIF CREATION, selection of parameters.
num_sd = 3;       % SD
n_frames = 90;    % frames 
modes_to_show = 3;
output_folder = '/usagers4/u139017/Proyecto/PointCorrespondance/PCA_Figs/GIFS';

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

%% --- GenerateGIFs ---
for modo = 1:modes_to_show
    gif_filename = fullfile(output_folder, sprintf('Modo_%d_pointcloud.gif', modo));
    
    figure('Color', 'w');
    
    for f = 1:n_frames
        alpha = linspace(-num_sd, num_sd, n_frames);
        
        % Resahping mean with eigen val and eigen vectors
        shape_t = p_mean + alpha(f) * sqrt(eigvals(modo)) * Q(:,modo);
        verts_t = reshape(shape_t, [N_pts, 3]);
        
        % Mostrar como point cloud
        scatter3(verts_t(:,1), verts_t(:,2), verts_t(:,3), 15, 'filled');
        axis equal; grid on;
        xlabel('X'); ylabel('Y'); zlabel('Z');
        title(sprintf('Mode %d (%.2f SD)', modo, alpha(f)), 'FontSize', 14);
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


% %%   THIS CAN BE ERASED LATER, IS JUST IAMGES FOR THE PRESENTATION
% modo = 3;
% num_sd = 2; % 1 es la desviacion real de los datos, entre mas grande mas exageramos los cambios
% shape_plus  = p_mean + num_sd*sqrt(eigvals(modo)) * Q(:,modo);
% shape_minus = p_mean - num_sd*sqrt(eigvals(modo)) * Q(:,modo);
% 
% % Convertir de vuelta a (N_pts, 3)
% shape_plus_coords  = reshape(shape_plus,  [N_pts, 3]);
% shape_minus_coords = reshape(shape_minus, [N_pts, 3]);
% 
% pc_plus  = pointCloud(shape_plus_coords);
% pc_minus = pointCloud(shape_minus_coords);
% pc_mean  = pointCloud(reshape(p_mean, [N_pts, 3]));
% 
% 
% figure,
% subplot(1,3,1), pcshow(pc_minus), title('Negative standard deviation mode:3')
% subplot(1,3,2), pcshow(pc_mean), title('Mean')
% subplot(1,3,3), pcshow(pc_plus), title('Positive standard deviation mode:3')
