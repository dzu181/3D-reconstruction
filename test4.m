I1 = imread('15.jpg');
I2 = imread('16.jpg');
%% Rectify images
[J1, J2] = rectifyStereoImages(I1, I2, stereoParams, 'OutputView','full');
%[J1,J2] = rectifyStereoImages(I1,I2,stereoParams, ...
%  'OutputView','valid');
figure;
imshow(stereoAnaglyph(J1, J2));
title('Rectified Images');
%% Disparity map
J1gray  = rgb2gray(J1);
J2gray  = rgb2gray(J2);
disparityMap = disparitySGM(J1gray, J2gray);
figure;
imshow(disparityMap, [0, 64]);
title('Disparity Map');
colormap jet
colorbar
%% 3D reconstruction
points3D = reconstructScene(disparityMap, stereoParams);
% Convert to meters and create a pointCloud object
points3D = points3D ./ 1000;
ptCloud = pointCloud(points3D, 'Color', J1);

% Compute limits to display point cloud
%lower = min([ptCloud.XLimits ptCloud.YLimits]);
%upper = max([ptCloud.XLimits ptCloud.YLimits]);
  
%xlimits = [lower upper];
%ylimits = [lower upper];
%zlimits = ptCloud.ZLimits;

% Create a streaming point cloud viewer
player3D = pcplayer([-8, 8], [-8, 8], [0, 8], 'VerticalAxis', 'y', ...
    'VerticalAxisDir', 'down');

% Visualize the point cloud
view(player3D, ptCloud);