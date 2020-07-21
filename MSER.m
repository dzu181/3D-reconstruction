% I1 = imread('25.jpg');
% I2 = imread('26.jpg');
% 
% 
% I1gray = rgb2gray(I1);
% I2gray = rgb2gray(I2);

% Hello twins!
blobs1 = detectMSERFeatures(I1gray, 'ThresholdDelta', 0.8, ...
    'MaxAreaVariation', 0.75);
blobs2 = detectMSERFeatures(I2gray, 'ThresholdDelta', 0.8, ...
    'MaxAreaVariation', 0.75);

[features1, validBlobs1] = extractFeatures(I1gray, blobs1);
[features2, validBlobs2] = extractFeatures(I2gray, blobs2);

indexPairs = matchFeatures(features1, features2, 'Metric', 'SAD', ...
  'MatchThreshold', 50);

matchedPoints1 = validBlobs1(indexPairs(:,1),:);
matchedPoints2 = validBlobs2(indexPairs(:,2),:);

% Epipolar constraint
[fMatrix, epipolarInliers, status] = estimateFundamentalMatrix(...
  matchedPoints1, matchedPoints2, 'Method', 'MSAC', ...
  'NumTrials', 10000, 'DistanceThreshold', 0.1, 'Confidence', 99.99);

% if status ~= 0 || isEpipoleInImage(fMatrix, size(I1)) ...
%   || isEpipoleInImage(fMatrix', size(I2))
%   error(['Either not enough matching points were found or '...
%          'the epipoles are inside the images. You may need to '...
%          'inspect and improve the quality of detected features ',...
%          'and/or improve the quality of your images.']);
% end

MSERinlierPoints1 = matchedPoints1(epipolarInliers, :);
MSERinlierPoints2 = matchedPoints2(epipolarInliers, :);

% figure;
% showMatchedFeatures(I1, I2, inlierPoints1, inlierPoints2);
% legend('Inlier points in I1', 'Inlier points in I2');