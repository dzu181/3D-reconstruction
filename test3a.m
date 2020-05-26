close all
%% Prepare images
I1 = imread('5.jpg');
I2 = imread('6.jpg');
% Undistort them!
I1 = undistortImage(I1, cameraParams);
I2 = undistortImage(I2, cameraParams);
% figure
% imshowpair(I1, I2, 'montage');
% title('Undistorted Images');
%% Find corresponding points

% Detect feature points
% imagePoints1 = detectMinEigenFeatures(rgb2gray(I1), 'MinQuality', 0.1);
imagePoints1 = detectSURFFeatures(rgb2gray(I1), 'MetricThreshold', ...
    2000, 'NumOctaves', 3, 'NumScaleLevels', 4);

% Visualize detected points
% figure
% imshow(I1, 'InitialMagnification', 50);
% title('150 Strongest Corners from the First Image');
% hold on
% plot(selectStrongest(imagePoints1, 150));

% Create the point tracker
tracker = vision.PointTracker('MaxBidirectionalError', 3, ...
    'NumPyramidLevels', 5, 'MaxIterations', 30);

% Initialize the point tracker
imagePoints1 = imagePoints1.Location;
initialize(tracker, imagePoints1, I1);

% Track the points
[imagePoints2, validIdx] = step(tracker, I2);
matchedPoints1 = imagePoints1(validIdx, :);
matchedPoints2 = imagePoints2(validIdx, :);

% Visualize correspondences
% figure
% showMatchedFeatures(I1, I2, matchedPoints1, matchedPoints2);
% title('Tracked Features');

% Estimate the fundamental matrix
% [fMatrix, epipolarInliers] = estimateFundamentalMatrix(...
%   matchedPoints1, matchedPoints2, 'Method', 'MSAC', 'NumTrials', 10000);
[fMatrix, epipolarInliers, status] = estimateFundamentalMatrix(...
  matchedPoints1, matchedPoints2, 'Method', 'RANSAC', ...
  'NumTrials', 10000, 'DistanceThreshold', 0.1, 'Confidence', 99.99);
if status ~= 0 || isEpipoleInImage(fMatrix, size(I1)) ...
  || isEpipoleInImage(fMatrix', size(I2))
  error(['Either not enough matching points were found or '...
         'the epipoles are inside the images. You may need to '...
         'inspect and improve the quality of detected features ',...
         'and/or improve the quality of your images.']);
end
% Find epipolar inliers
inlierPoints1 = matchedPoints1(epipolarInliers, :);
inlierPoints2 = matchedPoints2(epipolarInliers, :);

% Display inlier matches
figure
showMatchedFeatures(I1, I2, inlierPoints1, inlierPoints2);
legend('Inlier points in I1', 'Inlier points in I2');
title('Epipolar Inliers');
%% Two Camera Views
% Compute camera poses
[R, t] = cameraPose(fMatrix, cameraParams, inlierPoints1, inlierPoints2);

% Detect dense feature points
% imagePoints1 = detectMinEigenFeatures(rgb2gray(I1), 'MinQuality', 0.001);
imagePoints1 = detectSURFFeatures(rgb2gray(I1), 'MetricThreshold', 50, ...
    'NumOctaves', 5, 'NumScaleLevels', 8);

% Create the point tracker
tracker = vision.PointTracker('MaxBidirectionalError', 3, ...
    'NumPyramidLevels', 5, 'MaxIterations', 50);

% Initialize the point tracker
imagePoints1 = imagePoints1.Location;
initialize(tracker, imagePoints1, I1);

% Track the points
[imagePoints2, validIdx] = step(tracker, I2);
matchedPoints1 = imagePoints1(validIdx, :);
matchedPoints2 = imagePoints2(validIdx, :);

% Compute the camera matrices for each position of the camera
% The first camera is at the origin looking along the X-axis. Thus, its
% rotation matrix is identity, and its translation vector is 0.
camMatrix1 = cameraMatrix(cameraParams, eye(3), [0 0 0]);
camMatrix2 = cameraMatrix(cameraParams, R', -t*R');
%% 3D reconstruction
% Compute the 3-D points
points3D = triangulate(matchedPoints1, matchedPoints2, camMatrix1, ...
    camMatrix2); % cai nay dung matchedPoints nha

% Get the color of each reconstructed point
numPixels = size(I1, 1) * size(I1, 2);
allColors = reshape(I1, [numPixels, 3]);
colorIdx = sub2ind([size(I1, 1), size(I1, 2)], ...
    round(matchedPoints1(:,2)), round(matchedPoints1(:, 1)));
color = allColors(colorIdx, :);

% Create the point cloud
ptCloud = pointCloud(points3D, 'Color', color);

% Visualize the camera locations and orientations
cameraSize = 0.3;
figure
plotCamera('Size', cameraSize, 'Color', 'r', 'Label', '1', 'Opacity', 0);
hold on
grid on
plotCamera('Location', t, 'Orientation', R, 'Size', cameraSize, ...
    'Color', 'b', 'Label', '2', 'Opacity', 0);

% Visualize the point cloud
pcshow(ptCloud, 'VerticalAxis', 'y', 'VerticalAxisDir', 'down', ...
    'MarkerSize', 45);

% Rotate and zoom the plot
camorbit(0, -30);
camzoom(1.5);

% Label the axes
xlabel('x-axis');
ylabel('y-axis');
zlabel('z-axis')

title('Up to Scale Reconstruction of the Scene');
