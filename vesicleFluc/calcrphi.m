% calcrphi.m
% 
% for each pixel in an image, calculates the distance to some origin and the
% angle of the vector to that pixel
%
% inputs
%    A : image (2D)
%    x : x-position of origin (e.g. vesicle center), pixels (rel. to left)
%    y : y-position of origin (e.g. vesicle center), pixels (rel. to top)
%
% outputs (2D arrays, the same size as A)
%    r : distance to origin (pixels)
%    phi : angle (radians), in [-pi, pi].  East = 0.
%
% RP July 28, 2010
% last modified Dec. 20, 2010


function [r, phi] = calcrphi(A, x, y)

s = size(A);

rw = repmat((1:s(1))',1,s(2));  % an array of row numbers, the same size as A
cl = repmat(1:s(2),s(1),1);     % columns

r = sqrt((rw-y).*(rw-y) + (cl-x).*(cl-x));  % 
phi = atan2(y-rw, cl-x);  % -pi to pi
% Use y-rw rather than rw-y so East = 0 radians

