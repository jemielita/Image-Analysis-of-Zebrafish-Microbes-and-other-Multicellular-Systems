%For a given directory structure return the parameters that would allow a
%mosaic of the different regions to be created.

function [data, param] = registerImagesData(data,param)

%%Get the range of pixel data for each region.
%Note: we should make it possible to use the cropped region to do this
%calculation, to keep the code as general as possible.

%%Find the extent of each region of the scan
totalNumRegions = unique([param.expData.Scan.region]);
totalNumRegions = length(totalNumRegions);

%Create a structure that will contain the x, y, and z location of each
%region
%Note: currently image size hard coded into code-this should be changed, to
%make it possible to overlap cropped images.
regLoc = zeros(totalNumRegions, 5);

for regNum=1:totalNumRegions
    regionIndex = find([param.expData.Scan.region]==regNum,1); 
    %Only return first found value, in case there are more than one color. 
    
    %Read out the locations in 1/10ths of microns
    regLoc(regNum,1) = param.expData.Scan(regionIndex).xBegin;
    regLoc(regNum,2) = param.expData.Scan(regionIndex).yBegin;
    regLoc(regNum,3) = param.expData.Scan(regionIndex).zBegin;
    
    %Convert micron range to pixels;
    %Note: .xBegin, .yBegin are measured in 1/10th of microns (format used
    %by ASI)
    regLoc(regNum,:) = (1.0/param.micronPerPixel)*0.1*regLoc(regNum,:);

end


regLoc(:,4) = 2160; %image length in pixels
regLoc(:,5) = 2560; %image width in pixels.

%Calculate the range of overlap between each region
pixOverlap = zeros(totalNumRegions-1,2);

pixOverlap(:,1) = regLoc(2:totalNumRegions,4)-...
regLoc(2:totalNumRegions,1)+regLoc(1:totalNumRegions-1,1);

pixOverlap(:,2) = regLoc(2:totalNumRegions,5)-... 
regLoc(2:totalNumRegions,2)+regLoc(1:totalNumRegions-1,2);



b = 0;


%%Store the result in the format: 
%       registerIm(i,1): rectangle giving the pixel range in region A that
%       overlap with pixels in region B.
%       registerIm(i,2): rectangel giving the pixel rangein region B that
%       overlap with pixels in region A.
%       NOTE: For n regions there will only be n-1 values of i.

registerIm = zeros(totalNumRegions-1, 2, 2,2);

for regNum =1:totalNumRegions-1
   rectTop = [regLoc(regNum,4)-pixOverlap(regNum,1), regLoc(regNum,4);...
       regLoc(regNum,5)-pixOverlap(regNum,2), regLoc(regNum,5)];
   rectBot = [0, pixOverlap(regNum,1);...
       0, pixOverlap(regNum,2)];
    registerIm(regNum,1,:,:) = rectTop;
    registerIm(regNum,2,:,:) = rectBot;
end

param.registerIm = registerIm;
end