function D = vipstereo_blockmatch(leftI,rightI,disparityMin,disparityMax,...
    subpixel,dynProg,dynSpan)
%Performs block matching. Optionally can perform subpixel accuracy and use
%dynamic programming.
%  D = VIPSTEREO_BLOCKMATCH(LEFTI,RIGHTI,DISPARITYMIN,DISPARITYMAX) does
%  basic block matching on the images LEFTI and RIGHTI, with minimum and
%  maximum disparity search ranges as given. The returned disparity values
%  are for the right image relative to the left image.
%
%  D = VIPSTEREO_BLOCKMATCH(...,SUBPIXEL,DYNPROG,DYNSPAN) can turn on
%  options for subpixel accuracy and dynamic programming. The latter
%  accepts an integer parameter DYNSPAN which controls the extent of the
%  smoothing (the minimum value of 1 means high smoothing, while the
%  maximum value of 5 means the least smoothing).

%   Copyright 2009 The MathWorks, Inc.

    if nargin < 5 || isempty(subpixel)
        subpixel = false;
    end
    if nargin < 6 || isempty(dynProg)
        dynProg = false;
    end
    if nargin < 7 || isempty(dynSpan)
        dynSpan = 3;
    end

    D = zeros(size(leftI), 'single');
    % False infinity (for simulating very high but non-infinite values
    % relative to the rest of the distance map.
    finf = cast(1e3, 'single');
    halfBlockSize = 3;
    % Calculate maximum range of disparity values
    disparityRange = ceil( max(max(disparityMax)) - min(min(disparityMin)) + 1 );
    if numel(disparityMin) == 1
        disparityMin = repmat(disparityMin, size(leftI));
    end
    if numel(disparityMax) == 1
        disparityMax = repmat(disparityMax, size(leftI));
    end
    blockSize = 2*halfBlockSize + 1;
    disparityCost = repmat(finf, [size(leftI,2) blockSize]);
    % Cost penalty for disparity disagreement between adjacent pixels
    disparityPenalty = 0.5;
    tmats = cell(blockSize);

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
            mind = floor( max( disparityMin(m,n), 1-minc ) );
            maxd = ceil( min( disparityMax(m,n), size(leftI,2)-maxc ) );
            % Compute and save all matching costs.
            if ~dynProg
                % Construct template and region of interest.
                template = rightI(minr:maxr,minc:maxc);
                templateCenter = floor((size(template)+1)/2);
                roi = [minr+templateCenter(1)-2 ...
                       minc+templateCenter(2)+mind-2 ...
                       1 maxd-mind+1];
                % Lookup proper TemplateMatcher object; create if empty.
                if isempty(tmats{size(template,1),size(template,2)})
                    tmats{size(template,1),size(template,2)} = ...
                        vision.TemplateMatcher('ROIInputPort',true,...
                        'BestMatchNeighborhoodOutputPort',true);
                end
                % Run TemplateMatcher object.
                [loc,a2] = step(tmats{size(template,1),size(template,2)}, ...
                    leftI, template, roi);
                D(m,n) = single(loc(2)) - roi(2) + mind;

                if subpixel
                    % Subpixel refinement of index.
                    D(m,n) = D(m,n) + subpixelcorrection(a2(2,:));
                end
            else
                % Save all costs for later step
                for d=mind:maxd
                    disparityCost(n, d + disparityRange + 1) = ...
                        sum(sum(abs(leftI(minr:maxr,(minc:maxc)+d) ...
                        - rightI(minr:maxr,minc:maxc))));
                end
            end
        end

        if dynProg
            % Process scanline disparity costs with dynamic programming.
            optimalIndices = zeros(size(disparityCost), 'single');
            cp = disparityCost(end,:);
            for j=size(disparityCost,1)-1:-1:1
                % False infinity for this level
                cfinf = (size(disparityCost,1) - j + 1)*finf;
                % Acquire matrix for finding optimal move for each column
                % individually. Handles smoothness settings from 1 (highly
                % smoothed) up to 5 (very little smoothing).
                T = dynspanmatrix(cp,disparityPenalty,cfinf,dynSpan);
                [v,ix] = min(T,[],1);
                
                cp = [cfinf disparityCost(j,2:end-1)+v cfinf];
                % Record optimal routes.
                optimalIndices(j,2:end-1) = (2:size(disparityCost,2)-1) + (ix - dynSpan - 1);
                % Subpixel accuracy
                if subpixel
                    for k=1:length(ix)
                        if ix(k) > 1 && ix(k) < size(T,1)
                            optimalIndices(j,k+1) = optimalIndices(j,k+1) ...
                                + subpixelcorrection(T(ix(k)-1:ix(k)+1,k));
                        end
                    end
                end
            end
            % Recover optimal route.
            [~,ix] = min(cp);
            D(m,1) = ix;
            for k=1:size(D,2)-1
                D(m,k+1) = optimalIndices(k, ...
                    max(1, min(size(optimalIndices,2), round(D(m,k)) ) ) );
            end
            D(m,:) = D(m,:) - disparityRange - 1;
        end
    end
end

function offset = subpixelcorrection(x)
%Returns the subpixel correction based on the 3-element vector x.
    offset = 0;
    den = (x(1) - 2*x(2) + x(3));
    if den ~= 0
        offset = -0.5*(x(3)-x(1))/den;
    end
end

function T = dynspanmatrix(cost,penalty,finf,span)
%Returns the matrix to use for finding minimum-weight neighbors with
%dynamic programming.
    T = zeros(2*span+1,numel(cost)-2);
    cent = span+1;
    T(cent-1:cent+1,:) = [cost(1:end-2) + penalty;
                          cost(2:end-1);
                          cost(3:end) + penalty];
    for i=2:span
        T(cent-i,:) = [repmat(finf,[1 i-1]) cost(1:end-i-1)+i*penalty];
        T(cent+i,:) = [cost(i+2:end)+i*penalty repmat(finf,[1 i-1])];
    end
end


