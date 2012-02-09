%analyzeManyFluoro: Script that analyzes the fluorescence of a series of
%different guts. Uses the program analyzeFluoro.m to analyze the
%fluoroescence for each individual gut. See the help menu for that code for
%the particulars of how the scans are analyzed.
%
%USAGE: analyzeManyFluoro(scanLoc): for each scan location analyze the
%       fluorescent signal over all scans and colors. When calling the function in
%       this manner only the total intensity is calculated.
%       analyzeManyFluoro(scanLoc, type): same as before, but now doing a
%       particular type of projection. Currently supported: ('mip', 'total
%       intensity', 'total number', 'all');
%   
%INPUT: scanLoc: cell array of strings giving the location of each set of
%scans.
%       type: string giving the type of projection to do.

function []= analyzeManyFluoro(varargin)

%Reading in the variables
if nargin==1
   scanLoc = varargin{1}; 
   projectionType = 'total intensity';
end

if nargin==2
   scanLoc = varargin{1};
   projectionType = varargin{2};
end


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
        disp(strcat('The directory ', param.directoryName, ' is not in the valid format!'));
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
    
    %Manually set the threshold for pixels counted by the projection type
    %'totalNumber' to be that of the bacterial intensity outside the gut.
    %Should also be able to pull this from param.
    param.thresh(1) = 436.68;
    param.thresh(2) = 299.51;  
    
    %% Analyzing the fluorescence signal for that image stack
    disp([ 'Analyzing fluorescence in: ', param.directoryName]);
    [data,param] = analyzeFluoro(data,param, projectionType);
    
    
end
disp('All selected scans have been analyzed.');

end
