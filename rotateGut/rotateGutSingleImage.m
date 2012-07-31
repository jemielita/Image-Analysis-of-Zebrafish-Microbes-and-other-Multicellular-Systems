% rotateGutSingleImage: Rotate and crop an image of a gut so that the pricipal axis of
% the gut is along the x-axis.
%
% USAGE:
% imOut = rotateGutSingleImage(im, mask,angle)
%
% INPUT: mask: an n x m binary mask of the region of interest
%        im: an n x m image of the gut
%        angle: angle that the gut needs to be rotated by in order for the
%        principal axis to line up with the x-axis.
% OUTPUT: imOut: rotated image of the gut, cropped down to the smallest size
%
% AUTHOR: Matthew Jemielita, July 27, 2012

function imOut = rotateGutSingleImage(im, mask, angle)


%Rotate image
maskRotate = imrotate(mask, angle);
imOut = imrotate(im,angle);

imOut(~maskRotate) = 0;

%Crop down image
ind = find(maskRotate==1);
[x y] = ind2sub(size(maskRotate),ind);

minX = min(x); maxX = max(x);
minY = min(y); maxY = max(y);

imOut = imOut(minX:maxX, minY:maxY);

end