%analyzeGutTimeSeries: Analyze a time series of gut images for a single
%fish. This is *the* master function for our analysis, and will be written
%to maximize the flexibility of the possible analysis.
%
% USAGE analyseGutTimeSeries(analysisType, scanParam, param)
% 
% NOTE: 
% 1. The inputs to this function can either all be structures giving the
% analysis features for a single fish, or a cell array containing the
% analysis features for a set of fish. The input must be one of these and
% cannot be a combination of them.
% 2. Quality control checks will be done on the input parameters to ensure
% that the entire analysis pipeline will run sucessfully. If it doesn't the
% function will not run.
%
% INPUT analysisType: Contains the series of analysis steps to take on this
%                     data set.
%       scanParam: Parameters giving details about which scans to run, etc.
%       param: All the parameters relevant to the fish for which we've
%       collected data.
% AUTHOR Matthew Jemielita

function [] = analyzeGutTimeSeries(analysisTypeAll, scanParamAll, paramAll)

%% Check inputs

checkStruct = [isstruct(analysisTypeAll), isstruct(scanParamAll), isstruct(paramAll)];
checkStruct = sum(checkStruct)==3;

checkCell = [iscell(analysisTypeAll), iscell(scanParamAll), iscell(paramAll)];
checkCell = sum(checkCell)==3;

if(~xor(checkCell, checkStruct))
   fprintf(2, 'Inputs must either all be structures or all cell arrays!\n');
   return
end

%If input is a single structure, convert to a cell array of size 1
if(checkStruct==1)
   temp =  analysisTypeAll;
   analysisTypeAll  = cell(1,1);
   analysisTypeAll{1} = temp;
   
   temp =  scanParamAll;
   scanParamAll  = cell(1,1);
   scanParamAll{1} = temp;
   
   temp =  paramAll;
   paramAll  = cell(1,1);
   paramAll{1} = temp;
   
end



%% Check inputs and pipeline to make sure it will all run properly
error = checkInputs(analysisTypeAll, scanParamAll, paramAll);

if(error==1)
    fprintf(2, 'Analyze gut time series not properly initialized!');
    return
end

%% Run analysis on each of the data sets
totNumFish = length(paramAll);
for nF=1:totNumFish
    param = paramAll{nF};
    scanParam = scanParamAll{nF};
    analysisType = analysisTypeAll{nF};
    
    analyzeGutTimeSeriesSingleFish(analysisType, scanParam, param);
    
    %mlj: need to write.
   %postProcessTimeSeries(analysisType, scanParam, param,'')
   
    %Garbage collect
    clearvars -except paramAll scanParamAll analysisTypeAll;
        
end


%mlj: Need to write. Collecting together results from all of our different
%experiments.
%postProcessAllData(analysisTypeAll, scanParamAll, paramAll);

end


function error = analyzeGutTimeSeriesSingleFish(analysisType, scanParam, param)
%% Load in scan parameters
%Should be a subfolder of param.dataSaveDirectory. We don't want to
%directly write to this folder since we may run multiple analyses of the
%same data set
saveDir = param.dataSaveDirectory;

%Integer list of which scans to analyze- don't want to just do a range in
%case we want to do only a subset of scans.
scanParam = getFinishedScanList(scanParam);

%% Declaring variables

%We'll keep these from scan to scan, so that we can reuse the previous mask
%if it's the same.
centerLine = cell(3,1);
gutMask = cell(3,1);

%% Construct all the masks at once
%Get points on the center lines that are spaced at the distance given by
%scanParam.stepSize

param = resampleCenterLine(param, scanParam);


%% See if we've update the entry giving gut regions index. If not, calculate this and update the saved file
if(~isfield(param, 'gutRegionsInd'))
    param.gutRegionsInd = findGutRegionMaskNumber(param, true);
end


%createAllMasks(scanParam, param);
%% Save meta-data
%Including analysis parameters and the current version of the code

