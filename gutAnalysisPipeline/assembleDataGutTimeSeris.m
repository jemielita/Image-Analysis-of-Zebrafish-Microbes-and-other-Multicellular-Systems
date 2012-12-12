%assembleDataGutTimeSeries: Collect together all the data necessary to plot
%bacteria population sizes over time.
%
%USAGE: [popTot, popXpos] = assembleDataGutTimeSeris(param, sMin, sMax,
%bacInten, bkgInten)
%
%AUTHOR: Matthew Jemielita, Dec. 6, 2012
%
function [popTot, popXpos] = assembleDataGutTimeSeries(param, sMin, sMax,...
bacInten, bkgInten, bkgOffset)

%% Getting parameters and preallocating arrays
NtimePoints = sMax-sMin+1;

boxWidth = 
formatstr = '%d';
matfilebase = 'Analysis_Scan'; ext = '.mat';

%Preallocating arrays
maxgreen = zeros(1,NtimePoints);  % max intensity at each time point
maxred = zeros(1,NtimePoints);
totalgreen = zeros(1,NtimePoints);  % total intensity at each time point
totalred = zeros(1,NtimePoints);

%%Loading in data
for j=1:NtimePoints
    % Load data
    matfile = strcat(matfilebase, sprintf(formatstr,j+min_scan-1), ext);
    load(matfile)

    %Length of gut for this time point
    gutLength = size(regFeatures{1,1},1);
    %Position down the length of the gut
    xpos = boxWidth*((1:gutLength)' - 0.5); % position along gut, microns (column vector)

    

end