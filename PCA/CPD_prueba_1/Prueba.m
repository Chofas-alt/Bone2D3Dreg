
%{
Hola, resumen de lo que hace el pcd, despues de leer el articulo de como
funciona el algoritmo. 

tform = pcregistercpd(moving,fixed) returns a transformation that registers a moving point cloud with a fixed point cloud 
using the CPD algorithm. 

[tform,movingReg] = pcregistercpd(___) also returns the transformed point cloud that aligns with the fixed point cloud.

[tform,movingReg,rmse] = pcregistercpd(___) also returns the root mean square error of the Euclidean distance between 
the aligned point clouds.

[___] = pcregistercpd(___,Name=Value) specifies options using one or more name-value arguments in addition to any 
combination of arguments from previous syntaxes. For example, MaxIterations=20 stops the CPD algorithm after 20 iterations.


%}

handData = load('hand3d.mat');
moving = handData.moving;
fixed = handData.fixed;

%%
movingDownsampled = pcdownsample(moving,'gridAverage',0.03);
fixedDownsampled = pcdownsample(fixed,'gridAverage',0.03);

%% To improve the efficiency and accuracy of the CPD registration algorithm, downsample the moving and the fixed point clouds.

figure
pcshowpair(movingDownsampled,fixedDownsampled,'MarkerSize',50)
xlabel('X')
ylabel('Y')
zlabel('Z')
title('Point clouds before registration')
legend({'Moving point cloud','Fixed point cloud'},'TextColor','w')
legend('Location','southoutside')

%% Perform non-rigid registration using the CPD algorithm.
[tform,movingReg] = pcregistercpd(movingDownsampled,fixedDownsampled);

%% Display the downsampled point clouds after registration.

figure
pcshowpair(movingReg,fixedDownsampled,'MarkerSize',50)
xlabel('X')
ylabel('Y')
zlabel('Z')
title('Point clouds after registration')
legend({'Moving point cloud','Fixed point cloud'},'TextColor','w')
legend('Location','southoutside')

%%
