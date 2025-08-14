function [ptCloud, numPoints] = mask2cloudDownsample(mask, visual, gridStep, targetNumPoints)
    % COnverts binary mask into a pointcloud with a downsample
    % If targetNumpoints will downsample into the target given (we didnt use this function at the end)

    if nargin < 2 || isempty(visual)
        visual = false;
    end
    if nargin < 3 || isempty(gridStep)
        gridStep = 4;
    end

    % Obtain surface
    fv = isosurface(mask, 0.5); 
    ptCloudRaw = pointCloud(fv.vertices);

    % first downsample (más controlado)
    ptCloud = pcdownsample(ptCloudRaw, 'gridAverage', gridStep);
    numPoints = ptCloud.Count;

    % TARGET POINTS
    if nargin == 4 && ~isempty(targetNumPoints)
        if numPoints > targetNumPoints
            % Selección aleatoria de puntos (sin reemplazo)
            randIdx = randperm(numPoints, targetNumPoints);
            ptCloud = select(ptCloud, randIdx);
            numPoints = ptCloud.Count;
        elseif numPoints < targetNumPoints
            warning('No se puede upsamplear. Este set tiene menos puntos que el template.');
        end
    end

    % Visualization if needed(just as shortcut)
    if visual
        figure;
        pcshow(ptCloud);
        title(sprintf('Point Cloud (%d puntos)', numPoints));
    end
end
