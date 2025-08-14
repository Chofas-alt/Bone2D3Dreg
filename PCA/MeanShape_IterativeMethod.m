clear all, close all, clc;

%Read all images and convert into a pointcloud.
carpeta = '/usagers4/u139017/Proyecto/PointCorrespondance/LEFT_TIBIAS';
archivos = dir(fullfile(carpeta, '*.nii.gz')); % 
n = size(archivos);

clouds = {};
sizes = [];
names = strings(1, numel(archivos)); 

for i = 1:length(archivos)
    mask = niftiread(archivos(i).name);
    [cloud, n] = mask2cloudDownsample(mask, false, 5); % Downsampling 
    clouds{i} = cloud;
    sizes(i) = n;
    names(i) = archivos(i).name;
    fprintf('%d\n',round(i));
end

% Choose the template with least points
[~, idx_template] = min(sizes);
template = clouds{idx_template};
targetN = sizes(idx_template);  

%% for every dataset, obtain cell for pcd and idx from knn 
align_clouds = {};
corrIdx = {};

for i = 1:length(archivos)
    if names(i) == names(idx_template)
        continue;  %
    end
    pc = clouds{i};
    [~,pc_rigid] = pcregistercpd(pc,template, "Transform","Rigid");
    align_clouds{i} = pc_rigid; 
    [idx, ~] = knnsearch(pc_rigid.Location,template.Location);
    corrIdx{i} = idx;
    fprintf('%d\n',round(i));
end

%% just to visualize

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
pcshow(align_clouds{1}.Location);
title('PC2 ALIGN')

subplot(2,3,5)
pcshow(align_clouds{3}.Location);
title('PC3 ALIGN')

subplot(2,3,6)
pcshow(template.Location);
title('template')

%% Obtain mean with iterative method
pos_mean = [];
pc_mean = [];
for i = 1:targetN
    x = template.Location(i,1);
    y = template.Location(i,2);
    z = template.Location(i,3);
    
    for j = 1:length(archivos)
        if j == idx_template
            continue;
        end
        xj = align_clouds{j}.Location(corrIdx{j}(i),1);
        yj = align_clouds{j}.Location(corrIdx{j}(i),2);
        zj = align_clouds{j}.Location(corrIdx{j}(i),3);
        x = cat(1,x,xj);
        y = cat(1,y,yj);
        z = cat(1,z,zj);
    end
    x_mean = mean(x);
    y_mean = mean(y);
    z_mean = mean(z);
    pos_mean(i,:) = [x_mean, y_mean, z_mean];
end
pc_mean = pointCloud(pos_mean);

figure;
pcshow(pc_mean.Location);
title('MEAN SHAPE')
