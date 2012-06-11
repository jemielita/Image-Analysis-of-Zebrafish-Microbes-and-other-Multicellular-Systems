function [objs] = fo4_rp(img, objsize, thresh, fitstr, lsqoptions)

% fo4 : finds objects in images, first filtering and determining local
% maxima and then refining positions with one of several possible methods
%
% img = image to locate objects within
% objsize : size in pixels of objects to find. Used to determine:
%    ste = structuring element with diameter approximately particle size
%    and image-space bandpass filter
% thresh : intensity threshold 
%    *Various options,* inferred from the form of the input
%    (1) if a number in [0, 1), sets the local max intensity threshold, 
%        keeping all points with intensity above the thresh*100 percentile
%    (2) if a number <0, keeps pixels with intensity > thresh*std.dev. above
%          the median intensity
%    (3) if a number >= 1, keeps brightest "thresh" number of particles
%          by finding the "thresh" brightest regions and allowing only one
%          maximum in each
% fitstr : (Optional) string that selects the fitting option 
%          -- [default] 'radial'.  Radial-symmetry based fit.  Fast, accurate -- see
%             notes July-August 2011, and RP's Nature Methods paper, June
%             2012.
%          --  'gaussmle' , radially symmetric 2D Gaussian, fit by maximum
%             likelihood estimation.  Slow, most accurate.
%          --  'nonlineargauss' , radially symmetric 2D Gaussian
%             nonlinear fit.  Slow, accurate.
%             Fit to intensity = offset  A*exp(-(x^2+y^2)/2/sigma^2);
%          -- 'lineargauss' , 2D Gaussian, linear fit (i.e. parabolic 
%             fit to log(intensity).  Fast, moderate accuracy
%          -- 'centroid'.  Centroid fit.  Least accurate; may be necessary 
%             if intensity is saturated.
%          -- 'weightedlineargauss' , Linearized Gaussian fit, weighted 
%             for noise (Stephen M. Anthony, Steve Granick -- see Langmuir paper)
%             DON'T USE THIS
% lsqoptions : [optional] options structure for nonlinear least-squares
%              fitting, from previously running 
%              "lsqoptions = optimset('lsqnonlin');"
%              Inputting this speeds up the function by avoiding redundant 
%              calls to optimset.
%              This variable is only used for non-linear Gaussian fitting.
%
% first, filters image, then implements a dilation (see below)
% to find local maxima.  Maxima are refined with a 2D 
% Gaussian or centroid fit and returned in the matrix 'objs' 
% which has the following form:
%  [x;
%   y;
%   mass;  (i.e. brightness)
%   particleid;
%   frame;
%   trackid;
%   sigma]
%
% sigma is the 2D Gaussian width (std)('nonlineargauss'), the avg. of the x and
%    y Gauss fit ('lineargauss') or is zero ('centroid')
% frame and trackid are set to zero for all objects by fo4() and must be
% dealt with by the functions calling fo4().
%
% In earlier version, renamed fo4_rp_bpfilter.m:
%   Finds local minima as well, and filters maxima to be greater than p
%      (input) standard deviations above 3 nearest minima
%   Use bpfilter, filtering element "h"

% Raghuveer Parthasarathy, April 2007
% Modifications -- 
% Dilation: Originally use MATLAB's imdilate, but then use graydil.m (Luigi
%   Rosa, 2003, http://www.mathworks.com/matlabcentral/fileexchange/4163 --
%   faster for grayscale images); requires prior compilation of .mex file
%   (mex gdil.c) to create (on Windows XP) gdil.mexw32 .
% CENTROID seems to give 'quantized' output -- avoid if possible and 
%    use Gaussian fit instead.
%    Centroid fitting still allowed as an option -- useful for 
%    saturated images
% Implement 2D Gaussian fit to local maxima to find particle centers.
%    Seems to suffer less from quantization issues? -- 2 June 2007
% More Gaussian fit issues:
%    -- Use gaussfit2D.m for the Gaussian fitting, with a (fixed) 
%    threshold of 0.2.  Also: subtract the minimum value from the intensity profile --
%    otherwise the threshold is meaningless . RP Mar 3, 2011 
%    --  Allow the most accurate option -- nonlinear fit to a 2D
%    Gaussian .   The "intensity" (row 3 of the object
%    matrix) is pi*A*sigma_x*sigma_y  -- March 24, 2011
% March 24, 2011 (option for nonlinear 2D Gaussian fit)
% March 31, 2011 (returns the Gaussian width, sigma)
% June 8, 2011: Allow threshold to set a max no. of particles
% July 1, 2011: Remove use of graydil.m, since it requires recompiling on
% my new computer (RP)
% August 8, 2011: Allowing thresholding to find centers of only 
%    the 'n' brightest objects
% August 31, 2011: Allow radial symmetry based fitting
% October 24, 2011: std. dev. based thresholding
% Feb. 11, 2012: add max. likelihood Gaussian fit
% May 2, 2012 : move thresholding to a function: calcthreshimg.m
% Last modified May 22, 2012

