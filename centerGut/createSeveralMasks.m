%For a given set of fish, find the center of the gut and create mask,
%corresponding to different regions down the length of the gut.

function [] = createSeveralMasks(scanLoc, stepSize)

for numDir = 1:length(scanLoc)
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
    %Load in information about this scan.
    param.dataSaveDirectory = [param.directoryName, filesep, 'gutOutline'];
    mkdir(param.dataSaveDirectory);
    cd(param.dataSaveDirectory);
    
    paramFile = [param.directoryName, filesep, 'gutOutline', filesep, 'param.mat'];
    dataFile = [param.directoryName, filesep, 'gutOutline', filesep, 'data.mat'];
    
    disp('Loading the parameters for this directory into the workspace...');
    
    paramTemp = load(paramFile);
    dataTemp = load(dataFile);
    
    param = paramTemp.param;
    data = dataTemp.data;
    
    
    %% Find the center of this gut and the masks running down the length of
    %%the gut.
    poly = param.regionExtent.poly;
    BW = poly2mask(poly(:,1), poly(:,2), param.regionExtent.regImSize(1),...
        param.regionExtent.regImSize(2));
    mask = curveMask(BW, param.centerLine, param,'rectangle');
    param.mask = mask;
  
    
    %% Saving the parameters created.
    %Location that the results of the data will be saved to
    param.dataSaveDirectory = [param.directoryName, filesep, 'gutOutline'];
    mkdir(param.dataSaveDirectory);
    cd(param.dataSaveDirectory);
    %Save all the parameters used in making these distributions
    save('param.mat', 'param', '-v7.3');
    %And all of the data
    save('data.mat', 'data');
    
    save('regMask.mat', 'mask');
    
end



end