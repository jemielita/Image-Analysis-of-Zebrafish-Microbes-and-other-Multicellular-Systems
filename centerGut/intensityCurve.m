%For a given regionMask and im, returns the intenL vs. number associated
%with that region.
function [intenL] = intensityCurve(regionMask, im)


totalNumMask = size(regionMask,3);

%The number of regions is the number of unique elements in regionMask. This
%should be an input parameter, but for now we'll find it by hand
numReg = unique(regionMask(:));
numReg = sum(numReg>0);

intenL = zeros(numReg,1);

for numMask = 1:totalNumMask
    props = regionprops(regionMask(:,:,numMask), im, 'MeanIntensity', 'Area');
    props = [props.MeanIntensity].*[props.Area];
    
    %Get the elements that are numbers (NaN are for label matrices that
    %weren't picked up in this iteration.
    intenL(~isnan(props)) = props(~isnan(props));
end


end