%assembleDataGutTimeSeries: Collect together all the data necessary to plot
%bacteria population sizes over time.
%
%USAGE: [popTot, popXpos] = assembleDataGutTimeSeris(param, sMin, sMax,
%bacInten, bkgInten)
%
%AUTHOR: Matthew Jemielita, Dec. 6, 2012
%
function [popTot, popXpos, bkgDiff] = assembleDataGutTimeSeries(param, sMin, sMax,...
bacInten, bkgInten, bkgOffset)

%% Getting parameters and preallocating arrays
NtimePoints = sMax-sMin+1;

boxWidth = 5; %Should be an input, but it's almost always this.
formatstr = '%d';
matfilebase = 'Analysis_Scan'; ext = '.mat';

timestep = 0.33;

%Preallocating arrays
maxgreen = zeros(1,NtimePoints);  % max intensity at each time point
maxred = zeros(1,NtimePoints);
totalgreen = zeros(1,NtimePoints);  % total intensity at each time point
totalred = zeros(1,NtimePoints);

popXpos = cell(NtimePoints,2);
popTot = zeros(NtimePoints,3);
bkgDiff = cell(NtimePoints,2);
%%Loading in data
for j=1:NtimePoints
    % Load data
    matfile = [param.dataSaveDirectory filesep matfilebase ...
        sprintf(formatstr,j+sMin-1) '.mat'];
    regFeatures =  load(matfile);
    regFeatures = regFeatures.regFeatures;
    
    %Length of gut for this time point
    gutLength = size(regFeatures{1,1},1);
    %Position down the length of the gut
    xpos = boxWidth*((1:gutLength)' - 0.5); % position along gut, microns (column vector)
    
    %The background is the product of the mean background value and the
    %total volume of this box
    meanBkgGreen = 1*bkgInten{1}{j}(1:gutLength)';
    meanBkgRed = bkgOffset*bkgInten{2}{j}(1:gutLength)';
    
    bkgGreen = meanBkgGreen.*regFeatures{1}(1:gutLength,2);
    bkgRed = meanBkgRed.*regFeatures{2}(1:gutLength,2);
    
    thisLine_green = regFeatures{1}(1:gutLength,1)-bkgGreen;
    thisLine_red = regFeatures{2}(1:gutLength,1)-bkgRed;
    
    %Force the total intensity after background subtraction to be positive
    zPad = zeros(gutLength,1);
    thisLine_green = max([thisLine_green, zPad],[],2);
    thisLine_red = max([thisLine_red, zPad],[],2);
    
    %Convert to number of bacteria
    thisLine_green = thisLine_green / bacInten(1);
    thisLine_red = thisLine_red / bacInten(2);
    
    % save in structured array
    xPos = xpos(1:gutLength);
    popXpos{j,1}(1,:) = thisLine_green(1:gutLength);
    popXpos{j,2}(1,:) = thisLine_red(1:gutLength);
    
    %Save position array
    popXpos{j,1}(2,:) = xPos; popXpos{j,2}(2,:) = xPos;
    %Save time information-need to change this up a bit to include
    %information about the delay after the last inoculation-to better
    %overlap different data sets
    popXpos{j,1}(3,:) = j*timestep*ones(size(xPos));
    popXpos{j,2}(3,:) = j*timestep*ones(size(xPos));
    
    %Save the difference between the predicted background mean and the
    %total pixel
    bkgDiff{j,1} = ...
        (regFeatures{1}(1:gutLength,1)./regFeatures{1}(1:gutLength,2))...
        ./ bkgInten{1}{j}(1,1:gutLength)';
    bkgDiff{j,2} = ...
        (regFeatures{2}(1:gutLength,1)./regFeatures{2}(1:gutLength,2))...
        ./ bkgInten{2}{j}(1,1:gutLength)';
    bkgDiff{j,3} = bkgInten{1}{j}(1,1:gutLength)'.*regFeatures{1}(1:gutLength,2);
    bkgDiff{j,4} = regFeatures{2}(1:gutLength,1);
    %Also save the total volume of each 
    
    %Calculate the total population at this time point
    popTot(j,1) = sum(popXpos{j,1}(1,:));
    popTot(j,2) = sum(popXpos{j,2}(1,:));
    %Include a column of time
    popTot(j,3) = j*timestep*ones(size(popTot(j,1)));
 
end


fprintf(1,'.');
end