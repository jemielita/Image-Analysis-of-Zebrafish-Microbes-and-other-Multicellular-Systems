%analyzeGutGetParameters: Get parameters that will be used to analyze time
%series data. When function is run the user will be prompted for a list of
%directories to load the parameters from. Make sure to only select folders
%that have the 'fish#" syntax! The user will then be prompted for the types
%of analysis to be done. Currently the program will populate the scanParam
%variable with the maximum number of scans and colors in the data set.
%
% USAGE [pAll, sAll, analysisAll] = analyzeGutGetParameters()
%
% OUTPUT: pAll: cell array containing all parameter files to be analyzd.
%         sAll: cell array containing all scanParam variables.
%         analysisAll: cell array containing analysis type.
%AUTHOR: Matthew Jemielita, Oct 29, 2013

function [pAll, sAll, analysisAll] = analyzeGutGetParameters()

dirNames = uipickfiles();

codeDir = uigetdir('C:\code', 'Select location of code to be used in analysis');

%If only one entry then, look for subfolders containing param files
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

%For now let's have the analysis type be default

%1. Calculate a histogram of pixel values near background
analysisType(1).name = 'backgroundHistogram';
analysisType(1).return = true;
analysisType(1).binSize = 1:2:2000; 


%Calculate the linear intensity down the length of the gut after
%subtracting the background intensity at those regions
analysisType(2).name = 'linearIntensityBkgSub';
analysisType(2).return = true;
analysisType(2).bkgList = 1:25:2000; %Need to get a sense of what size 

analysisType(3).name = 'spotDetection';
analysisType(3).return = true;
analysisType(3).spotFeatures.intenThresh = [30, 30]; %Use default



for nF =1:length(dirNames)
   inputVar = load(dirNames{nF});
   pAll{nF} = inputVar.param;
   
   sAll{nF}.scanList = 1:pAll{nF}.expData.totalNumberScans;
   sAll{nF}.codeDir = codeDir;
    
   %Default step sizes etc-haven't been changed in eons.
   sAll{nF}.stepSize = 5;
   sAll{nF}.regOverlap = 10;
   sAll{nF}.color = pAll{nF}.color;
   sAll{nF}.dataSaveDirectory = pAll{nF}.dataSaveDirectory;
   analysisAll{nF} = analysisType;
   sAll{nF}.freshStart = true;
end




end

