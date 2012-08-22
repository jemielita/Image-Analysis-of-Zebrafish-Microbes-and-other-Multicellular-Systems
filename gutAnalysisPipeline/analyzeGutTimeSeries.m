%analyzeGutTimeSeries: Analyze a time series of gut images for a single
%fish. This is *the* master function for our analysis, and will be written
%to maximize the flexibility of the possible analysis

function [] = analyzeGutTimeSeries(analysisType, scanParam, param)
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
saveDir = scanParam.dataSaveDirectory; 

%Integer list of which scans to analyze- don't want to just do a range in
%case we want to do only a subset of scans.

scanParam = getFinishedScanList(scanParam);

%% Save meta-data
%Including analysis parameters and the current version of the code

error = checkCodeVersion(scanParam.codeDir, scanParam.dataSaveDirectory);
error = saveAnalysisSteps(analysisType, scanParam, param);
if(error ==1)
    fprintf(2, 'Problem saving meta-data from analysis!');
    return
end
%% Start the analysis of individual scans

for thisScan=1:length(scanParam.scanList)
  %Set this particular scan number-only thing that changes from one scan to
  %the next-I don't see any reason why we should change what we analyze
  %from one scan to the enxt
  scanParam.scanNum = scanParam.scanList(thisScan);
  
  %Different optimal cut for each time point, because we have a different
  %gut outline.
  param.cutVal = calcOptimalCut(10,param,scanParam.scanNum);
  
  regFeatures = analyzeGut(analysisType, scanParam, param);
  
  error = saveAnalysis(regFeatures, scanParam);
  
  updateFinishedScanList(scanParam, error);
  
  
    
end

%% Analysis/graphing of the entire data set



end


function error = saveAnalysisSteps(analysisType, scanParam, param)
try
    save([scanParam.dataSaveDirectory filesep 'analysisParam.mat'],...
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

function error = saveAnalysis(regFeatures, scanParam)
try
    fileName = [scanParam.dataSaveDirectory, filesep, 'Analysis_Scan', ...
        num2str(scanParam.scanNum), '.mat'];
    save(fileName, 'regFeatures', '-v7.3');
    error = 0;
catch
    fprintf(2, ['Error in saving Scan: ', num2str(scanParam.scanNum)]);
    error = 1;
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
