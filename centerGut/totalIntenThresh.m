%totalIntenThresh: Calculate the total pixel intensity above
%above a given threshold
%
% USAGE intenL = intensityCurve(im, regionMask,centerLine, param)
%
% INPUT regionMask: n x m x p mask containing integers. n x m is the same
% dimension as im and p is the number of different layers of region masks
% (allowing us to calculate statistics for regions that are overlaping).
%       im: n x m double image or image stack.
%       centerLine: Line along with we are calculating the intensity
%       param: parameter file for this fish. Will be used to find where to
%       cut the image to avoid regions outside the gut (By default we'll
%       cut out everything after the fiducial marker used to mark the end
%       of the region of autofluorescent cells).
%       
% OUTPUT intenL: nx1 array containing the total pixel intensity in the gut
%        above a range of intensity threshold cutoffs.
%
% AUTHOR: Matthew Jemielita, March 14, 2014

function intenL = totalIntenThresh(im,regionMask,scanNum, cutNum, centerLine, param)

%% Making a mask to exclude all regions that are past the autofluorescent region of the gut

%Loading in cut regions-to see how to exclude regions
inputVar = load([param.dataSaveDirectory filesep 'masks' filesep 'cutVal.mat']);
cutVal = inputVar.cutValAll{scanNum};

%Quick and dirty way to exclude stuff in the end of the gut
if(cutNum>1)
   minRegNum = cutVal{cutNum,1}(1);
   %Remove all regions past the end of the autofluorescent cells
   regionMask(regionMask(:)+minRegNum-1 > param.gutRegionsInd(scanNum,4)) = 0;
end

totalNumMask = size(regionMask,3);
maxNumReg = 60; %Maximum number of regions to calculate the properties of at the same time
%Duplicate the mask.
regionMask =uint16(regionMask);

allReg = unique(regionMask(:));

intenL = zeros(length(centerLine),2);

fprintf(1, '\n');
insideGutMask = zeros(size(regionMask,1), size(regionMask,2));

%Index that's our cutoff for being inside the gut-we'll be doing our cutoff
%at the end of the autofluorescent cells in the gut.
ind = param.gutRegionsInd(scanNum,4);
for numMask = 1:totalNumMask
insideGutMask(regionMask(:,:,numMask)<=ind &(regionMask(:,:,numMask)>0)) = 1;
end
%Removing stuff outside the image region
for nZ = 1:size(im,3)
    thisIm = im(:,:,nZ);
    thisIm(~insideGutMask) = 0;
    im(:,:,nZ) = thisIm;
end

%Now calculating all the sums
tic;
threshVal = 100:50:800;
intenL = zeros(length(threshVal),1);

for i=1:length(threshVal)
   intenL(i) = sum(im(im(:)>threshVal(i))); 
end

clear rMaskBig
fprintf(1, 'All intensities found! \n');

end