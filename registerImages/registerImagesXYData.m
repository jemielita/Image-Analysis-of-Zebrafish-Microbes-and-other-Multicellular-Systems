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



%%Store the result in the format: 
%       registerIm(i,1): rectangle giving the pixel range in region A that
%       overlap with pixels in region B.
%       registerIm(i,2): rectangel giving the pixel rangein region B that
%       overlap with pixels in region A.
%       NOTE: For n regions there will only be n-1 values of i.

registerIm = zeros(totalNumRegions-1, 2, 4);

for regNum =1:totalNumRegions-1
       rectTop = [regLoc(regNum,5)-pixOverlap(regNum,2)  regLoc(regNum,4)-pixOverlap(regNum,1)...
           pixOverlap(regNum,2) pixOverlap(regNum,1)];
       rectBottom =[1 1  pixOverlap(regNum,2) pixOverlap(regNum,1)]; %Changed from 0 to 1
       registerIm(regNum,1,:) = rectTop;
       registerIm(regNum,2,:) = rectBottom;
end

%Returned the overlaped regions.
registerIm = floor(registerIm);
param.registerImXY = registerIm;






%Above approach was clumsy...we'll do something else instead

xData = [param.expData.Scan.xBegin];
yData = [param.expData.Scan.yBegin];

xData = (1.0/param.micronPerPixel)*0.1*xData;
yData = (1.0/param.micronPerPixel)*0.1*yData;

%Rounding down all the data
xData = floor(xData);
yData = floor(yData);

%Finding the range of the data
imRange(1,1) = min([yData]);
imRange(1,2) = max([yData]);

imRange(2,1) = min([xData]);
imRange(2,2) = max([xData]);

%We'll rescale all the x and y data so that the origin (1,1) is at the
%smallest x and y point.

xData = xData- imRange(2,1)+1;
yData = yData - imRange(1,1)+1;

%Removing points that correspond to the same colors.
%DANGER: this is hard coded in!!!!!!
xData = xData(1:2:length(xData));
yData = yData(1:2:length(yData));

%Adding in the size of the images
xData = [xData; xData+2159];
yData = [yData; yData + 2559];

%Now we need to also calculate the part of each regions that will be
%overlaped.

%This matrices gives the location on the master image for the overlapped
%regions, and the range that they are drawn from on the original images.
overlap = zeros(size(xData,2)-1,2,2);
overlapOrig = zeros(size(xData,2)-1,2,2,2);

for i=1:size(xData,2)-1
   overlap(i,1,1) = xData(1,i+1);
   overlap(i,1,2) = yData(1,i+1);
   
   overlap(i,2,1) = xData(2,i);
   overlap(i,2,2) = yData(2,i);

   xGapSize = overlap(i,2,1)-overlap(i,1,1);
   yGapSize = overlap(i,2,2)-overlap(i,1,2);

%Is this right?   
   xGapSize = abs(xGapSize);
   yGapSize = abs(yGapSize);

   %For the first region
   overlapOrig(i,1,1,1) =  2160-xGapSize;
   overlapOrig(i,1,2,1) = 2160;
   
   overlapOrig(i,1,1,2) =  2560-yGapSize;
   overlapOrig(i,1,2,2) = 2560;
   
   %And the second
   overlapOrig(i,2,1,1) =  1;
   overlapOrig(i,2,2,1) = 1+xGapSize;
   
   overlapOrig(i,2,1,2) =  1;
   overlapOrig(i,2,2,2) = 1+yGapSize;

   xGapSize
   yGapSize
   
   %Now lets be anal and test the x and y range for all these different
   %regions that we've construted. They should all be the same size.
   
   xLength(1) = overlap(i,2,1)-overlap(i,1,1);
   xLength(2) = overlapOrig(i,1,2,1)-overlapOrig(i,1,1,1);
   xLength(3) = overlapOrig(i,2,2,1) -overlapOrig(i,2,1,1);
   
   yLength(1) = overlap(i,2,2)-overlap(i,1,2);
   yLength(2) = overlapOrig(i,1,2,2)-overlapOrig(i,1,1,2);
   yLength(3) = overlapOrig(i,2,2,2) -overlapOrig(i,2,1,2);

   if(length(unique(xLength))>1 || length(unique(yLength))>1)
      disp('The regions to overlap are not the same size!')
      return;
   end
   
end

%Output these results. When the code is better tested, we'll remove the
%junk above.
param.registerOverlap = overlap;
param.registerOverlapOrig = overlapOrig;
param.registerLoc.x = xData;
param.registerLoc.y = yData;

end