%minBoundBox: For a binary mask and image return an image and mask
%containing the smallest bounding box around that mask
%
%

function [mask, im, range] = minBoundBox(mask, im)

x = sum(mask,2)>1;
xMin = find(x==1, 1, 'first');
xMax = find(x==1, 1, 'last');

y = sum(mask,1)>1;
yMin = find(y==1, 1, 'first');
yMax = find(y==1, 1, 'last');


im = im(xMin:xMax,yMin:yMax);
mask = mask(xMin:xMax,yMin:yMax);

range = [xMin, xMax; yMin, yMax];

end