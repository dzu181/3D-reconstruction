% Code nay loi vi co Uncalibrated Rectification nen khong dung duoc
% tham so stereoParams; va rectify khong nhan du diem.
%% Rectify with the modded code
cvex1('7.jpg', '8.jpg');
global J1
global J2

%% Draw Disparity Map 
%J1gray = rgb2gray(J1);
%J2gray = rgb2gray(J2);
disparityMap = disparitySGM(J1, J2);
%disparityMap = disparitySGM(J1gray, J2gray);

figure;
imshow(disparityMap, [0, 64]);
title('Disparity Map');
colormap jet
colorbar

%% Tao ra 3D point cloud
%points3D = reconstructScene(disparityMap, stereoParams);

% Convert to meters and create a pointCloud object
%points3D = points3D ./ 1000;
%ptCloud = pointCloud(points3D, 'Color', J1);

% Create a streaming point cloud viewer
%player3D = pcplayer([-3, 3], [-3, 3], [0, 8], 'VerticalAxis', 'y', ...
%    'VerticalAxisDir', 'down');

% Visualize the point cloud
%view(player3D, ptCloud);