%Apply the mask that outline the gut

function [im] = applyRegionMask(im, param)

[temp, BW] = roifill(im, param.regionExtent.poly(:,1), param.regionExtent.poly(:,2));

im(~BW) = 0;


end