error = checkCodeVersion(scanParam.codeDir, param.dataSaveDirectory);
if(error==1)
    %fprintf(2, 'Analysis will not continue until code is comitted!\n');
    %return;
end

error = saveAnalysisSteps(analysisType, scanParam, param);
if(error ==1)
    fprintf(2, 'Problem saving meta-data from analysis!');
    return
end
%% Start the analysis of individual scans

for thisScan=1:length(scanParam.scanList)
    tic;
    centerLine = cell(3,1);
    gutMask = cell(3,1);
    %Set this particular scan number-only thing that changes from one scan to
    %the next-I don't see any reason why we should change what we analyze
    %from one scan to the next
    scanParam.scanNum = scanParam.scanList(thisScan);
    
    fprintf(1, '\n');
    fprintf(1, ['Analyzing scan: ', num2str(scanParam.scanNum)]);
    
    [param, centerLine,gutMask] = getScanMasks(scanParam,...
        param,centerLine, gutMask,thisScan);
    
    param.cutValAll{scanParam.scanNum} = param.cutVal;
    
    regFeatures = analyzeGut(analysisType,scanParam,param,centerLine,gutMask);
    
    error = saveAnalysis(regFeatures, scanParam,param,analysisType);
    
    updateFinishedScanList(scanParam, error);
    
    %Convert the image stack if desired
    % error = convertImageFormat(scanParam, param);
    clear regFeatures centerLine gutMask
    toc
end

end
function error = saveAnalysisSteps(analysisType, scanParam, param)
try
    save([param.dataSaveDirectory filesep 'analysisParam.mat'],...
        'analysisType', 'scanParam', 'param');
    error = 0;
catch
    error = 1;
    
end

end

function error = checkInputs(analysisType, scanParam, param)
%write!

error = 0;
end

function scanParam = setScanParameters(sN, param, analysisType)
scanParam.scanNum = sN;
scan
end

function error = saveAnalysis(regFeatures, scanParam,param,analysisType)
   param.dataSaveDirectorySubFolder = 'sumIntensityThresh';
   if(~isdir([param.dataSaveDirectory filesep  param.dataSaveDirectorySubFolder]))
      mkdir([param.dataSaveDirectory filesep param.dataSaveDirectorySubFolder]); 
   end
   
if(isfield(param, 'dataSaveDirectorySubFolder'))
   analysisSaveDir = [param.dataSaveDirectory filesep 'singleCountRaw'];
else
    analysisSaveDir = param.dataSaveDirectory;
end
analysisSaveDir = [param.dataSaveDirectory filesep 'singleCountRaw'];

analysisSaveDir = [param.dataSaveDirectory filesep param.dataSaveDirectorySubFolder];
fileName = [analysisSaveDir, filesep, 'Analysis_Scan', ...
        num2str(scanParam.scanNum), '.mat'];
     save(fileName, 'regFeatures', '-v7.3');
    error = 0;

end

function param = resampleCenterLine(param, scanParam)

for nS=1:length(param.centerLineAll)
    clear polyT
    clear polyFit
    poly = param.centerLineAll{nS};
    
    %Resample the center line at the desired spacing
    stepSize = scanParam.stepSize/0.1625;
    
    %Parameterizing curve in terms of arc length
    t = cumsum(sqrt([0,diff(poly(:,1)')].^2 + [0,diff(poly(:,2)')].^2));
    %Find x and y positions as a function of arc length
    polyFit(:,1) = spline(t, poly(:,1), t);
    polyFit(:,2) = spline(t, poly(:,2), t);
    
    polyT(:,2) = interp1(t, polyFit(:,2),min(t):stepSize:max(t),'spline', 'extrap');
    polyT(:,1) = interp1(t, polyFit(:,1),min(t):stepSize:max(t), 'spline', 'extrap');
    
    %Redefining poly
    poly = cat(2, polyT(:,1), polyT(:,2));
    
    param.centerLineAll{nS} = poly;
