function [objs] = fo4_rp(img, objsize, thresh, fitstr)

% fo4 : finds objects in images, filters using localmin triangulation
%
% img = image to locate objects within
% objsize : size in pixels of objects to find. Used to determine:
%    ste = structuring element with diameter approximately particle size
%    and image-space bandpass filter
% thresh = number in [0, 1] that sets the local max threshold
% fitstr : (Optional) string that selects the fitting option (Gaussian or
%    centroid).  Default is Gaussian ('gauss').  For centroid, enter 'centroid'.
%
% first, filters image, then implements imdilate
% and find routine to find local maxima.  Maxima are refined with a 2D 
% Gaussian fit and returned in the matrix 'objs' which has the following form:
%  [x;
%   y;
%   mass;
%   particleid;
%   frame;
%   trackid]
%
% frame and trackid are set to zero for all objects by fo4() and must be
% dealt with by the functions calling fo4().
%

% In earlier version, renamed fo4_rp_bpfilter.m:
%   Finds local minima as well, and filters maxima to be greater than p
%      (input) standard deviations above 3 nearest minima
%   Use bpfilter, filtering element "h"

% Raghuveer Parthasarathy, April 2007
% modifications -- 
% CENTROID seems to give 'quantized' output -- delete and replace with local
%   quadratic fit, find local maximum along x and y of row or column summed
%   image intensities -- RP 28 May 2007.
% Implement 2D Gaussian fit to local maxima to find particle centers.
%    Seems to suffer less from quantization issues? -- 2 June 2007
% Centroid fitting allowed as an option -- useful for saturated images
% Last modified 11 June 2009


% Fitting option; default is Gaussian
if and((nargin>3), strcmpi(fitstr, 'centroid'))
    gaussfitopt = false;
    % Do centroid (center of mass) fit
else
    gaussfitopt = true;
end

showplots=false;  % for debugging -- plot things.

ste = strel('disk', floor(objsize/2),0);  % for dilation
% make img processable
img = double(img);

% now do bandpass filter -- use Grier et al bpass.m
noisesize = 1;  % size of noise, px
filtimg = bpass(img,noisesize,objsize);

if showplots
    figure(1)
    imagesc(img); colormap(gray); title('1 original image')
    figure(2)
    imagesc(filtimg); colormap(gray); title('2 bandpass filtered')
end

% dilate
dimg = imdilate(filtimg, ste);
if showplots
    figure(3); imagesc(dimg); colormap(gray); title('3 dilated')
end

% now compute noise level and threshold
[hs, bins] = hist(filtimg(:),100);

ch = cumsum(hs);
ch = ch/max(ch);
noiseind = find(ch > thresh); %
noiseind = noiseind(2); % The index value below which "thresh" fraction
% of the pixels lie

% find local maxima
[y,x] = find((filtimg == dimg) & ...
    (filtimg > bins(noiseind))); % "the magic happens here!" (ALD)
if showplots
    figure(4)
    imagesc(filtimg==dimg); colormap(gray); title('4 filtered == dilated')
    figure(5);
    imagesc(filtimg>bins(noiseind)); colormap(gray);
    title('5 filtered > threshold')
end

% get rid of maxima to close to the edge
nhood = getnhood(ste);
lenx = size(nhood,1);
leny = size(nhood,2);
edgeind = ((x < lenx/2) | (x > (size(img,2) - lenx/2))) | ...
    ((y < leny/2) | (y > (size(img,1) - leny/2)));

x(edgeind) = [];
y(edgeind) = [];

% now compute masses
savemass = zeros(1, length(x));

xn = zeros(1,length(x));
yn = zeros(1,length(x));
for i = 1:length(x)
    rect = [round(x(i) - lenx/2) round(y(i) - leny/2) (lenx-1) (leny-1)];
    cropimg = imcrop(img, rect);
    % figure; surf(cropimg); shading flat; pause
    if(size(cropimg) == size(nhood))
        savemass(i) = sum(sum(cropimg(nhood)));
    else
        savemass(i) = sum(sum(cropimg)); % cropimg is not same size as nhood
    end
    % do refinement
    lsumx = 1:size(cropimg,2);
    lsumy = 1:size(cropimg,1);
    if gaussfitopt
        % Gaussian fit
        % "Multiple regression" fit of cropimg intensity to a 2D Gaussian:
        %   img = A * exp(-[(x-x0)^2 + (y-y0)^2]/B)
        % -> log(img) = constants -(1/B)x^2 + (2x0/B)x -(1/B)y^2 + (2y0/B)y
        xa = zeros(1,numel(cropimg));
        ya = zeros(1,numel(cropimg));
        logint = zeros(1,numel(cropimg));
        m = 1;
        for j=lsumx,
            for k=lsumy,
                if (cropimg(k,j)>0)
                    xa(m) = j;  % vector of all the x values in the neighborhood
                    ya(m) = k;  % vector of all the y values in the neighborhood
                    logint(m) = log(cropimg(k,j)); % vector of log of intensity x values
                    m = m+1;
                end
            end
        end
        xa = xa';  ya = ya';  logint = logint';
        X = [ones(size(xa)) xa.*xa  xa  ya.*ya  ya];
        a = X\logint;  % a are the best fit coefficients of the terms of X
        xcent = -1.0*a(3)/2/a(2);
        ycent = -1.0*a(5)/2/a(4);
    else
        % centroid (center of mass) fit
        xcent = sum(sum(cropimg) .* lsumx) / sum(sum(cropimg));
        ycent = sum(sum(cropimg,2) .* lsumy') / sum(sum(cropimg,2));
    end
    xn(i) = xcent + rect(1) - 1; % -1 is to correct for matlab indexing
    yn(i) = ycent + rect(2) - 1;
end

if showplots
    figure(6)
    imagesc(zeros(size(img))); colormap(gray); title('6 centers')
    for j=1:length(xn)
        rectangle('Position', [xn(j)-1 yn(j)-1 2 2], 'Curvature', [1 1], ...
            'Linewidth', 2.0, 'EdgeColor', [1.0 1.0 0.0]);
    end
end

objs = zeros(6, length(xn));
objs(1,:) = xn;
objs(2,:) = yn;
objs(3,:) = savemass;
objs(4,:) = 1:length(x);
