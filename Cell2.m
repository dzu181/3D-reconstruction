close all
%% Prepare images
I1 = imread('53.jpg');
I2 = imread('54.jpg');
I1gray = rgb2gray(I1);
I2gray = rgb2gray(I2);
I1udi = undistortImage(I1, cameraParams);
I2udi = undistortImage(I2, cameraParams);
%% Cho ra Diem chung dua theo tat ca cac thuat toan co the
KAZE;
SURF;
ORB;
MSER;
BRISK;
FAST;
EIGEN;
HARRIS;
%% Gop tat ca cac diem chung tim duoc
inlierPoints1 = [KAZEinlierPoints1.Location; SURFinlierPoints1.Location;...
    ORBinlierPoints1.Location; MSERinlierPoints1.Location; ...
     BRISKinlierPoints1.Location; FASTinlierPoints1; ...
    HARRISinlierPoints1; EIGENinlierPoints1];

inlierPoints2 = [KAZEinlierPoints2.Location; SURFinlierPoints2.Location;...
    ORBinlierPoints2.Location; MSERinlierPoints2.Location; ...
     BRISKinlierPoints2.Location; FASTinlierPoints2; ...
    HARRISinlierPoints2; EIGENinlierPoints2];

figure;
showMatchedFeatures(I1, I2, inlierPoints1, inlierPoints2);
legend('Inlier points in I1', 'Inlier points in I2');
%% Rectify images
[t1, t2] = estimateUncalibratedRectification(fMatrix, ...
  inlierPoints1, inlierPoints2, size(I2));
tform1 = projective2d(t1);
tform2 = projective2d(t2);
[I1Rect, I2Rect] = rectifyStereoImages(I1, I2, tform1, tform2);

figure;
imshow(stereoAnaglyph(I1Rect, I2Rect));
title('Rectified Stereo Images (Red - Left Image, Cyan - Right Image)');
%% Disparity Map
I1Rectgray = rgb2gray(I1Rect);
I2Rectgray = rgb2gray(I2Rect);
disparityMap = disparitySGM(I1Rectgray, I2Rectgray);

figure;
imshow(disparityMap, [0, 64]);
title('Disparity Map 2');
colormap jet
colorbar