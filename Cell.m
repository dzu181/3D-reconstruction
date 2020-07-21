% close all
%% Prepare images
I1 = imread('st14l.png');
I2 = imread('st14r.png');
I1gray = rgb2gray(I1);
I2gray = rgb2gray(I2);
%% Cho ra Diem chung dua theo tat ca cac thuat toan co the
KAZE;
SURF;
ORB;
MSER;
BRISK;
%% Gop tat ca cac diem chung tim duoc
inlierPoints1 = [KAZEinlierPoints1.Location; SURFinlierPoints1.Location;...
    ORBinlierPoints1.Location; MSERinlierPoints1.Location; ...
    BRISKinlierPoints1.Location];

inlierPoints2 = [KAZEinlierPoints2.Location; SURFinlierPoints2.Location;...
    ORBinlierPoints2.Location; MSERinlierPoints2.Location; ...
    BRISKinlierPoints2.Location];

figure;
showMatchedFeatures(I1, I2, inlierPoints1, inlierPoints2);
legend('Inlier points in I1', 'Inlier points in I2');
%% Rectify images
[t1, t2] = estimateUncalibratedRectification(fMatrix, ...
  inlierPoints1, inlierPoints2, size(I2));
tform1 = projective2d(t1);
tform2 = projective2d(t2);
[I1Rect, I2Rect] = rectifyStereoImages(I1, I2, tform1, tform2);

% figure;
% imshow(stereoAnaglyph(I1Rect, I2Rect));
% title('Rectified Stereo Images (Red - Left Image, Cyan - Right Image)');
%% Disparity Map
I1Rectgray = rgb2gray(I1Rect);
I2Rectgray = rgb2gray(I2Rect);
disparityMap = disparitySGM(I1Rectgray, I2Rectgray);
figure;
imshow(disparityMap, [0, 24]);
title('Disparity Map');
colormap jet
colorbar 