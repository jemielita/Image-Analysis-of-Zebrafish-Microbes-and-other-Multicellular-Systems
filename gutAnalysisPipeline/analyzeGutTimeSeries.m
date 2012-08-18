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
scanList = scanParam.scanList;


%% Save meta-data
%Including analysis parameters and the current version of the code

error = checkCodeVersion(scanParam.codeDir, scanParam.dataSaveDirectory);
error = saveAnalysisSteps(analysisType, scanParam, param);
if(error ==1)
    fprintf(2, 'Problem saving meta-data from analysis!');
    return
end
%% Start the analysis of individual scans

%analysis step
%saving step


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


end