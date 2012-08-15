function [] = aveRadDist(radialMask, radialIm, ~, varargin)

L = logical(radialMask);
props = regionprops(L);
center = props.Centroid;

%Get the maximum radius that we'll see for this data
perim = bwperim(radialMask);
[x, y] = find(perim==1);

dist = sqrt((x-center(1)).^2 + (y-center(2)).^2);
maxRadius = max(dist); maxRadius = floor(maxRadius);

%Get the coordinates for all points on the circle.
numPoints = 2*2*pi*sum(1:maxRadius); %The extra two is there for good measure.
numPoints = round(numPoints);

x = -1*zeros(numPoints, 1); y = -1*zeros(numPoints,1); n= 1;

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
       n = n+1;
       
   end
end
%Unpad the arrays
index = find(x==-1);
x(index) = [];
y(index) = [];


%Interpolate at these points 
z = interp2(radialIm, x, y);

%Unpack these values to give the intensity as a function of radius
n = 0;
intenR = zeros(maxRadius,1);

for radius = 1:maxRadius
   
   for tn=1:numTheta
       intenR(n) = z(n);
       n = n+1;
   end
end


end

