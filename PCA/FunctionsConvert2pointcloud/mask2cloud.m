%% First function to convert to PC and downsample
function ptCloud = mask2cloud(mask, visual, gridStep)
    if nargin < 2
        visual = false; % V
    end
    if nargin < 3
        gridStep = 5; % Downsampling 
    end

    % Extracts surface
    fv = isosurface(mask, 0.5); 
    ptCloudRaw = pointCloud(fv.vertices);

    %  downsampling
    ptCloud = pcdownsample(ptCloudRaw, 'gridAverage', gridStep);
    num = ptCloud.Count;
    % Visualize
    if visual
        figure, pcshow(ptCloud);
        title(['Point Cloud (bwperim, gridStep = ', num2str(gridStep), ')','#PTS:',num2str(num)]);
    end
end
