%Calculate the centroid of a vesicle and set of radius values for different
%thetas for the edge of the vesicle
%INPUT: im: binary output from the canny filter
%OUTPUT: centroid: location of the centroid of the vesicle
%        radiusAtTheta: N by 2 matrix. Every row: theta radius(theta)

function guv = vesicleProp(im, numTheta)

%convert to double
im = double(im);

%Calculate the centroid

prop = regionprops(double(im), 'Centroid');
centroid = prop.Centroid;
guv.ctr(1) = centroid(1);
guv.ctr(2) = centroid(2);

%Find pixel locations on the boundary.
[y x] = find(im>0);

%Get the angle for each of these points
theta = atan( (x-centroid(1))./(y-centroid(2)));

%atan returns values that run from -pi/2 to pi/2. Convert this into a theta
%range that goes from 0 to 2pi by adding pi to the answer if x-centroid is
%negative.
index = find(x<centroid(1));
theta(index) = theta(index) + pi;

%Shifting theta to run from 0 to 2pi
theta = theta + 0.5*pi;

%And the radius
radius = sqrt((x-centroid(1)).^2 + (y-centroid(2)).^2);

%Interpolating the results (note: you can't interpolate outside the region
%that we've analyzed...even though the function is cyclic.
thetaOut = min(theta): (2*pi)/numTheta : max(theta);

radiusOut = interp1(theta,radius, thetaOut);

%Storing the result in the form used by the other code for fluctuation
%analysis.

guv.phi = thetaOut;
guv.R = radiusOut;



end