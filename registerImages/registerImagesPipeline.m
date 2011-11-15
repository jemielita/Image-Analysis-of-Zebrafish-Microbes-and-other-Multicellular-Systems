%This script calculates the line distribution for a given subset of scans
%taken for an experiment. This can be used as the first step towards
%calculating a correlation function for the data.


%We should really exploit our saved experimental variables to make this
%code much cleaner.

%%Camera and experimental parameters
param.micronPerPixel = 0.125; %For the 40X objective.

%% Listing the scans to be taken

%Give the master directory for all the scans
param.directoryName = 'F:\Nov_9_Aeromonas\Flask_A_wtGFP_DeltaPgmDTomato\Fish_1';
%Give the range of scans to be analyzed. If the variable scans is set to
%'all' then all the scans in this folder will be analyzed. If not scans
%should be an array listing the scans to analyze. 
%   e.g. scans = 1:10, will analyze all scans from 1 to 10.
%        scans = [1 6 8] will analyze scans 1, 6, and 8.
%        scans = 'all' will analze all the scans in this directory
param.scans = [1];

%Call for regions will be the same as for scans
param.regions = 'all';

%Call for color needs to be somewhat different, to deal with our file save
%methods...will get once we can get back on the main computer.

param.color = 'all';

%Give the range of images in each of the scans to use for calculating the
%projections.
param.minImage = 20; 
param.maxImage = 23;
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
[data,param] = registerImagesXYData(data,param);

[data,param] = registerImagesZData(data,param);


%% Going through the images, and overlapping the images as needed.
param.registerRegion = 'all';

[data,param] = registerImages(data,param);


%% Calculating the line distributions for all of the scans
[data,param] = lineDistAll(data,param);

%% Creating and saving graphics from this data

%This is a temporary directory location;

tempFile = '/Users/matthewjemielita/Documents/MATLAB';
%Location that the results of the data will be saved to 
param.dataSaveDirectory = [tempFile, filesep, 'lineDist'];
mkdir(param.dataSaveDirectory);
cd(param.dataSaveDirectory);
%Save all the parameters used in making these distributions
save('param.mat', 'param');
%And all of the data
save('data.mat', 'data');

%Now creating several figures that illustrate the data.

[data,param] = saveLineDist(data,param);


%Create figures that show the distribution for each of these data sets.


%% Calculating correlation functions for this data





