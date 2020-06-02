I1 = imread('left3.png');
I2 = imread('right3.png');
leftI = rgb2gray(I1);
rightI = rgb2gray(I2);

%% Disparity Map
disparityRange = 52;
DdynamicSubpixel = vipstereo_blockmatch_combined(leftI,rightI, ...
    'NumPyramids',3, 'DisparityRange',disparityRange, ...
    'DynamicProgramming',true, 'Subpixel', true);

figure;
imshow(DdynamicSubpixel,[]), axis image, colormap('jet'), colorbar;
caxis([0 disparityRange]);
title('Pyramid with dynamic programming and sub-pixel accuracy');