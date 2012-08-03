%intensityCurve: Calculating mean and maximum pixel intensity for all
%points in the 2d or 3d image contained within certain masks.
%
% USAGE intenL = intensityCurve(regionMask, im)
%
% INPUT regionMask: n x m x p mask containing integers. n x m is the same
% dimension as im and p is the number of different layers of region masks
% (allowing us to calculate statistics for regions that are overlaping).
%       im: n x m double image or image stack.
% OUTPUT intenL: n x 2 array where n is the number of unique regionsin
% regionMask (excluding 0) and n(:,1) is the mean pixel intensity in
% different regions and (n:,2) is the maximum pixel intensity.
%
% AUTHOR: Matthew Jemielita, revised August 3, 2012

function intenL = intensityCurve(regionMask, im)
totalNumMask = size(regionMask,3);

%Duplicate the mask.
regionMask =uint16(regionMask);

allReg = unique(regionMask(:));
intenL = zeros(max(allReg),2);

for numMask = 1:totalNumMask
    fprintf(1, ['Getting intensity for mask: ', num2str(numMask), '\n']);
    %Get regions in this particular mask.
    regNum = unique(regionMask(:,:,numMask));
    regNum(regNum==0) = [];
    
    rMaskBig = repmat(regionMask(:,:,numMask), [1 1 size(im,3)]);
    inten = regionprops(rMaskBig, im,'MeanIntensity', 'MaxIntensity');

    
    meanInten = [inten(regNum).MeanIntensity];
    maxInten = [inten(regNum).MaxIntensity];%.maxIntensity is empty where meanInten was NaN-annoying
    
    intenL(regNum, 1) = meanInten;
    intenL(regNum,2) = maxInten;
      
end
fprintf(1, 'All intensities found! \n');

end