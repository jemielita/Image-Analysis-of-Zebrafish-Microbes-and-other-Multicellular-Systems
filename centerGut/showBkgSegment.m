%showBkgSegment: Show a mask over images of the gut indicating what regions
%will be picked up by our coarse analysis of the gut microbial population.
%
% USAGE segMask = showBkgSegment(im, scanNum, colorNum, param, bkgOffset)
%
% INPUT im: image of the gut on which a mask will be applied.
%       scanNum and colorNum: which color and scan to calculate the
%         background estimator for.
%       param: parameter file for this fish
%       bkgOffset: Offset in background to use.
% OUTPUT segMask: binary mask with segmented regions given by 1s.
%
% AUTHOR Matthew Jemielita, March 24, 2014

function segMask = showBkgSegment(im, scanNum, colorNum, param, bkgOffset)

%Load in background mask
inputVar = load([param.dataSaveDirectory filesep 'bkgEst' filesep 'bkgEst_' param.color{colorNum} '_nS_' num2str(scanNum) '.mat']);

bkgMask = inputVar.segMask;

%Subtract background estimation from image
segMask = (double(im)-(bkgMask*bkgOffset)>0);



end