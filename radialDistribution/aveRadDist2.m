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

function intenR = radDist(radialIm, centerPoint, radBin, varargin)

center(1) = 50; %This is going to come as an input from centerLine-our line that we drew through the center of the gut
center(2) = 50; %This should be some prescribed midpoint of the radial projection, either the center of mass or the geometric mean of the data


%Find the maximum distance of all these points to the center-this is the
%maximum radius we'll find


%Get the maximum radius that we'll see for this data
perim = bwperim(radialIm>0);
[x, y] = find(perim==1);

dist = sqrt((x-center(1)).^2 + (y-center(2)).^2);
maxRadius = max(dist); maxRadius = floor(maxRadius);

%Get the coordinates for all points on the circle.
numPoints = 2*2*pi*sum(1:maxRadius); %The extra two is for padding
numPoints = ceil(numPoints);

x = NaN*zeros(numPoints, 1); y = NaN*zeros(numPoints,1);
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
       y(n) = center(2) + radius*sin(theta);
       
       allTheta(n) = theta;
       n = n+1;
       
   end
end

%Unpad the arrays
index = find(isnan(x));
x(index) = [];
y(index) = [];
allTheta(index) = [];
%Remove indices that shot past the boundaries of the region
dist = sqrt( (x-center(1)).^2 + (y-center(2)).^2);
index = find(dist>maxRadius);
x(index) = []; y(index) = []; allTheta(index) = [];
dist(index) = [];
%Interpolate at these points 
z = interp2(radialIm, x, y);

%Unpack these values to give the intensity as a function of radius


%Bin these intensities appropriately
%Convert distance to microns
dist = 0.1625*dist;
dist = dist-mod(dist, radBin);

radius = unique(dist);
%For all given radii find the positions in the interpolated image that have
%that distance to the center of the region. For all those points calculate
%the mean pixel intensity.
intenR = arrayfun(@(r)nanmean(z(find(dist==r))), radius, 'UniformOutput', false);
intenR = cell2mat(intenR);

intenR = cat(2, radius, intenR);
end

