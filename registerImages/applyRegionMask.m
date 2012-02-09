%applyRegionMask: Returns an image that contains the regions 

function im = applyRegionMask(im, param)

[temp, BW] = ...
    roifill(im, param.regionExtent.poly(:,1), param.regionExtent.poly(:,2));

im(~BW) = 0;

end