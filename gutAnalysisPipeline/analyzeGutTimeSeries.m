%analyzeGutTimeSeries: Analyze a time series of gut images for a single
%fish. This is *the* master function for our analysis, and will be written
%to maximize the flexibility of the possible analysis

function [] = analyzeGutTimeSeries(analysisType, scanParam, param)
%% If scanParam is empty, then populate it with values that span the range of scans taken

if(isempty(scanParam))
   scanParam = populateScanParam(param); 
end

%% Check inputs and pipeline to make sure it will all run properly


error = checkInputs(analysisType, scanParam, param);

if(error==1)
    fprintf(2, 'Analyze gut time series not properly initialized!');
    return
end

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

createAllMasks(scanParam, param);
%% Save meta-data
%Including analysis parameters and the current version of the code

error = checkCodeVersion(scanParam.codeDir, param.dataSaveDirectory);
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
    
    error = saveAnalysis(regFeatures, scanParam,analysisType);
    
    updateFinishedScanList(scanParam, error);
    
    %Convert the image stack if desired
    % error = convertImageFormat(scanParam, param);
    clearvars -except param scanParam analysisType;
    clear regFeatures centerLine gutMask
    toc
end

%% Analysis/graphing of the entire data set



clear all
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

function  scanParam = populateScanParam(param)

scanParam.color = param.color;
scanParam.scanList = 1:param.expData.totalNumberScans;

%Just in case it wasn't reset somewhere
scanParam.dataSaveDirectory = param.dataSaveDirectory;

%Standard values
scanParam.stepSize = 5;
scanParam.regOverlap = 10;

%This might change a little bit based on which computer we're running
%things on
scanParam.codeDir = 'C:\code\trunk';

end


function error = checkInputs(analysisType, scanParam, param)
%write!

error = 0;
end

function scanParam = setScanParameters(sN, param, analysisType)
scanParam.scanNum = sN;
scan
end

function error = saveAnalysis(regFeatures, scanParam,analysisType)

    fileName = [scanParam.dataSaveDirectory, filesep, 'Analysis_Scan', ...
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

fileName = [scanParam.dataSaveDirectory, filesep, 'scanlist_LOCK.mat'];

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
