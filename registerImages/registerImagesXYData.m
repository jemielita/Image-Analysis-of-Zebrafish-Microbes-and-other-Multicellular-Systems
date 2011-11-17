%For a given directory structure return the parameters that correspond to
%regions that are overlapping between different regions.
%SUMMARY: [data, param] = registerImagesData(data,param)
%
%Returns param.registerImXY which is an array of size: [numRegions-1,2, 4].
%The second argument gives the region of overlap for the first region (from
%top to bottom), while the second gives the overlap for the second region
%(the bottom one). For each region, a rectangle of form [x init, y init,
%width height] is calculated. This is the same format used by imcrop.
%So param.registerIm(1,1,:) will give the region of overlap in region 1 for
%the overlap between region 1 and 2, and param.regsiterIm(1,2,:) will give
%the region of overlap in region 2 for the overlap between region 1 and 2.
%FIX UP THIS SUMMARY!!
function [data, param] = registerImagesXYData(data,param)


%%Get the range of pixel data for each region.
%Note: we should make it possible to use the cropped region to do this
%calculation, to keep the code as general as possible.

%%Find the extent of each region of the scan
totalNumRegions = unique([param.expData.Scan.region]);
totalNumRegions = length(totalNumRegions);

%Create a structure that will contain the x, y, and z location of each
%region
regLoc = zeros(totalNumRegions, 6);

for regNum=1:totalNumRegions
    regionIndex = find([param.expData.Scan.region]==regNum,1); 
    %Only return first found value, in case there are more than one color. 
    
    %Read out the locations in 1/10ths of microns
    regLoc(regNum,1) = param.expData.Scan(regionIndex).xBegin;
    regLoc(regNum,2) = param.expData.Scan(regionIndex).yBegin;
    
    %Convert micron range to pixels;
    %Note: .xBegin, .yBegin are measured in 1/10th of microns (format used
    %by ASI)
    regLoc(regNum,:) = (1.0/param.micronPerPixel)*0.1*regLoc(regNum,:);
end

%Rescale the pixel range so that the minimum x and y pixel location are
%both 1.
regLoc(:,1) = regLoc(:,1) - min(regLoc(:,1))+1;
regLoc(:,2) = regLoc(:,2) - min(regLoc(:,2))+1;

% 
% %Get the range of pixels for each of these regions.
 regLoc(:,3) = regLoc(:,1) + param.imSize(1)-1; %image length in pixels
 regLoc(:,4) = regLoc(:,2) + param.imSize(2)-1; %image width in pixels.

 regLoc(:,5:6) = 1;
 
%Store the result in the structure param.regionExtent, where
%param.regionExtentXY is a regNum x 6 matrix with entries:
%[pixel X location, pixel Y Location, pixel extent X, 
% pixel extent Y,initial x pixel (on image), initial y pixel (on image)]

param.regionExtent.XY = regLoc;

end