end

end

function [param, centerLine, gutMask] = getScanMasks(...
    scanParam, param,centerLine, gutMask,thisScan)

%param.cutVal = calcOptimalCut(scanParam.regOverlap,param,scanParam.scanNum);
cutVal = load([param.dataSaveDirectory filesep 'masks' filesep 'cutVal.mat'],'cutValAll');
cutVal = cutVal.cutValAll;
param.cutVal = cutVal{scanParam.scanNum};

switch isdir([param.dataSaveDirectory filesep 'masks']);
    case false
        %If we didn't calculate all the masks at the beginning calculate
        %this particular mask
        if(thisScan~=1)
            lastScan = scanParam.scanList(thisScan-1);
            scanNum = scanParam.scanNum;
            sameLine = isequal(param.centerLineAll{lastScan}(:),param.centerLineAll{scanNum}(:));
            sameOutline = isequal(...
                param.regionExtent.polyAll{lastScan}(:),param.regionExtent.polyAll{scanNum}(:));
            if(sameLine==true && sameOutline==true)
                %If true, then the previously calculated gut mask is equal to this one
                %and we don't have to recalculate it
                return
            end
        end
        
        %If the mask is different, then recalculate the mask
        numCuts = size(param.cutVal,1);
        for cN =1:numCuts
            [centerLine{cN}, gutMask{cN}] =...
                constructRotRegion(cN, scanParam.scanNum, '', param, true);
        end
        
    case true 
        %Load in the appropriate mask
        thisMask = load([param.dataSaveDirectory filesep 'masks' filesep...
            'mask_', num2str(scanParam.scanNum), '.mat']);
        centerLine = thisMask.centerLine;
        gutMask = thisMask.gutMask;
end

end

function updateFinishedScanList(scanParam, error)
fileName = [scanParam.dataSaveDirectory, filesep, 'scanlist_LOCK.mat'];
scanList = load(fileName);
scanList = scanList.scanList;

%Remove the completed scan from the list
scanList = setdiff(scanList, scanParam.scanNum);
save(fileName, 'scanList');


end

function scanParam = getFinishedScanList(scanParam)

%See if we're going to be wiping out the locked scanlist

fileName = [scanParam.dataSaveDirectory, filesep, 'scanlist_LOCK.mat'];
if(isfield(scanParam, 'freshStart') && scanParam.freshStart==true)
    fprintf(1, 'unsuccessful!\n Saving current scan list.');
    
    scanList = scanParam.scanList;
    save(fileName, 'scanList');
else
    
    if(exist(fileName)==2)

        scanList = load(fileName, 'scanList');
        scanList = scanList.scanList;
        scanParam.scanList = scanList;
    end
end
    



try
    fprintf(1, 'Trying to load in list of previously analyzed scan...');
    scanList = load(fileName, 'scanList');
    scanList = scanList.scanList;
    scanParam.scanList = scanList;
catch
    fprintf(1, 'unsuccessful!\n Saving current scan list.');
    
    scanList = scanParam.scanList;
    save(fileName, 'scanList');


end
fprintf(1, '\n');

end

function error = convertImageFormat(scanParam, param)
error = 0;
if(isfield(scanParam, 'convertToPNG') && scanParam.convertToPNG==true)
    currentDir = pwd;
    cd(param.directoryName);
    
    searchStr = ['**', filesep, '*.tif'];
    fileName = rdir(searchStr);
    
    fprintf(1, 'Converting images in this scan to pngs: ');
    for i=1:length(fileName)
        inFileName = fileName(1).name;
        
        im = imread(fileName(1).name);
        outFileName = [inFileName(1:end-3), 'png'];
        
        imwrite(im, outFileName);
        delete(inFileName);
        fprintf(1, '.');
    end
    fprintf(1, '\n');
    
end
    
end
