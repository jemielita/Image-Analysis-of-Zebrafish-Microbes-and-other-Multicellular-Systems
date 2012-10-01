%histCurve: Calculating a histogram of pixel intensites at each point along
%a mask
%
%Author: Matthew Jemielita, Sep 13, 2012


function histL = histCurve(im, regionMask, centerLine, binVect)

totalNumMask = size(regionMask,3);

%Duplicate the mask.
regionMask =uint16(regionMask);

allReg = unique(regionMask(:));
intenL = zeros(length(centerLine),2);
fprintf(1, '\n');
for numMask = 1:totalNumMask
    %Get regions in this particular mask.
    
    regNum = unique(regionMask(:,:,numMask));
    regNum(regNum==0) = [];
    
    rMaskBig = repmat(regionMask(:,:,numMask), [1 1 size(im,3)]);
    fprintf(1, ['Getting intensity for mask: ', num2str(numMask), '\n']);
    inten = regionprops(rMaskBig, im,'MeanIntensity', 'MaxIntensity');

    
    meanInten = [inten(regNum).MeanIntensity];
    maxInten = [inten(regNum).MaxIntensity];%.maxIntensity is empty where meanInten was NaN-annoying
    
    intenL(regNum, 1) = meanInten;
    intenL(regNum,2) = maxInten;
      
end
fprintf(1, 'All intensities found! \n');