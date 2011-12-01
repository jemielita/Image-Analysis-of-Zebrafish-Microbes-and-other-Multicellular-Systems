%Script to analyze the fluoresence for a number of different guts...code
%should be made more general to analyze fluorescence over time for a
%handful of scans, colors, and fish.

function []= analyzeManyFluoro(scanLoc)

for numDir =1:length(scanLoc)
    %% Clear any old clutter from previous iterations of this code
    clear param
    clear data
    
    disp(strcat('Analyzing images stored in the directory: ', scanLoc{numDir} ,'.'));
    %% Load in the appropriate experimental parameters
    try
        param.directoryName = scanLoc{numDir};
    catch 
        disp(strcat('The directory ', param.directoryName, ' is not in the valid format!'));
    end
    
    parameterFile = strcat(param.directoryName, filesep, 'ExperimentData.mat');
    testDir = [isdir(param.directoryName), exist(parameterFile, 'file')];
    %Skip this iteration of the analysis if there was a problem with the
    %chosen directory.
    if(sum(ismember(testDir, 0)) > 0)
        disp(strcat('The directory ', param.directoryName, ' is not in the valid format!'))
        continue
    end
    
    %Load in information about the outline of the gut, and the cropping
    %region.
    paramFile = [param.directoryName, filesep, 'gutOutline', filesep, 'param.mat'];
    dataFile = [param.directoryName, filesep, 'gutOutline', filesep, 'data.mat'];
    paramFileExist = exist(paramFile, 'file');
            
    paramTemp = load(paramFile);
    dataTemp = load(dataFile);
    
    param = paramTemp.param;
    data = dataTemp.data;
    
    
    %Place holder for now-need to get this information from Mike.
    param.thresh(1) = 436.68;
    param.thresh(2) = 299.51;
    
    
    
 %% Analyzing the fluorescence signal for that image stack
 disp([ 'Analyzing fluorescene in: ', param.directoryName]);
 [data,param] = analyzeFluoro(data,param, 'all');
 
 %% Saving the fluorescence data
    %Location that the results of the data will be saved to
    param.dataSaveDirectory = [param.directoryName, filesep, 'gutOutline'];
    mkdir(param.dataSaveDirectory);
    cd(param.dataSaveDirectory);
     %And all of the data produced by this scan
    save('data.mat', 'data');
    
end
disp('All selected scans have been analyzed.');





end
