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
%
%Code assumes that all of the regions scanned have the same color order:
%ex: rg, rg, rg,...
function [data, param] = registerImagesXYData(type, data,param)
%%Get the range of pixel data for each region.
%Note: we should make it possible to use the cropped region to do this
%calculation, to keep the code as general as possible.

%%Find the extent of each region of the scan
%Only count regions that are scans, not videos
totalNumRegions = unique([param.expData.Scan.region].*[strcmp('true', {param.expData.Scan.isScan})]);
totalNumRegions(totalNumRegions==0) = [];

totalNumRegions = length(totalNumRegions);
% 
% cIn1 = 1;cIn2 = 1;
% for i=1:size(param.expData.Scan,2)
%    thisColor= param.expData.Scan(i).color;
%    switch thisColor
%        case '488 nm: GFP'
%            colorIndex{1}(cIn1) = i;
%            cIn1 = cIn1+1;
%        case '568 nm: RFP'
%            colorIndex{2}(cIn2)=i;
%            cIn2 = cIn2+1;
%    end
% end

switch lower(type)
    case 'original'
        param = registerOriginalImage(param,totalNumRegions);
        
    case 'crop'
        param = registerCroppedImage(param,totalNumRegions);
    case 'overlap'
        %Just keep on going and calculate the overlapped region
end

%And get the index location of all pixels that are in parts of the image
%where regions overlap.

numColor = length(param.color);  
regOverlap = [1:totalNumRegions-1 ; 2:totalNumRegions];

numOverlapReg = size(regOverlap,2);

overlap = cell(numColor, numOverlapReg);

for colorNum=1:numColor
    
    im = ones(param.regionExtent.regImSize{colorNum}(1), param.regionExtent.regImSize{colorNum}(2));
    
    for regNum = 1:numOverlapReg
        im(:) = 0;
        temp1 = im;
        temp2 = im;
        
        reg1 = regOverlap(1,regNum);
        reg2 = regOverlap(2,regNum);
        
        %Get the part of the registered image from one of the subimages
        xInit = param.regionExtent.XY{colorNum}(reg1,1);
        xFinal = xInit + param.regionExtent.XY{colorNum}(reg1,3) -1;
        yInit = param.regionExtent.XY{colorNum}(reg1,2);
        yFinal = yInit + param.regionExtent.XY{colorNum}(reg1,4) -1;
        
        temp1(xInit:xFinal,yInit:yFinal) = 1;
        
        %and the other subimage
        xInit = param.regionExtent.XY{colorNum}(reg2,1);
        xFinal = xInit + param.regionExtent.XY{colorNum}(reg2,3) -1;
        yInit = param.regionExtent.XY{colorNum}(reg2,2);
        yFinal = yInit + param.regionExtent.XY{colorNum}(reg2,4) -1;
        
        %Combining them together and looking for the overlaped regions.
        temp2(xInit:xFinal, yInit:yFinal) = 1;

        im = temp1+temp2;
        %Saving the index number of the overlaped pixels.
        param.regionExtent.overlapIndex{colorNum,regNum} = find(im==2);        
    end
    

end


end

function param = registerCroppedImage(param,totalNumRegions)
%Use the user defined box sizes of the cropped regions to determine the
%size of the cropped regions that are loaded in as images from now on.

%Store the result in the structure param.regionExtent, where
%param.regionExtentXY is a regNum x 6 matrix with entries:
%[pixel X location, pixel Y Location, pixel extent X,
% pixel extent Y,initial x pixel (on image), initial y pixel (on image)]

numColor = length(param.color);
regLoc = zeros(totalNumRegions,6);



