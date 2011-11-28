%Calculates the outline of the gut for an arbitrary number of different 
function [] = outlineSeveralGuts(varargin)

%Load in the desired variables
switch nargin
    case 0
        %Read in the directories that contain the stacks that we're going to
        %analyze      
        %Probably want to clean up this program a bit.
        scanLoc = uigetfile_n_dir;
    case 1
        scanLoc = varargin{1};
end

%Check to make sure that each of these directories has the valid structure
%for storing scan data from our microscope.

%Going through each directory

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
    
    %If this scan directory has already been analyzed, load in that
    %information, from the appropriate file
    param.dataSaveDirectory = [param.directoryName, filesep, 'gutOutline'];
    mkdir(param.dataSaveDirectory);
    cd(param.dataSaveDirectory);
    
    paramFile = [param.directoryName, filesep, 'gutOutline', filesep, 'param.mat'];
    dataFile = [param.directoryName, filesep, 'gutOutline', filesep, 'data.mat'];
    paramFileExist = exist(paramFile, 'file');
    switch paramFileExist
        case 2
            disp('Parameters for this scan have already been (partially?) calculated. Loading them into the workspace.');
            
            paramTemp = load(paramFile);
            dataTemp = load(dataFile);
            
            param = paramTemp.param;
            data = dataTemp.data;
  
        case 0
        
        %Load in information about this scan...this information should be
        %passed in, or stored in one place on the computer.
        param.micronPerPixel = 0.1625; %For the 40X objective.
        param.imSize = [2160 2560];
        
        expData = load(parameterFile);
        param.expData = expData.parameters;
        
        %Load in the number of scans. Default will be for all of the
        %scans...might want to make this an interactive thing at some point.
        param.scans = 1:param.expData.totalNumberScans;
        %Number of regions in be analyzed. Hardcoded to be all of them
        param.regions = 'all';
        %Colors to be analyzed. Need to provide a more machine readable way and
        %elegant way to load this into the code.
        param.color = [{'488nm'}, {'568nm'}];
        %param.color = [{'568nm'}];
        %For the parameters above construct a structure that will contain all the
        %results of this calculation.
        
        [data,param] = initializeScanStruct(param);
        
        disp('Paremeters succesfully loaded.');
        
        % Calculate the overlap between different regions
        
        fprintf(2,'Calculating information needed to register the images...');
        [data,param] = registerImagesXYData('original', data,param);
        
        [data,param] = registerImagesZData('original', data,param);
        
        %Store the result in a backup structure, since .regionExtent will be
        %modified by cropping.
        param.regionExtentOrig = param.regionExtent;
        fprintf(2, 'done!\n');
    end
    
    %% Open an interactive GUI to crop the images to the desired size
    [param,data] = multipleRegionCrop(param,data);
    
    %% Saving the parameters created.
    %Location that the results of the data will be saved to
    param.dataSaveDirectory = [param.directoryName, filesep, 'gutOutline'];
    mkdir(param.dataSaveDirectory);
    cd(param.dataSaveDirectory);
    %Save all the parameters used in making these distributions
    save('param.mat', 'param');
    %And all of the data
    save('data.mat', 'data');
    
end
disp('All selected scans have been analyzed.');







end