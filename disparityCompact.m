I1 = imread('left3.png');
I2 = imread('right3.png');
I1gray = rgb2gray(I1);
I2gray = rgb2gray(I2);

%% Disparity Map
disparityMap = disparityBM(I1gray, I2gray);
figure;
imshow(disparityMap, [0, 52]);
title('Disparity Map');
colormap jet
colorbar