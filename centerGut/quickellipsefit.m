% quickellipsefit.m
% quickly written function to fit an ellipsoid to a bright "rod" image, 
% using centroid finding and principal component analysis to determine the 
% orientation 
%
% Input: image (A)
% Outputs:
%    xcent, ycent : centroid (px, relative to top left corner)
%    ecc : eccentricity
%    theta : orientation, radians; note y increases downward, so "upside
%            down"
%    eig, eig2 : major and minor axis lengths
%
% Raghuveer Parthasarathy
% Sept. 13, 2011

function [xcent ycent ecc theta eig1 eig2] = quickellipsefit(A)

[ny nx] = size(A);
[px py] = meshgrid(1:nx, 1:ny);  % a grid of coordinates; note that y increases downward

A = double(A); % make process-able
sumA = sum(A(:));

% centroid
xcent = sum(sum(A.*px))/sumA;
ycent = sum(sum(A.*py))/sumA;

% Variance and covariance
xvar = sum(sum(A.*(px-xcent).*(px-xcent)))/sumA;
yvar = sum(sum(A.*(py-ycent).*(py-ycent)))/sumA;
xyvar = sum(sum(A.*(px-xcent).*(py-ycent)))/sumA;

% Calculate eigenvalues of the variance-covariance matrix
% (These are the major and minor axes of the best-fit ellipse)
D = sqrt((xvar-yvar).*(xvar-yvar) + 4*xyvar*xyvar);
eig1 = 0.5*(xvar+yvar+D);
eig2 = 0.5*(xvar+yvar-D);

% Eccentricity
ecc = sqrt(1-(eig2/eig1)^2);
% Could also use (eig1-eig2)/(eig1+eig2) as a measure of circularity; I
% think this is the "third eccentricity"

% Angle w.r.t. x-axis.  Note that y increases downward
theta = atan((eig1-xvar)/xyvar);

