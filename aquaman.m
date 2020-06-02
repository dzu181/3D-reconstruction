% close all

%% Prepare the images
I1 = imread('left4.png');
I2 = imread('right4.png');
% Undistort them! Only for rectification algorithms like MinEigen va Harris
%I1 = undistortImage(I1, cameraParams);
%I2 = undistortImage(I2, cameraParams);

%figure 
%imshowpair(I1, I2, 'montage');
%title('Undistorted Images');

% Convert to grayscale.
I1gray = rgb2gray(I1);
I2gray = rgb2gray(I2);

% Composite images
%figure;
%imshow(stereoAnaglyph(I1,I2));
%title('Composite Image (Red - Left Image, Cyan - Right Image)');

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

% figure;
% showMatchedFeatures(I1, I2, inlierPoints1, inlierPoints2);
% legend('Inlier points in I1', 'Inlier points in I2');

%% Rectify Image
[t1, t2] = estimateUncalibratedRectification(fMatrix, ...
  inlierPoints1.Location, inlierPoints2.Location, size(I2));
tform1 = projective2d(t1);
tform2 = projective2d(t2);

[I1Rect, I2Rect] = rectifyStereoImages(I1, I2, tform1, tform2);
% figure;
% imshow(stereoAnaglyph(I1Rect, I2Rect));
% title('Rectified Stereo Images (Red - Left Image, Cyan - Right Image)');
leftI = rgb2gray(I1Rect);
rightI = rgb2gray(I2Rect);

% %% Basic block matching
% Dbasic = zeros(size(leftI), 'single');
% disparityRange = 15;
% % Selects (2*halfBlockSize+1)-by-(2*halfBlockSize+1) block.
% halfBlockSize = 3;
% blockSize = 2*halfBlockSize+1;
% % Allocate space for all template matchers.
% tmats = cell(blockSize);
% % Scan over all rows.
% for m=1:size(leftI,1)
%     % Set min/max row bounds for image block.
%     minr = max(1,m-halfBlockSize);
%     maxr = min(size(leftI,1),m+halfBlockSize);
%     % Scan over all columns.
%     for n=1:size(leftI,2)
%         minc = max(1,n-halfBlockSize);
%         maxc = min(size(leftI,2),n+halfBlockSize);
%         % Compute disparity bounds.
%         mind = max( -disparityRange, 1-minc );
%         maxd = min( disparityRange, size(leftI,2)-maxc );
%         % Construct template and region of interest.
%         template = rightI(minr:maxr,minc:maxc);
%         templateCenter = floor((size(template)+1)/2);
%         roi = [minr+templateCenter(1)-2 ...
%                minc+templateCenter(2)+mind-2 ...
%                1 maxd-mind+1];
%         % Lookup proper TemplateMatcher object; create if empty.
%         if isempty(tmats{size(template,1),size(template,2)})
%             tmats{size(template,1),size(template,2)} = ...
%                 vision.TemplateMatcher('ROIInputPort',true);
%         end
%         thisTemplateMatcher = tmats{size(template,1),size(template,2)};
%         % Run TemplateMatcher object.
%         loc = step(thisTemplateMatcher, leftI, template, roi);
%         Dbasic(m,n) = loc(2) - roi(2) + mind;
%     end
% end

% figure;
% imshow(Dbasic,[]), axis image, colormap('jet'), colorbar;
% caxis([0 disparityRange]);
% title('Depth map from basic block matching');

