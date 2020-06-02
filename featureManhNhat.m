%% Chuan bi anh
% I1 = imread('left3.png');
% I2 = imread('right3.png');
I = imread('st1.jpg');
[Bx By Bz]=size(I);
I1=I(:,1:By/2,:);
I2=I(:,1+By/2:By,:);
I1gray = rgb2gray(I1);
I2gray = rgb2gray(I2);

%% Tim feature manh nhat su dung SURF
blobs1 = detectSURFFeatures(I1gray, 'MetricThreshold', 50, ...
    'NumOctaves', 5, 'NumScaleLevels', 8);
blobs2 = detectSURFFeatures(I2gray, 'MetricThreshold', 50, ...
    'NumOctaves', 5, 'NumScaleLevels', 8);
% Trinh chieu cac diem feature noi bat
figure;
imshow(I1);
hold on;
plot(selectStrongest(blobs1, 300));
title('300 strongest SURF features in I1');

%% Tim feature manh nhat su dung minEigen
% Detect feature points
imagePoints1 = detectMinEigenFeatures(I1gray, 'MinQuality', 0.1);

% Visualize detected points
figure
imshow(I1, 'InitialMagnification', 50);
title('500 Strongest Corners from the First Image');
hold on
plot(selectStrongest(imagePoints1, 500));