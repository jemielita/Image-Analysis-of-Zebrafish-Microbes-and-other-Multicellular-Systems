%optimalAngle: calculate the angle to rotate a mask so that a rectangle
%bounding the mask has as small an area as possible.
%
%USAGE [height, width, angle, rotImSize] = optimalAngle(mask)
%
%INPUT mask: binary n x m  mask
%
%OUTPUT height and width: height and width of the bounding rectangle
%       angle: angle that the original mask needs to be rotated by to get
%       the optimal rotation.
%       rotImSize (1,2): size of rotated (pre-cropped) mask
%       rotImSize (3:6): xMin, xMax, yMin, yMax for cropped rotated mask
%AUTHOR Matthew Jemielita, July 30, 2012

function [height, width, angle, rotImSize] = optimalAngle(mask)

%Get points on the surface of the mask
mask = bwperim(mask);
ind = find(mask==1);
[x,y] = ind2sub(size(mask), ind);
X = cat(1,x',y');

[~, angle,~, ~] = minBoundingBox(X);

%mlj: note the code below could be run *much* faster if only the points on
%the perim are rotated.
%Rotate mask
maskRotate = imrotate(mask, angle);

%Crop down image
ind = find(maskRotate==1);
[y x] = ind2sub(size(maskRotate),ind);

minX = min(x); maxX = max(x);
minY = min(y); maxY = max(y);

height = maxY-minY+1;
width = maxX-minX+1;

rotImSize(1:2) = size(maskRotate);
rotImSize(3) = minX;
rotImSize(4) = maxX;
rotImSize(5) = minY;
rotImSize(6) = maxY;

% 
% rotMat = [cos(angle), -sin(angle); sin(angle), cos(angle)];
% 
% rotVal = rotMat*X;


end