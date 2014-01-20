%analyzeGutGetParameters: Get parameters that will be used to analyze time
%series data. When function is run the user will be prompted for a list of
%directories to load the parameters from. Make sure to only select folders
%that have the 'fish#" syntax! The user will then be prompted for the types
%of analysis to be done. Currently the program will populate the scanParam
%variable with the maximum number of scans and colors in the data set.
%
% USAGE [pAll, sAll, analysisAll] = analyzeGutGetParameters()
%       pAll = analyzeGutGetParameters()
% OUTPUT: pAll: cell array containing all parameter files to be analyzd.
%         sAll: (optional) cell array containing all scanParam variables.
%         analysisAll: (optional) cell array containing analysis type.
%        
%AUTHOR: Matthew Jemielita, Oct 29, 2013

function [pAll,varargout] = analyzeGutGetParameters()

dirNames = uipickfiles();

%% Unpack param files.

%If only one entry in dirNames then look for subfolders containing param files
if(length(dirNames)==1)
    cd(dirNames{1});
    subDir= rdir('**\param.mat');
    
    dirNamesTemp = [];
    for i=1:length(subDir)
        dirNamesTemp{i} = subDir(i).name;
    end
    dirNames = dirNamesTemp;
else
   %Get the location of the param file for each of these entries
   for i=1:length(dirNames)
      dirNames{i} = [dirNames{i} filesep 'gutOutline' filesep 'param.mat']; 
   end
end


pAll = cell(length(dirNames),1);
for nF=1:length(dirNames)
    inputVar = load(dirNames{nF});
    pAll{nF} = inputVar.param;
end

if(nargout==1)
   %Return if we only want these param files
   return 
end


%% Get code repository location
codeDir = uigetdir('C:\code', 'Select location of code to be used in analysis');



%% Load in analysis type

analysisList = {'backgroundHistogram', 'linearIntensityBkgSub', 'spotDetection'};
promptString = 'Selection types of analysis to run';
selectionMode = 'multiple';
initValue = [1 2 3];

[s, v] = listdlg('PromptString', promptString, 'SelectionMode', selectionMode, ...
    'InitialValue', initValue, 'ListString', analysisList);

if(v==0)
    fprintf(2, 'No analysis selected! Must select at least one!\n');
    return
end


%Go through each of the analysis steps and make sure the values for the
%parameters are all right

for aNum=1:length(s)
    analysisType(aNum) = checkAnalysis(analysisList, aNum);
end



for nF =1:length(dirNames)
   %Check the inputs for all of the scan parameters
   scanList = ['1:' num2str(pAll{nF}.expData.totalNumberScans)];
   stepSize = '5';
   regOverlap = '10';
   
   %mlj: Need to work on output of color list being readable.
   %Convoluted way to turn cell array into a sr
   numColor = length(pAll{nF}.color);
   colorList = ['{'];
   for nC=1:numColor;
       colorList = [colorList pAll{nF}.color{nC}];
       if(nC~=numColor)
       colorList = [colorList ','];
       end
   end
   colorList = [colorList '}'];
       
   colorList = pAll{nF}.color;
   dataSaveDirectory = pAll{nF}.dataSaveDirectory;
   freshStart = 'true';
   
   prompt = {'Scan list', 'Mask step size (microns)', 'Region overlap (microns',...
   'Color list', 'Save directory', 'Restart all analysis'};
   numlines = 1;
   name = ['Scan parameters for fish ', num2str(nF)];
   defaultanswer = {scanList, stepSize, regOverlap, colorList, dataSaveDirectory, freshStart};
   answer = inputdlg(prompt, name, numlines, defaultanswer);
   
   sAll{nF}.scanList = str2num(answer{1});
   sAll{nF}.stepsize = str2num(answer{2});
   sAll{nF}.regOverlap = str2num(answer{3});
   sAll{nF}.colorList = answer{4};
   sAll{nF}.dataSaveDirectory = answer{5};
   sAll{nF}.freshStart = str2num(answer{6});

%    
%    sAll{nF}.scanList = 1:pAll{nF}.expData.totalNumberScans;
%    sAll{nF}.codeDir = codeDir;
%     
%    Default step sizes etc-haven't been changed in eons.
%    sAll{nF}.stepSize = 5;
%    sAll{nF}.regOverlap = 10;
%    sAll{nF}.color = pAll{nF}.color;
%    sAll{nF}.dataSaveDirectory = pAll{nF}.dataSaveDirectory;
%    analysisAll{nF} = analysisType;
%    sAll{nF}.freshStart = true;
   
   
   
   
end


varargout{1} = sAll;
varargout{2} = analysisAll;


end

function analysisType = checkAnalysis(analysisList, aNum)

thisAnalysis = analysisList(aNum);


switch thisAnalysis
    
    case 'backGroundHistogram'
        %1. Calculate a histogram of pixel values near background
        analysisType.name = 'backgroundHistogram';
        analysisType.return = 'true';
        analysisType.binSize = '1:2:2000';
        
        prompt = {'Name', 'return value', 'bin size'};
        name = getfield(analysisType, 'name');
        numlines = 1;
        defaultanswer = cellfun(@(x)getfield(analysisType, x), fieldnames(analysisType), 'UniformOutput', false);
        answer = inputdlg(prompt, name, numlines, defaultanswer);
        
        analysisType.return = str2num(answer{2});
        analysisType.binSize = str2num(answer{3});
        
    case 'linearIntensityBkgSub'
        %Calculate the linear intensity down the length of the gut after
        %subtracting the background intensity at those regions
        analysisType.name = 'linearIntensityBkgSub';
        analysisType.return = 'true';
        analysisType.bkgList = '1:25:2000'; %Need to get a sense of what size

        name = getfield(analysisType, 'name');
        defaultanswer = cellfun(@(x)getfield(analysisType, x), fieldnames(analysisType), 'UniformOutput', false);
        numlines = 1;
        answer = inputdlg(prompt, name, numlines, defaultanswer);

        analysisType.return = str2num(answer{2});
        analysisType.bkgList = str2num(answer{3});
        
    case 'spotDetection'
        analysisType.name = 'spotDetection';
        analysisType.return = 'true';
        intenThresh = '[30 30]';
        analysisType.spotFeatures.intenThresh = intenThresh; %Use default
        
        name = getfield(analysisType, 'name');
        numlines = 1;
        prompt = {'Name', 'return value', 'intensity threshold'};
        defaultanswer = {analysisType.name, analysisType.return,intenThresh};
        answer = inputdlg(prompt, name, numlines, defaultanswer);

        analysisType.return = str2num(answer{2});
        analysisType.spotFeatures.intenThresh = str2num(answer{3});
        
        
end



end

