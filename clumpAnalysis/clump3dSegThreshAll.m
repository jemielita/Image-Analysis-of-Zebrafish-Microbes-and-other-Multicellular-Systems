%clump3dSegThresh: Calculate properties of each clump found in this
%particular scan
%
% USAGE cc = clump3dSegThresh(param, scanNum, colorNum, saveVal)
% AUTHOR Matthew Jemielita, April 2, 2014

function cc = clump3dSegThreshAll(param, scanNum, colorNum, saveVal)

%% Load in variables
fileDir = param.dataSaveDirectory;

inputVar = load( [obj.saveLoc filesep 'masks' filesep 'allRegMask_' num2str(obj.scanNum) '_' param.color{obj.colorNum} '.mat']);
labelMatrix = inputVar.segMask;
ind = unique(labelMatrix(:)); ind(ind==0) = [];

imMIP = imread([fileDir filesep 'FluoroScan_' num2str(scanNum) '_' param.color{colorNum} '.tiff']);

fprintf(1, ['Scan: ', num2str(scanNum) '  color: ', param.color{colorNum}]);

%% If saveVal is true then delete everything that would be in the folder.
%This avoids issues where additional clumps may accidentally be created
sl = [fileDir filesep 'clump' filesep 'clump_' param.color{colorNum} '_nS' num2str(scanNum) ]; 
if(isdir(sl))
    rmdir(sl, 's');
    mkdir(sl);
end

%% Finding connected components
arrayfun(@(x)clump3dSegThresh(param, scanNum, colorNum, labelMatrix, imMIP,x, saveVal), ind);

end