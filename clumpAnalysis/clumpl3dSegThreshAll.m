%clump3dSegThresh: Calculate properties of each clump found in this
%particular scan
%
% USAGE cc = clump3dSegThresh(param, scanNum, colorNum, saveVal)
% AUTHOR Matthew Jemielita, April 2, 2014

function cc = clump3dSegThreshAll(param, scanNum, colorNum, saveVal)

%% Load in variables
fileDir = param.dataSaveDirectory;

inputVar = load([fileDir filesep 'bkgEst' filesep 'fin_' num2str(scanNum) '_' param.color{colorNum} '.mat']);

maskAll = inputVar.segMask;

imMIP = imread([fileDir filesep 'FluoroScan_' num2str(scanNum) '_' param.color{colorNum} '.tiff']);

fprintf(1, ['Scan: ', num2str(scanNum) '  color: ', param.color{colorNum}]);


%% Finding connected components
labelMatrix = bwlabel(maskAll);
ind = unique(labelMatrix(:)); ind(ind==0) = [];
arrayfun(@(x)clump3dSegThresh(param, labelMatrix, x, saveVal), ind);

end