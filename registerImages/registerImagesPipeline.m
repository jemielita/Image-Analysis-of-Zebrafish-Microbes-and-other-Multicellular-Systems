%This script calculates the line distribution for a given subset of scans
%taken for an experiment. This can be used as the first step towards
%calculating a correlation function for the data.


%We should really exploit our saved experimental variables to make this
%code much cleaner.

%% The directory we'll work out of
%Give the master directory for all the scans
param.directoryName = 'F:\Nov_9_Aeromonas\Flask_A_wtGFP_DeltaPgmDTomato\Fish_2';
%param.directoryName = '/Volumes/big-2/guts/Data/Nov_9_Aeromonas/Flask_A_wtGFP_DeltaPgmDTomato/Fish_2';
%% Initialize parameters and code path
%On my own (mlj) machine
%addpath(genpath('~/Documents/code/'))

%On lsm control computer
addpath(genpath('C:\code'));
%addpath(genpath('~/Documents/code'));
param.micronPerPixel = 0.1625; %For the 40X objective.
param.imSize = [2160 2560];
%% Listing the scans to be taken

%Give the range of scans to be analyzed. If the variable scans is set to
%'all' then all the scans in this folder will be analyzed. If not scans
%should be an array listing the scans to analyze. 
%   e.g. scans = 1:10, will analyze all scans from 1 to 10.
%        scans = [1 6 8] will analyze scans 1, 6, and 8.
%        scans = 'all' will analze all the scans in this directory
param.scans = [3:4];

%Call for regions will be the same as for scans
param.regions = 'all';

%Call for color needs to be somewhat different, to deal with our file save
%methods...will get once we can get back on the main computer.

param.color = [{'488nm'}; {'568nm'}];

%Place holder for now-need to get this information from Mike.
param.thresh(1) = 1000;
param.thresh(2) = 600;
%For the parameters above construct a structure that will contain all the
%results of this calculation.

%As a test we'll do this for just the data contained in our test scan, and
%soon we'll adapt it to a mor general file structure.

[data,param] = initializeScanStruct(param);

%Load in the experimental data
expDataLoc = strcat(param.directoryName,filesep,'ExperimentData.mat');
param.expData = load(expDataLoc);
param.expData = param.expData.parameters;%Only pull out the parameters, not the time data.


%% Calculate the overlap between different regions
[data,param] = registerImagesXYData('original', data,param);

[data,param] = registerImagesZData('original', data,param);

%Store the result in a backup structure, since .regionExtent will be
%modified by cropping.
param.regionExtentOrig = param.regionExtent;

%% Going through the images, and overlapping the images as needed.
param.registerRegion = 'all';
registerImagesScan(data,param);

%% Open an interactive GUI to crop the images to the desired size
global param; %Clumsy, but it's the easiest way to pass information to and from a GUI in matlab
multipleRegionCrop(param,data);
pause

%% Crop the images
%Done autoamaticaly by the multipleRegionCrop function
[data,param] = registerImagesZData('crop', data,param);

%% Calculate features of the gut fluorescence 
%A first pass at analyzing data about the gut.

[data, param] = analyzeFluoro(data,param, 'all');

%% Saving the parameters created.
%Location that the results of the data will be saved to 
param.dataSaveDirectory = [param.directoryName, filesep, 'gutOutline'];
mkdir(param.dataSaveDirectory);
cd(param.dataSaveDirectory);
%Save all the parameters used in making these distributions
save('param.mat', 'param');
%And all of the data
save('data.mat', 'data');

%% Load data
%Load in information that has already been calculated.
param.dataSaveDirectory = [param.directoryName, filesep, 'gutOutline'];
cd(param.dataSaveDirectory);
load('param.mat', 'param');
load('data.mat', 'data');

