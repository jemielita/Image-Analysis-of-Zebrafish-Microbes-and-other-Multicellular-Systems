% getGUVedge.m
%
% Function to determine the contour of a giant vesicle from a fluorescence
% image.  
% Determines the "center of mass" of the intensity (I) vs. radial
% coordinate (rho) at a given angle (phi), using I(rho) at the previous phi
% to define the bounds of the fit.  This approach, compared to looking
% for a simple maxima or using all rho to fit I(rho) provides greater
% precision and also is less sensitive to "junk" in the image, since the
% edge position should not change sharply as a function of phi.
%
% Examines phi from -pi to pi Counterclockwise and then clockwise; takes
% the average of the two weighted by the edge intensity.
% If the input image is the "first" in a series, the user is asked to
% roughly determine the vesicle center and the initial search bounds.
%
% See note Jan 26-27, 2011. It is strongly recommended that the image
% first be processed by smoothing and ridge finding!
%
% INPUT
% A : fluorescence image of a GUV or (better) ridge-finding output of a
%     fluorescence image
% ctr : Array ([xcenter ycenter]) locating the GUV center, determined
%       when this function was previously called (i.e. previous image)
%       If EMPTY ([]), prompt user to roughly determine center (to be more
%       precisely fixed later after the contour is determined)
% roughR : approximate vesicle radius,  determined
%       when this function was previously called (i.e. previous image)
%       If ctr is EMPTY ([]), prompt user to determine via edge bounds
% dR :  2-element array of the radial width to examine for local maximum,  
%       determined when this function was previously called (i.e. previous image)
%       dR(1) is the range in -R, dR(2) is the range in +R (i.e. we'll
%       examinine R-dR(1) to R+dR(2)
%       If ctr is EMPTY ([]), prompt user to determine via edge bounds
% CMthresh : Intensity threshold for determining "center of mass" edge position
%       -ignore points dimmer than CMthresh*maxIntensity)  Default 0.35
% scale : image scale, microns per pixel (typically 0.11)
% res :   resolution (microns: should be roughly wavelength/2, or greater)
%       Default  0.5.  This sets the edge size for fitting I(rho)
% showplots : true to display plots
%
% OUTPUT
%    R = vesicle radius (pixels)at each angle phi.
%    phi = array of all angles
%    Amp = Intensity at R (at each phi)
%    newc = re-calculated vesicle center (= mean of x and y positions of
%           edge pixels).  two-element array of [x y] position
%    dR = radial width array (see above)
%    closedflag = true if the contour does not properly close; false if ok
%
% based on temp23Dec10.m
% See notes: Dec. 23, 2010
%
% Raghuveer Parthasarathy
% December 28, 2010
% last modified January 27, 2011


function [R, phi, Amp, newc, dR, closedflag] = ...
    getGUVedge(A, ctr, roughR, dR, CMthresh, scale, res, showplots)


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


if isempty(ctr)
    % user needs to select approximate vesicle center, and bounds of edge
    % at phi = -pi.
    him = figure; imagesc(A); colormap('gray');
    % User input: get center
    disp(' ')
    disp('** getGUVedge.m **')
    disp(' ')
    disp('  Double click at (roughly) the center of the vesicle')
    [cx, cy, c] = improfile;
    hold on
    plot(cx, cy, 'yo')
    plot(1:cx, cy*ones(size(1:cx)), 'g:')
    
    % User input: get radial range closely spanning vesicle edge
    disp('  Left and right click spanning the left and right sides of the');
    disp('      vesicle edge, along the green line.')
    disp('  Suggestion: span a fairly small range.')
    [cAx, cAy, cA] = improfile;
    A1 = min(cAx);
    A2 = max(cAx);
    % simple mean of user-input line
    %    roughR = cx - 0.5*(A1+A2);
    % Max intensity position of the user-input line: use this as a rough R
    [maxcA, maxposcA] = max(cA);
    roughR = cx - cAx(maxposcA);
    dR = [(A2 - cAx(maxposcA)) (cAx(maxposcA)-A1)];  
         % radial width of swathe to examine
    if (A2-A1) < 6
        disp('WARNING:  width to examine must be at least 6 pixels. ')
        disp('  Forcing: width = 6 px. (will pause 2 seconds)');
        dR = [3 3];  % so that 5px parabolic fit works
        pause(2)
    end
else
    cx = ctr(1); cy = ctr(2);
end

[allr, allphi] = calcrphi(A, cx, cy);
% Note that phi is in [-pi,pi]

allA = double(A);
allA = allA(:);
allr = allr(:);
allphi = allphi(:);

temp_dphi = res / roughR / scale;
% Want an integer number of bins
Nphi = floor(2*pi/temp_dphi);
dphi = 2*pi/Nphi;
phi = (0:Nphi-1)*dphi - pi;  % array of all central phi values of angular bins
% Note offset to be consistent with calcrphi, above