% %% Sub-pixel estimation
% DbasicSubpixel= zeros(size(leftI), 'single');
% disparityRange = 128;
% % Selects (2*halfBlockSize+1)-by-(2*halfBlockSize+1) block.
% halfBlockSize = 3;
% % Allocate space for all template matchers.
% tmats = cell(2*halfBlockSize+1);
% for m=1:size(leftI,1)
% 	% Set min/max row bounds for image block.
% 	minr = max(1, m-halfBlockSize);
% 	maxr = min(size(leftI,1), m+halfBlockSize);
% 	% Scan over all columns.
% 	for n=1:size(leftI,2)
%         minc = max(1,n-halfBlockSize);
%         maxc = min(size(leftI,2),n+halfBlockSize);
%         % Compute disparity bounds.
%         mind = max(-disparityRange, 1-minc);
%         maxd = min(disparityRange, size(leftI,2)-maxc);
%         % Construct template and region of interest.
%         template = rightI(minr:maxr, minc:maxc);
%         templateCenter = floor((size(template)+1)/2);
%         roi = [minr+templateCenter(1)-2 ...
%             minc+templateCenter(2)+mind-2 ...
%             1 maxd-mind+1];
%         % Lookup proper TemplateMatcher object; create if empty.
%         if isempty(tmats{size(template,1),size(template,2)})
%             tmats{size(template,1),size(template,2)} = ...
%                 vision.TemplateMatcher('ROIInputPort',true,...
%                 'BestMatchNeighborhoodOutputPort',true);
%         end
%         thisTemplateMatcher = tmats{size(template,1),size(template,2)};
%         % Run TemplateMatcher object.
%         [loc,a2] = step(thisTemplateMatcher, leftI, template, roi);
%         ix = single(loc(2) - roi(2) + mind);
%         a2 = single(a2);
%         % Subpixel refinement of index.
%         DbasicSubpixel(m,n) = ix - 0.5 * (a2(2,3) - a2(2,1)) ...
%             /(a2(2,1) - 2*a2(2,2) + a2(2,3));
% 	end
% end

% figure;
% imshow(DbasicSubpixel,[]), axis image, colormap('jet'), colorbar;
% caxis([0 disparityRange]);
% title('Basic block matching with sub-pixel accuracy');

%% Dynamic Programming
Ddynamic = zeros(size(leftI), 'single');
disparityRange = 52;
% Selects (2*halfBlockSize+1)-by-(2*halfBlockSize+1) block.
halfBlockSize = 4;
finf = 1e3; % False infinity
disparityCost = finf*ones(size(leftI,2), 2*disparityRange + 1, 'single');
disparityPenalty = 0.5; % Penalty for disparity disagreement between pixels
% Scan over all rows.
for m=1:size(leftI,1)
    disparityCost(:) = finf;
    % Set min/max row bounds for image block.
    minr = max(1,m-halfBlockSize);
    maxr = min(size(leftI,1),m+halfBlockSize);
    % Scan over all columns.
    for n=1:size(leftI,2)
        minc = max(1,n-halfBlockSize);
        maxc = min(size(leftI,2),n+halfBlockSize);
        % Compute disparity bounds.
        mind = max( -disparityRange, 1-minc );
        maxd = min( disparityRange, size(leftI,2)-maxc );
        % Compute and save all matching costs.
        for d=mind:maxd
            disparityCost(n, d + disparityRange + 1) = ...
                sum(sum(abs(leftI(minr:maxr,(minc:maxc)+d) ...
                - rightI(minr:maxr,minc:maxc))));
        end
    end
    % Process scanline disparity costs with dynamic programming.
    optimalIndices = zeros(size(disparityCost), 'single');
    cp = disparityCost(end,:);
    for j=size(disparityCost,1)-1:-1:1
        % False infinity for this level
        cfinf = (size(disparityCost,1) - j + 1)*finf;
        % Construct matrix for finding optimal move for each column
        % individually.
        [v,ix] = min([cfinf cfinf cp(1:end-4)+3*disparityPenalty;
                      cfinf cp(1:end-3)+2*disparityPenalty;
                      cp(1:end-2)+disparityPenalty;
                      cp(2:end-1);
                      cp(3:end)+disparityPenalty;
                      cp(4:end)+2*disparityPenalty cfinf;
                      cp(5:end)+3*disparityPenalty cfinf cfinf],[],1);
        cp = [cfinf disparityCost(j,2:end-1)+v cfinf];
        % Record optimal routes.
        optimalIndices(j,2:end-1) = (2:size(disparityCost,2)-1) + (ix - 4);
    end
    % Recover optimal route.
    [~,ix] = min(cp);
    Ddynamic(m,1) = ix;
    for k=1:size(Ddynamic,2)-1
        Ddynamic(m,k+1) = optimalIndices(k, ...
            max(1, min(size(optimalIndices,2), round(Ddynamic(m,k)) ) ) );
    end
end
Ddynamic = Ddynamic - disparityRange - 1;

figure;
imshow(Ddynamic,[]), axis image, colormap('jet'), colorbar;
caxis([0 disparityRange]);
title('Block matching with dynamic programming');


