%% Chuan bi anh
% I1 = imread('left1.png');
% I2 = imread('right1.png');
I = imread('st1.jpg');
[Bx By Bz]=size(I);
I1=I(:,1:By/2,:);
I2=I(:,1+By/2:By,:);
I1gray = rgb2gray(I1);
I2gray = rgb2gray(I2);

%% Tim diem chung giua cap anh
blobs1 = detectSURFFeatures(I1gray, 'MetricThreshold', 50, ...
    'NumOctaves', 5, 'NumScaleLevels', 8);
blobs2 = detectSURFFeatures(I2gray, 'MetricThreshold', 50, ...
    'NumOctaves', 5, 'NumScaleLevels', 8);

[features1, validBlobs1] = extractFeatures(I1gray, blobs1);
[features2, validBlobs2] = extractFeatures(I2gray, blobs2);
indexPairs = matchFeatures(features1, features2, 'Metric', 'SAD', ...
  'MatchThreshold', 50);
matchedPoints1 = validBlobs1(indexPairs(:,1),:);
matchedPoints2 = validBlobs2(indexPairs(:,2),:);
% Phep gioi han Epipolar
[fMatrix, epipolarInliers, status] = estimateFundamentalMatrix(...
  matchedPoints1, matchedPoints2, 'Method', 'MSAC', ...
  'NumTrials', 10000, 'DistanceThreshold', 0.1, 'Confidence', 99.99);

if status ~= 0 || isEpipoleInImage(fMatrix, size(I1)) ...
  || isEpipoleInImage(fMatrix', size(I2))
  error(['Either not enough matching points were found or '...
         'the epipoles are inside the images. You may need to '...
         'inspect and improve the quality of detected features ',...
         'and/or improve the quality of your images.']);
end
% Cac diem chung chinh xac
inlierPoints1 = matchedPoints1(epipolarInliers, :);
inlierPoints2 = matchedPoints2(epipolarInliers, :);

figure;
showMatchedFeatures(I1, I2, inlierPoints1, inlierPoints2);
legend('Inlier points in I1', 'Inlier points in I2');
title('Diem chung giua cap anh');

% Vi cap anh da duoc Rectify tu truoc nen ta show Disparity map luon
%% Disparity Map
disparityMap = disparitySGM(I1gray, I2gray);
figure;
imshow(disparityMap, [0, 52]);
title('Disparity Map');
colormap jet
colorbar