% figure out which phi bin each pixel in the image corresponds to
% bin1 is a bit tricky: pi-dphi/2 to -pi + dphi/2;
% bin2 = -pi + dphi/2 to  -pi + 3*dphi/2, ...
whichbin = ceil((allphi - (-pi - dphi/2))/dphi);
% fine except for angles between pi-dphi/2 to pi, which should be in bin1
whichbin(whichbin==(Nphi+1)) = 1;

% Figure out ahead of examining each slice what the r and intensity values
% corresponding to each slice are.
% Reorder the allr and allA arrays so that elements 1:nw(1) correspond to
% slice 1, where nw(1) is the number of elements; nw(1)+1:nw(1)+nw(2) are
% slice 2, etc.
[sortwb swbix] = sort(whichbin);
sortallr = allr(swbix);
sortallA = allA(swbix);
Nisslice = zeros(size(phi));
for k=1:Nphi
    Nisslice(k) = sum(whichbin==k);
end

if showplots
    fs = sprintf('Angular bin size %.3f radians; Nphi = %d', dphi, Nphi); disp(fs)
end

diagnosticplots = false;
if diagnosticplots
    hwedge = figure;
end

% ----------------------------------------------------------------------

edgeR = zeros(size(phi));
Amp = zeros(size(phi));

% Consider angular bins, CCW from -pi to pi
for j=1:Nphi
    if j==1
        % the first bin.  Use roughR as the "previous" radial position
        % to determine the swathe relative to
        pR = roughR;
    else
        pR = edgeR(j-1);
    end
    [edgeR(j) Amp(j)] = wedge_getedge(j, pR);
end

% Revisit the first phi bin
pR = edgeR(Nphi);
edgeR0  = wedge_getedge(1, pR);
closedflag = abs(edgeR0-edgeR(1))>res;  % true if the two determinations don't match

edgeRCW = zeros(size(phi));
AmpCW = zeros(size(phi));
% Consider angular bins, CW from -pi to pi
for j=1:Nphi
    if j==1
        pR = roughR;
    else
        pR = edgeRCW(j-1);
    end
    [edgeRCW(j) AmpCW(j)] = wedge_getedge(Nphi-j+1, pR);
end
edgeRCW = fliplr(edgeRCW);  % make the same order as edgeR

% Weighted average of both directions
weightR = (Amp.*edgeR + AmpCW.*edgeRCW)./(Amp + AmpCW);
% hold on; plot(edgeR, weightR-edgeR, 'rs')

% Determine actual vesicle center, and correct radial distances accordingly
xR = cx + weightR.*cos(phi) ;  % x positions of edges
yR = cy - weightR.*sin(phi);  % y positions of edges; note inversion since cy rel. to top

truecx = mean(xR);
truecy = mean(yR);

% array of "true" radial values
R = sqrt((xR-truecx).*(xR-truecx) + (yR-truecy).*(yR-truecy));
newc = [truecx truecy];  % array containing true center position

if showplots
    figure; imagesc(A); colormap('gray')
    hold on
    if closedflag
        plot(newc(1) + R.*cos(phi), newc(2) - R.*sin(phi), 'rx');
    else
        plot(newc(1) + R.*cos(phi), newc(2) - R.*sin(phi), 'yx');
    end
end


% Will make the edge finding a nested function, since it's called
% repeatedly (forwards and backwards in phi)
% Note that nested functions can use the workspace of the outer function

    function [eR  Amp] = wedge_getedge(k, prevR)
        % k == wedge number
        % prevR = edge position from the previously analyzed wedge
        
        slicer = sortallr(sum(Nisslice(1:k))-Nisslice(k)+1:sum(Nisslice(1:k)));
        sliceA = sortallA(sum(Nisslice(1:k))-Nisslice(k)+1:sum(Nisslice(1:k)));
        isannulus = (slicer-prevR)<dR(2) & (prevR-slicer)<dR(1);
        wedger = slicer(isannulus);
        wedgeA = sliceA(isannulus);
        
        % "center of mass" fit in this region.  Use dimmest pixel as
        % background
        try
            bkgd = min(wedgeA);
            Asub = wedgeA - bkgd;
            fitA = Asub(Asub>=(CMthresh*max(Asub)));
            fitr = wedger(Asub>=(CMthresh*max(Asub)));
            eR = sum(fitr.*fitA)/sum(fitA);  % "center of mass"
            Amp = max(fitA);
        catch
            disp('error here')
        end
        if isempty(Amp)
            % strange -- this shouln't happen
            disp('Amp is empty??')
            fitA
            % figure;  plot(wedger, wedgeA, 'ko'); title(num2str(j))
            pause(2)
        end
        if diagnosticplots % && abs(eR-prevR)>2
            % diagnostic plots
            figure(hwedge); clf; plot(wedger, wedgeA, 'ko'); title(num2str(j))
            hold on
            plot(fitr, fitA, 'ko', 'markerfacecolor', 0.7*[1 1 1])
            plot(eR, Amp, 'ro');
            figure(him)
            plot(cx + eR*cos(phi(k)), cy - eR*sin(phi(k)), 'rx');
            pause(0.2)
        end
    end

% end of main function
end


