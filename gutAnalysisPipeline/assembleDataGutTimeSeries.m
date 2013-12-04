%assembleDataGutTimeSeries: Collect together all the data necessary to plot
%bacteria population sizes over time.
%
%USAGE: [popTot, popXpos] = assembleDataGutTimeSeris(param, sMin, sMax,
%bacInten, bkgInten)
%
%AUTHOR: Matthew Jemielita, Dec. 6, 2012
%
function [popTot, popXpos, bkgDiff] = assembleDataGutTimeSeries(param, sMin, sMax,...
bacInten, bkgInten, bkgOffset,varargin)


singleBacCount = '';

numColor = length(param.color);
switch nargin
    case 6
        subDir = '';
    case 7
        subDir = varargin{1};
    case 8
        subDir = varargin{1};
        singleBacCount = varargin{2};
    case 9
        subDir = varargin{1};
        singleBacCount = varargin{2};
        cList = varargin{3};
        numColor = length(cList);
end
    
%% Getting parameters and preallocating arrays
NtimePoints = sMax-sMin+1;

boxWidth = 5; %Should be an input, but it's almost always this.
formatstr = '%d';

if(isempty(subDir))
    matfilebase = 'Analysis_Scan'; ext = '.mat';
else
    matfilebase = [subDir filesep 'Analysis_Scan']; ext = '.mat';
end
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
    
    for nC=1:numColor
        %The background is the product of the mean background value and the
        %total volume of this box
        meanBkg{nC} = bkgOffset*bkgInten{nC}{j}(1:gutLength)';
        
        regArea = regFeatures{nC,2}(1:gutLength,2);
        regMean = regFeatures{nC,1}(1:gutLength,1);
        
        bkg{nC} = meanBkg{nC}.*regArea;
        
        %thisLine{nC} = regFeatures{nC,2}(1:gutLength,1)-bkg{nC};
        thisLine{nC} = (regArea.*regMean)-bkg{nC};
        %Force the total intensity after background subtraction to be positive
        zPad = zeros(gutLength,1);
        thisLine{nC} = max([thisLine{nC}, zPad],[],2);
        
        %Convert to number of bacteria
        thisLine{nC} = thisLine{nC} / bacInten(1);
        
        % save in structured array
        xPos = xpos(1:gutLength);
        popXpos{j,nC}(1,:) = thisLine{nC}(1:gutLength);
        
        %Save the difference between the predicted background mean and the
        %total pixel
        bkgDiff{j,nC} = ...
            (regFeatures{nC}(1:gutLength,1)./regFeatures{nC}(1:gutLength,2))...
            ./ bkgInten{nC}{j}(1,1:gutLength)';
        
        bkgDiff{j,3} = bkgInten{1}{j}(1,1:gutLength)'.*regFeatures{1}(1:gutLength,2);
        bkgDiff{j,4} = regFeatures{2}(1:gutLength,1);
        
    end
    
    %Save position array
    popXpos{j,1}(2,:) = xPos; popXpos{j,2}(2,:) = xPos;
    %Save time information-need to change this up a bit to include
    %information about the delay after the last inoculation-to better
    %overlap different data sets
    popXpos{j,1}(3,:) = j*timestep*ones(size(xPos));
    popXpos{j,2}(3,:) = j*timestep*ones(size(xPos));
    

    %Also save the total volume of each 
    
    %Calculate the total population at this time point
    popTot(j,1) = nansum(popXpos{j,1}(1,:));
    popTot(j,2) = nansum(popXpos{j,2}(1,:));
    %Include a column of time
    popTot(j,3) = j*timestep*ones(size(popTot(j,1)));
    
    
    %Also load in single bacteria count if it's been calculated
    if(~isempty(singleBacCount))
        popTot(j,4) = sum(singleBacCount([1 2 4],j),1);
    end
 
end


fprintf(1,'.');
end