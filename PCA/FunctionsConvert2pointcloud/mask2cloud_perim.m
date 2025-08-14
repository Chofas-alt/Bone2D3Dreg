%% Function with other method to obtain the point cloud.
function ptCloud = mask2cloud_perim(mask, visual, gridStep)
    if nargin < 2
        visual = false; % SO we dont have to add more code to have a quick visualization
    end
    if nargin < 3
        gridStep = 5; % Downsampling 
    end

    % Obtener la superficie perimetral de la máscara binaria
    surfMask = bwperim(mask);

    % Extracts coordinates of the points which values is 1
    [idxX, idxY, idxZ] = ind2sub(size(surfMask), find(surfMask));
    surfacePoints = [idxX, idxY, idxZ];

    % Crear la pointCloud original
    ptCloudRaw = pointCloud(surfacePoints);

    % Apply downsampling with gridAverage
    ptCloud = pcdownsample(ptCloudRaw, 'gridAverage', gridStep);
    num = ptCloud.Count;
    % 
    if visual
        figure, pcshow(ptCloud);
        title(['Point Cloud (bwperim, gridStep = ', num2str(gridStep), ')','#PTS:',num2str(num)]);
    end
end
