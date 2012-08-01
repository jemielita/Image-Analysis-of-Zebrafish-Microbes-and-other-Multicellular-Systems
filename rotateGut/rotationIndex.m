%rotationIndex: get the indices in the original image that map to points in
%the rotated image. Will be used to quickly rotate images using nearest
%neighbor interpolation for rotation (not ideal, but it's quick).
%
% USAGE [origIndex, rotIndex] = rotationIndex(mask, angle)
%
% AUTHOR Matthew Jemielita, July 31, 2012

function [origIndex, rotIndex] = rotationIndex(mask, angle)

ind = find(mask~=0);
mask(ind) = ind;

rotMask = imrotate(mask, angle);

rotIndex = find(rotMask~=0);

origIndex = rotMask(rotIndex);


end