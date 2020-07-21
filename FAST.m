% I1 = imread('27.jpg');
% I2 = imread('28.jpg');
% I1udi = undistortImage(I1, cameraParams);
% I2udi = undistortImage(I2, cameraParams);

% figure
% imshowpair(I1udi, I2udi, 'montage');
% title('Undistorted Images');

% Detect feature points
imagePoints1 = detectFASTFeatures(rgb2gray(I1udi), 'MinQuality', 0.01,...
    'MinContrast', 0.1);

% figure
% imshow(I1udi, 'InitialMagnification', 50);
% title('150 Strongest Corners from the First Image');
% hold on
% plot(selectStrongest(imagePoints1, 150));

% Create the point tracker
tracker = vision.PointTracker('MaxBidirectionalError', 3, ...
    'NumPyramidLevels', 5, 'MaxIterations', 50);

% Initialize the point tracker
imagePoints1 = imagePoints1.Location;
initialize(tracker, imagePoints1, I1udi);

% Track the points
[imagePoints2, validIdx] = step(tracker, I2udi);
matchedPoints1 = imagePoints1(validIdx, :);
matchedPoints2 = imagePoints2(validIdx, :);

% Visualize correspondences
% figure
% showMatchedFeatures(I1udi, I2udi, matchedPoints1, matchedPoints2);
% title('Tracked Features');

% Estimate the fundamental matrix
% [fMatrix, epipolarInliers] = estimateFundamentalMatrix(...
%   matchedPoints1, matchedPoints2, 'Method', 'MSAC', 'NumTrials', 10000);
[fMatrix, epipolarInliers, status] = estimateFundamentalMatrix(...
  matchedPoints1, matchedPoints2, 'Method', 'MSAC', ...
  'NumTrials', 10000, 'DistanceThreshold', 0.1, 'Confidence', 99.99);
% if status ~= 0 || isEpipoleInImage(fMatrix, size(I1udi)) ...
%   || isEpipoleInImage(fMatrix', size(I2udi))
%   error(['Either not enough matching points were found or '...
%          'the epipoles are inside the images. You may need to '...
%          'inspect and improve the quality of detected features ',...
%          'and/or improve the quality of your images.']);
% end
% Find epipolar inliers
FASTinlierPoints1 = matchedPoints1(epipolarInliers, :);
FASTinlierPoints2 = matchedPoints2(epipolarInliers, :);

% figure
% showMatchedFeatures(I1udi, I2udi, inlierPoints1, inlierPoints2);
% legend('Inlier points in I1', 'Inlier points in I2');
% title('Epipolar Inliers');