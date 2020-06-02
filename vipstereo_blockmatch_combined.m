function D = vipstereo_blockmatch_combined(leftI,rightI,varargin)
%video stereo demo block matching function.
%  D = VIPSTEREO_BLOCKMATCH_COMBINED(leftI,rightI) performs basic block
%  matching on the two images using the function VIPSTEREO_BLOCKMATCH.
%
%  D = VIPSTEREO_BLOCKMATCH_COMBINED(leftI,rightI,...) accepts the
%  following parameter-value pairs for additional options:
%
%  'DynamicProgramming' Turns on dynamic programming.
%
%                       Default: false.
%
%  'DynamicSpan'        Set the latitude of the dynamic programming
%                       smoothness constraint: smaller numbers mean
%                       more-smoothed maps.
%
%                       Default: 3.
%
%  'Subpixel'           Turns on subpixel accuracy.
%
%                       Default: false.
%
%  'NumPyramids'        Sets the number of pyramid levels.
%
%                       Default: 0.
%
%  'DisparityRange'     Sets the disparity search range.
%
%                       Default: 15.

%   Copyright 2009 The MathWorks, Inc.

% Default parameter values
numPyramids = 0; % No image pyramiding
disparityRange = 15; % Initial disparity search range.
dynProg= false; % No dynamic programming
dynSpan = 3; % Moderately smoothed
subpixel = false; % No subpixel accuracy

% Parse arguments
i = 1;
v = varargin;
while i <= length(v)
    if strcmpi(v{i},'DynamicProgramming')
        dynProg = v{i+1};
        i=i+2;
    elseif strcmpi(v{i},'DynamicSpan')
        dynSpan = v{i+1};
        i=i+2;
    elseif strcmpi(v{i},'NumPyramids')
        numPyramids = v{i+1};
        i=i+2;
    elseif strcmpi(v{i},'DisparityRange')
        disparityRange = v{i+1};
        i=i+2;
    elseif strcmpi(v{i},'Subpixel')
        subpixel = v{i+1};
        i=i+2;
    else
        error('vipblks:vipstereo_blockmatch_combined:invalidOption',...
            'Failed to parse option: %s', v{i});
    end
end

pyramids = cell(1,numPyramids+1);
pyramids{1}.L = single(leftI);
pyramids{1}.R = single(rightI);
% Create image pyramid
for i=2:length(pyramids)
    hPyr = vision.Pyramid('PyramidLevel',1);
    pyramids{i}.L = step(hPyr,pyramids{i-1}.L);
    pyramids{i}.R = step(hPyr,pyramids{i-1}.R);
end
% Initialize disparity search bounds
disparityRange = single(disparityRange);
disparityMin = repmat(-disparityRange, size(pyramids{end}.L));
disparityMax = repmat( disparityRange, size(pyramids{end}.L));
% Process levels of pyramid in reverse order with telescoping search
for i=length(pyramids):-1:1
    D = vipstereo_blockmatch(pyramids{i}.L,pyramids{i}.R, ...
          disparityMin,disparityMax,subpixel,dynProg,dynSpan);

    if i > 1
        % Scale disparity values for next level.
        
        % gsca = video.GeometricScaler(...
        %     'InterpolationMethod','Nearest neighbor',...
        %     'SizeMethod','Number of output rows and columns',...
        %     'Size',size(pyramids{i-1}.L));
        % D = 2*step(gsca, D);
        D = 2* imresize(D, size(pyramids{i-1}.L), 'nearest');
        % Maintain search radius of +/-disparityRange.
        disparityMin = D - disparityRange;
        disparityMax = D + disparityRange;
    end
end