% Fitting option; default is nonlinear Gaussian
if ~exist('fitstr', 'var') || isempty(fitstr)
    fitstr = 'radial';
end
if ~exist('lsqoptions', 'var') || isempty(lsqoptions)
    % This variable is only used for non-linear Gaussian fitting.
    lsqoptions = optimset('lsqnonlin');
end

showplots=false;  % for debugging -- plot things.

% Determine thresholding option -- see header comments 
if thresh >= 1.0
    threshopt = 3;
elseif thresh >= 0.0
    threshopt = 1;
else
    threshopt = 2;
    thresh = -thresh;  % note that negative thresh is the indicator of this option;
                       % flip so it's positive.
end

% DELETE
% ste = strel('disk', floor(objsize/2),0);  % for dilation


% make img processable
img = double(img);

% Bandpass filter (if objsize > 0) -- use Grier et al bpass.m
if objsize>0
    noisesize = 1;  % size of noise, px
    filtimg = bpass(img,noisesize,objsize);
else
    filtimg = img;
end

if showplots
    figure(1)
    imagesc(img); colormap(gray); title('1 original image')
    figure(2)
    imagesc(filtimg); colormap(gray); title('2 bandpass filtered')
end

% Three options for thresholding -- see above
% For the chosen option, determine the points that "pass" the threshold.
% Move to a separate function, so it can be called by the GUI
[y, x] = calcthreshpts(filtimg, threshopt, thresh, objsize);

% Get rid of maxima too close to the edge
lenx = 2*floor(objsize/2) + 1;  % 'floor' isn't really necessary, but this 
    % is the size of "nhood = getnhood(ste);" for a disk structuring
    % element of that size
leny = lenx;  % in principle, could make different
edgeind = ((x < lenx/2) | (x > (size(img,2) - lenx/2))) | ...
    ((y < leny/2) | (y > (size(img,1) - leny/2)));
x(edgeind) = [];
y(edgeind) = [];
   
% Compute "masses"
savemass = zeros(1, length(x));
rect = zeros(length(x), 4);
% Compute the first neighborhood of a maximum, to know the image size
% Can skip if there are no objects to find
if ~isempty(x)
    rect(1,:) = [round(x(1) - lenx/2) round(y(1) - leny/2) (lenx-1) (leny-1)];
    cropimg1 = imcrop(img, rect(1,:));
    % all the other neighborhoods
    cropimg = repmat(cropimg1, [1 1 length(x)]);
    for k = 2:length(x)
        rect(k,:) = [round(x(k) - lenx/2) round(y(k) - leny/2) (lenx-1) (leny-1)];
        cropimg(:,:,k) = imcrop(img, rect(k,:));
    end
end

% Calculate "mass" (intensity)
nhood = getnhood(strel('disk', floor(objsize/2),0));  % somewhat silly
for k = 1:length(x)
    tempreg = cropimg(:,:,k);
    if(size(cropimg1) == size(nhood))
        cropreg = tempreg(nhood);
    else
        cropreg = tempreg;
    end
    savemass(k) = sum(cropreg(:));
