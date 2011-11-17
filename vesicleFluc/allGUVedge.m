% allGUVedge.m
% Takes a series of images, loaded by TIFFseries, and tracks
% the GUV edges using getGUVedge.m
% For each image, first apply a Gaussian smoothing filter, and then perform
% ridge-finding using FrangiFilter2D.m.  Then, sends this to getGUVedge.m
% For the first image, getGUVedge will ask for user-input approximate
% vesicle center and initial edge location.
%
% INPUT
% outA : array of images to consider (from TIFFseries)
% CMthresh : Intensity threshold for determining "center of mass" edge position
%       -ignore points dimmer than CMthresh*maxIntensity)  Default 0.35
% scale : image scale, microns per pixel (typically 0.11)
% res :   resolution (microns: should be roughly wavelength/2, or greater)
%       Default  0.5
% gausssig : width of Gaussian smoothing filter to apply.  Leave empty ([])
%       for default 1 px.  Set to zero for no filtering.
% ridgesig : width of the Ridge finding filter to apply.  Leave empty ([])
%       for default 1 px.  Set to zero for no ridge finding.
% dispopt : if true, show a picture of each GUV and the detected edge
%
% OUTPUT
% guv -- structured array.  Number of elements equals the number of images
%       .file -- file number
%       .R = vesicle radius (pixels)at each angle phi
%       .phi = array of angles (radians)
%       .Amp = Intensity of GUV edge for the given phi
%       .ctr = two-element array of vesicle center position [x y]
%       .closedflag = flag from getGUVedge with warning about closure
%
% Raghuveer Parthasarathy
% December 29, 2010
% last modified Jan. 27, 2011


function [guv] = allGUVedge(outA, CMthresh, scale, res, gausssig, ridgesig, dispopt)

Nimages = length(outA(1,1,:)); % number of images

if isempty(CMthresh)
    CMthresh = 0.35;  
    fs = sprintf('Using center of mass intensity threshold %.2f microns/px', CMthresh); disp(fs)
end
if isempty(scale)
    scale = 0.11;  % microns/px
    fs = sprintf('Using image scale %.2f microns/px', scale); disp(fs)
end
if isempty(res)
    scale = 0.5;  % microns/px
    fs = sprintf('Using resolution %.2f microns', res); disp(fs)
end
if isempty(gausssig)
    gausssig = 1;  % smoothing filter size, px
    fs = sprintf('Using %.d px smoothing filter', gausssig); disp(fs)
end
if isempty(ridgesig)
    ridgesig = 1;  % smoothing filter size, px
    fs = sprintf('Using %.d px ridge filter', ridgesig); disp(fs)
end
if or(nargin<7, isempty(dispopt))
    dispopt = false;
end

if gausssig > 0
    h = fspecial('gaussian', 7*gausssig*[1 1], gausssig);  % Filter for smoothing
end

% Ridge finding options
Options.BlackWhite = false;  % for white ridges
Options.FrangiScaleRange = ridgesig*[1 1];  
Options.verbose = false;

% Allocate memory 
guv = repmat(struct('file', {0}, 'phi', {[]}, 'R', {[]}, 'Amp', {0}, ...
    'ctr', {0}, 'closedflag', {0}), Nimages, 1);

if dispopt
    hguv = figure;
end

% ----------------------------------------------------------------
% Find vesicle edges

progtitle = 'Progress analyzing images...';  % create bar later
for k = 1:Nimages
    if gausssig > 0
        smoutA = filter2(h, outA(:,:,k));  % smoothed image
    else
        smoutA = outA(:,:,k);  % just use original image
    end
    if ridgesig > 0
        [ridgeA,whatScale,Direction] = FrangiFilter2D(smoutA, Options);
        % fill in white borders in ridgeA image
        ridgeA(1:4*ridgesig, :) = 0;
        ridgeA(size(ridgeA,1)-4*ridgesig+1:end, :) = 0;
        ridgeA(:,1:4*ridgesig) = 0;
        ridgeA(:, size(ridgeA,2)-4*ridgesig+1:end) = 0;
    else
        ridgeA = smoutA;  % unchanged
    end
    if k==1
        % first image; get initial center from starting image
        [R, phi, Amp, newc, dR, closedflag] = ...
            getGUVedge(ridgeA, [], [], [], CMthresh, scale, res, false);
        % Create progress bar after starting the loop so that the bar will
        % appear on top of the image window opened by getGUVedge
        progbar = waitbar(0, progtitle);  % will display progress
    else
        % uses previously determined R, dR, center
        [R, phi, Amp, newc, dR, closedflag] = ...
            getGUVedge(ridgeA, newc, mean(R), dR, CMthresh, scale, res, false);
    end
    guv(k).file = k;
    guv(k).phi = phi;
    guv(k).R = R;
    guv(k).Amp = Amp;
    guv(k).ctr = newc;
    guv(k).closedflag = closedflag;
    if dispopt
        % show image and edge
        figure(hguv)
        clf
        imagesc(outA(:,:,k)); colormap(gray);
        hold on
        plot(guv(k).ctr(1) + cos(guv(k).phi).*guv(k).R, guv(k).ctr(2) ...
            - sin(guv(k).phi).*guv(k).R, 'yx');
    end
    if mod(k,10)==0
        waitbar(k/Nimages, progbar, progtitle);
    end
end
close(progbar)


