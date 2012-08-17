% radDist: Calculate the average pixel intensity as a function of the
% distance from the center of the radial projection.
% The center of the radial projection is given by the point on the user
% drawn center of the gut and the location of the median pixel intensity in
% the other direction
%
% USAGE intenR = aveRadDist(radialIm, centerPoint, radBin)
%
% INPUT radialIm: 2D image of the radial projection of the gut at a certain
%          point
%       centerPoint: location of the center of the gut line
%          ex. If we load in projection radIM{2} then we also need to load
%          in centerLine{2}
%       radBin: The binning size in microns
% OUTPUT intenR: nx2 array where the first column is the radius and the
%         second column is the average intensity at that radius. More
%         properties of the radial distribution may be added over time.
%
% AUTHOR Matthew Jemielita, August 14, 2012
%
%NOTE: Not respecting axis ratio!!!-this should now be fixed. Worth
%checking again.


function intenR = radDist(radialIm, radBin, varargin)

%mlj: We should be more careful with how we propagate empty
%arrays-currently they arise from the beginning and ending masks in the
%line down the gut.
if(isempty(radialIm))
    intenR = [];
    return
end

center(1) = round(size(radialIm,1)/2);
%Along the z-axis find the point point that has the median pixel
%intensity-the sum of pixel intensties in all rows below this line is equal
%to the pixel intensities above this line.
zProj = nansum(radialIm,1);
if(sum(zProj(:))==0)
    %This mask is blank for some reason-probably towards the end of the gut
    intenR = [];
    return
end
zProj = zProj/sum(zProj(:));
zProj = cumsum(zProj);
center(2) = find(abs(zProj-0.5)==min(abs(zProj-0.5)), 1, 'first');

%Find the maximum distance of all these points to the center-this is the
%maximum radius we'll find


%Get the maximum radius that we'll see for this data
perim = bwperim(radialIm>0);
[x, z] = find(perim==1);
%Note
dist = sqrt((x-center(1)).^2 + (z-center(2)).^2);
maxRadius = max(dist); maxRadius = floor(maxRadius);

%Get the coordinates for all points on the circle.
numPoints = 2*2*pi*sum(1:maxRadius); %The extra two is for padding
numPoints = ceil(numPoints);

x = NaN*zeros(numPoints, 1); z = NaN*zeros(numPoints,1);
allTheta = NaN*zeros(numPoints, 1);
n= 1;%counter


for radius = 1:maxRadius
   %Appropriate dTheta to use at this radius so that at every given radius
   %we're sampling at points 1 pixel apart.
   
   perim = 2*pi*radius;
   numTheta = round(perim);
   dTheta = 2*pi/numTheta;
   
   for tn=1:numTheta
       theta = dTheta*tn;
       %We really should pre-allocate, but I doubt this will take all that
       %long either way.
       x(n) = center(1) + radius*cos(theta);
       z(n) = center(2) + radius*sin(theta);
       
       allTheta(n) = theta;
       n = n+1;
       
   end
end

%Unpad the arrays
index = find(isnan(x));
x(index) = [];
z(index) = [];
allTheta(index) = [];
%Remove indices that shot past the boundaries of the region
dist = sqrt( (x-center(1)).^2 + (z-center(2)).^2);
index = find(dist>maxRadius);
x(index) = []; z(index) = []; allTheta(index) = [];
dist(index) = [];
%Interpolate at these points 
imVal = interp2(radialIm, z, x);

%Unpack these values to give the intensity as a function of radius

%Bin these intensities appropriately
%Convert distance to microns in the x direction the spacing is 0.1625
%microns per pixel. In the z direction it's 1 micron per pixel (comes from
%how we've 
%
dist = sqrt( (0.1625*(x-center(1))).^2 + (z-center(2)).^2);

dist = dist-mod(dist, radBin);

radius = unique(dist);
%For all given radii find the positions in the interpolated image that have
%that distance to the center of the region. For all those points calculate
%the mean pixel intensity.
intenR = arrayfun(@(r)nanmean(imVal(dist==r)), radius, 'UniformOutput', false);
intenR = cell2mat(intenR);

%Remove trailing elements
ind = isnan(intenR);
radius(ind) =[]; intenR(ind) = [];
intenR = cat(2, radius, intenR);
end