for colorNum =1:numColor
    for regNum=1:totalNumRegions
        
        regLoc(regNum,1) = max(param.regionExtent.crop.XY(regNum,2), ...
            param.regionExtent.XY{colorNum}(regNum,1));
        regLoc(regNum,2) = max(param.regionExtent.crop.XY(regNum,1),...
            param.regionExtent.XY{colorNum}(regNum,2));
        
        
        
        regLoc(regNum, 5) = max(1,...
            regLoc(regNum,1)-param.regionExtent.XY{colorNum}(regNum,1)+1);
        regLoc(regNum,6) = max(1,...
            regLoc(regNum,2) - param.regionExtent.XY{colorNum}(regNum,2)+1);

        %Get the width and height of the original image in this region
        ind = find([param.expData.Scan.region]==regNum, 1, 'first');
        
        imWidth = param.expData.Scan(ind).imSize(1);
        imHeight = param.expData.Scan(ind).imSize(2);
        
        regLoc(regNum,3) = min(1+imWidth-regLoc(regNum,5), ...
            param.regionExtent.crop.XY(regNum,4));
        regLoc(regNum,4) = min(1+imHeight- regLoc(regNum,6),...
            param.regionExtent.crop.XY(regNum,3));
        
    end

    %Rescale the pixel range so that the minimum x and y pixel location are
    %both 1.
    regLoc(:,1) = regLoc(:,1) - min(regLoc(:,1))+1;
    regLoc(:,2) = regLoc(:,2) - min(regLoc(:,2))+1;

    param.regionExtent.XY{colorNum} = regLoc;
    
    %Also store the size of the registered image
    param.regionExtent.regImSize{colorNum}(1) = max(regLoc(:,1) +regLoc(:,3)-1);
    param.regionExtent.regImSize{colorNum}(2) = max(regLoc(:,2) +regLoc(:,4)-1);
end


end

function param = registerOriginalImage(param,totalNumRegions)

%Create a structure that will contain the x, y, and z location of each
%region
regLoc = zeros(totalNumRegions, 6);

%Create a different list of regions locations for the different colors in
%the experiment.
numColor = length(param.color);
for colorNum=1:numColor

for regNum=1:totalNumRegions
    
    regionIndex = find([param.expData.Scan.region]==regNum,numColor);
    regionIndex = regionIndex(colorNum);%Return the appropriate region for this color
    
    %Read out the locations in 1/10ths of microns
    
    %mlj: temporarily changed from xBegin to zBegin-I think this is what's
    %causing the bug in the registration
    %mlj: negative sign important for aligning images

    if(param.expData.Scan(1).xBegin==min([param.expData.Scan(:).xBegin]))
      %  regLoc(regNum,1) = param.expData.Scan(regionIndex).xBegin;
    else
   %     regLoc(regNum,1) = -param.expData.Scan(regionIndex).xBegin;
    end
    
    
       regLoc(regNum,1) = -param.expData.Scan(regionIndex).xBegin;
       
       
       regLoc(regNum,1) = regLoc(regNum,1) +2*10*0.1625*(param.expData.Scan(regionIndex).cropRegion(1));
%  regLoc(regNum,1) = regLoc(regNum,1) + (10*0.1625)*(2160 -param.expData.Scan(regionIndex).cropRegion(1)-...
 %     param.expData.Scan(regionIndex).cropRegion(3));
  
    %   regLoc(regNum,1) = param.expData.Scan(regionIndex).xBegin
    regLoc(regNum,2) = param.expData.Scan(regionIndex).yBegin;
    
    %Convert micron range to pixels;
    %Note: .xBegin, .yBegin are measured in 1/10th of microns (format used
    %by ASI)
    regLoc(regNum,:) = (1.0/param.micronPerPixel)*0.1*regLoc(regNum,:);

    %Get the size of the images in this region, if it's different from the
    %total field of view (which will happen if the cropped image was saved
    %at any point;
    
    if(isfield(param.expData.Scan, 'imSize'))
        regLoc(regNum,3) = param.expData.Scan(regionIndex).imSize(1);
        regLoc(regNum,4) = param.expData.Scan(regionIndex).imSize(2);
    else
        %Otherwise default to the maximum pixel size of the camera
        regLoc(regNum,3) =  param.imSize(1); %image length in pixels
        regLoc(regNum,4) =  param.imSize(2); %image width in pixels.
    end
    
end

%Round the result
regLoc = round(regLoc);

%Rescale the pixel range so that the minimum x and y pixel location are
%both 1.
regLoc(:,1) = regLoc(:,1) - min(regLoc(:,1))+1;
regLoc(:,2) = regLoc(:,2) - min(regLoc(:,2))+1;
regLoc(:,5:6) = 1;

%Store the result in the structure param.regionExtent, where
%param.regionExtentXY is a regNum x 6 matrix with entries:
%[pixel X location, pixel Y Location, pixel extent X,
% pixel extent Y,initial x pixel (on image), initial y pixel (on image)]

%Also store the size of the registered image
param.regionExtent.regImSize{colorNum}(1) = max(regLoc(:,1) +regLoc(:,3)-1);
param.regionExtent.regImSize{colorNum}(2) = max(regLoc(:,2) +regLoc(:,4)-1);

param.regionExtent.XY{colorNum} = regLoc;

end


end

