clear X Y Z;
[Ax Ay]=size(disparityMap);
k=0;
for i=1:Ax
    for j=1:Ay
        k=k+1;
        if isnan(disparityMap(i,j))
%             disparityMap(i,j)=0;
            continue;
        end
        X(k)= (Ax-i) *2;
        Y(k)= (Ay-j) *2;
        Z(k)= disparityMap(i,j);
        C(k)= Z(k)/(45*50); % max(Z) ~= 45
        % Dung C de chia toa do mau cho Grayscale
    end
end
% figure
% plot3(Y,Z,X,'.');
% surf(X,Y,Z,'edgecolor','none');
% plot3(X,Y,Z,'.')
% colormap(gray);
% surf(X, Y, Z, C);

% %% Colors method 1 - bi qua tai array
% p3D = [X; Y; Z].';
% numPixels = size(I1, 1) * size(I1, 2);
% allColors = reshape(I1, [numPixels, 3]);
% colorIdx = sub2ind([size(I1, 1), size(I1, 2)], ...
%     round(matchedPoints1(:,2)), round(matchedPoints1(:, 1)));
% color = allColors(colorIdx, :);
% 
% % Create the point cloud
% ptCloud = pointCloud(p3D, 'Color', color);

% %% Color method 2 - khong lien quan den diaparityMap
% resize_value = 0.3; % From 0 to 1
% 
% TraceImage = imresize(I1gray,resize_value);
% original = TraceImage;
% bw = im2bw(TraceImage,graythresh(TraceImage)); 
% 
% I=TraceImage;
% [x,y]=size(I);
% X1=1:x;
% Y1=1:y;
% [xx,yy]=meshgrid(Y1,X1);
% i=im2double(I);
% figure;mesh(xx,yy,i);
% colorbar
% % figure;imshow(i)


c = X+Y-Z;          % c = data(:,4);
figure
scatter3(X,Y,Z,3,c)
colorbar

