% close all

%% Prepare the images
I1 = imread('left3.png');
I2 = imread('right3.png');
I1gray = rgb2gray(I1);
I2gray = rgb2gray(I2);

%% Find correspondences
blobs1 = detectKAZEFeatures(I1gray, 'Diffusion', 'region', ...
    'NumOctaves', 5, 'NumScaleLevels', 5);
blobs2 = detectKAZEFeatures(I2gray, 'Diffusion', 'region', ...
    'NumOctaves', 5, 'NumScaleLevels', 5);

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

%% Rectify Image
[t1, t2] = estimateUncalibratedRectification(fMatrix, ...
  inlierPoints1.Location, inlierPoints2.Location, size(I2));
tform1 = projective2d(t1);
tform2 = projective2d(t2);

[I1Rect, I2Rect] = rectifyStereoImages(I1, I2, tform1, tform2);

% figure;
% imshow(stereoAnaglyph(I1Rect, I2Rect));
% title('Rectified Stereo Images (Red - Left Image, Cyan - Right Image)');

%% Disparity Map
leftI = rgb2gray(I1Rect);
rightI = rgb2gray(I2Rect);
disparityRange = 52;
% That Sub-pixel Pyramiding Dynamic Programming code!
DdynamicSubpixel = vipstereo_blockmatch_combined(leftI,rightI, ...
    'NumPyramids',3, 'DisparityRange',disparityRange, 'DynamicProgramming',true, ...
    'Subpixel', true);
figure;
imshow(DdynamicSubpixel,[]), axis image, colormap('jet'), colorbar;
caxis([0 disparityRange]);
title('Pyramid with dynamic programming and sub-pixel accuracy');