end

% Do refinement (find center)
xn = zeros(1,length(x));
yn = zeros(1,length(x));
sigma = zeros(1,length(x));
for i = 1:length(x)
    lsumx = 1:size(cropimg,2);
    lsumy = 1:size(cropimg,1);
    Lx = lsumx(end);
    Ly = lsumy(end);
    switch lower(fitstr)
        case {'lineargauss'}
            % Linear gaussian fit
            % Linear regression -- fit of cropimg intensity to a 2D Gaussian,
            % via polynomial fit of log(intensity),
            % using gaussfit2D.m with a 0.2 threshold
            % figure; surf(cropimg); shading interp; pause
            [A, x0, sigma_x, y0, sigma_y] = gaussfit2D(lsumx, lsumy, cropimg(:,:,i), 0.2);
            if imag(x0)>0.0
                xcent = 0.0;  % return zero -- nonsense
            else
                xcent = x0;
            end
            if imag(y0)>0.0
                ycent = 0.0;  % return zero -- nonsense
            else
                ycent = y0;
            end
            sigma(i) = 0.5*(sigma_x+sigma_y);  % mean Gaussian width
        case {'nonlineargauss'}
            % Gaussian fit via nonlinear least squares
            [A, xcent, ycent, sigma(i), offset] = gaussfit2Dnonlin(cropimg(:,:,i), [], [], [], [], lsqoptions);
            % savemass(i) = A*2*pi*sigma(i)*sigma(i);  % Area under a 2D gaussian
            %        Don't use this, since gives large values for weak Gaussians
        case {'gaussmle'}
            % Gaussian fit via maximum likelihood estimmation -- most accurate
            [A, xcent, ycent, sigma(i), offset] = gaussfit2Dmle(cropimg(:,:,i));
        case {'radial'}
            % Radial-symmetry based fit -- fase, accurate
            [xcent, ycent, sigma(i)] = radialcenter(cropimg(:,:,i));
            % Is the center within reasonable bounds?  
            % If not, replace with centroid
            % See notes Oct. 26, 2011: frequency of bad cases ~ 1/100,000 !
            % This conditional statement does slow things (+50% !).
            % Delete?
            if abs(xcent - Lx/2)>1.5*Lx || abs(ycent - Ly/2)>1.5*Ly 
                ci = cropimg(:,:,i);
                xcent = sum(sum(ci) .* lsumx) / sum(sum(ci));
                ycent = sum(sum(ci,2) .* lsumy') / sum(sum(ci,2));
            end
        case {'weightedlineargauss'}
            % Linearized Gaussian fit, weighted for noise (Stephen M.
            % Anthony, Steve Granick -- see Langmuir paper)
            % Need "noiselevel"  std dev of background noise
            % Function gauss2dcirc.m written by Stephen M.
            % Anthony.
            noiselevel = 220;
            disp('hardwiring noise level!!!  -- re-write this')
            [xcent,ycent,A,sigma(i)] = ...
                gauss2dcirc(cropimg(:,:,i),repmat(lsumx,size(cropimg,1),1),...
                repmat(lsumy',1,size(cropimg,2)),noiselevel);
        case {'centroid'}
            % centroid (center of mass) fit
            ci = cropimg(:,:,i);
            % cisub = ci - min(ci(:));
            xcent = sum(sum(ci) .* lsumx) / sum(sum(ci));
            ycent = sum(sum(ci,2) .* lsumy') / sum(sum(ci,2));
            %xcent = sum(sum(cisub) .* lsumx) / sum(sum(cisub));
            %ycent = sum(sum(cisub,2) .* lsumy') / sum(sum(cisub,2));
        otherwise
            disp('Unknown method! [fo4_rp.m]');
    end
    % center position relative to image boundary
    xn(i) = xcent + rect(i,1) - 1; % -1 is to correct for matlab indexing
    yn(i) = ycent + rect(i,2) - 1;
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
objs(7,:) = sigma;
