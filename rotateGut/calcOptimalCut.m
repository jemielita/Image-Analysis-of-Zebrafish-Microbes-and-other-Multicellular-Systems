% calcOptimalCut: For a given outline of a gut with a line drawn down
% through the center calculate the optimal division of the gut into
% multiple chunks to store the gut in memory. Even with >24 Gb of memory we
% are unable to store the entire gut in memory, in double precision, at
% once. As a result we need to divide the gut up into smaller chunks when
% doing analysis.
%
% USAGE: cutVal = calcOptimalCut(lengthOverlap, param)
%
% INPUT: param: parameter file associated with a particular fish.
%        This function requires two values in param to be set that aren't
%        automatically found:
%        1) param.regionExtent.poly-gives the outline of the gut
%        2) param.centerLine-gives the approximate center of the gut
%
% OUTPUT: cutVal: cell array of size n x 4, where n is the number of
% different regions in the optimal cut. cutVal{i,1} = [pos_init, pos_final] 
% final and initial position along the line given by param.centerLine 
% where the optimal cut is located.
% cutVal{i,2} = which regions are included in this particular region.
% cutVal{i,3} = angle to rotate the original image by to get the optimal
% image stack size.
% cutVal{i,4}(1,2) = size of rotated (pre-cropped) mask
% cutVal{i,4}(3:6) = xMin, xMax, yMin, yMax for cropped rotated mask
%
% AUTHOR: Matthew Jemielita, July 27, 2012

function cutVal = calcOptimalCut(lengthOverlap, param,scanNum)

displayProgress =false;
%See if the previous scan's outline is the same as this scans. If so, we
%don't have to recalculate the cut value.

if(scanNum>1 && isfield(param, 'cutValAll'))
    %If we've stored up previous cut values, see if we can load one instead
    %of recalculating it.
    for i=1:scanNum-1
       
        
       sameLine = isequal(param.centerLineAll{i}(:),param.centerLineAll{scanNum}(:));
       sameOutline = isequal(...
           param.regionExtent.polyAll{i}(:),param.regionExtent.polyAll{scanNum}(:));
       
       
%        if(sameLine==true && sameOutline==true && ~isempty(param.cutValAll{i}))
%            cutVal = param.cutValAll{i};
%            return;
%        end
    end
end


%Get mask of gut
height = param.regionExtent.regImSize{1}(1);
width = param.regionExtent.regImSize{1}(2);
polyX = param.regionExtent.polyAll{scanNum}(:,1);
polyY = param.regionExtent.polyAll{scanNum}(:,2);
mask = poly2mask(polyX, polyY, height, width);

centerLine = param.centerLineAll{scanNum};

%Get a test image 
imOrig = ones(height, width);
imOrig(~mask) = 0;

%Get masks for each of the different regions-will be used to see which
%regions are in which cut of the gut
numRegions = size(param.regionExtent.XY{1}, 1);
regionMask = cell(numRegions,1);

for i=1:numRegions
   regionMask{i} =  zeros(height, width);
   
   xMin = param.regionExtent.XY{1}(i,1);
   yMin = param.regionExtent.XY{1}(i,2);
   
   xMax = xMin + param.regionExtent.XY{1}(i,3)-1;
   yMax = yMin + param.regionExtent.XY{1}(i,4)-1;
   
   regionMask{i}(xMin:xMax, yMin:yMax) = 1;
end

%Find out how many z-slices are in each region
regionDepth = sum(param.regionExtent.Z>0)';
xyPlane = zeros(height,width);

%The largest array we will load in is one that's a quarter the size of all
%available memory (total physical memory is 16Gb)
[uV, sV] = memory;
%For now we'll just hard code this in...arbitrarily
maxArraySize = 2560*2160*200;

%Find optimal cut using a binary search
lastPoint = 2;

cutIndex = 1;
isEndGut=false;
maxPoint = size(centerLine,1)-1;

%If we found a cut on the previous time point, use this as a guess where
%the cut will be this time-the outlines don't change that much from point
%to point.
if(scanNum>1 &&  isfield(param, 'cutValAll')&&...
        ~isempty(param.cutValAll{scanNum-1}))
    thisPoint = param.cutValAll{scanNum-1}{1}(2);
    thisPoint = min([thisPoint,maxPoint]); 
else
    thisPoint = round((maxPoint-lastPoint)/2);
end

while(isEndGut==false)

    [cutPoint,theta,indReg,rotImSize] ...
        = findCut(lastPoint, maxPoint, thisPoint,displayProgress);
    
    cutVal{cutIndex, 1}(1) = lastPoint;%Beginning of the region
    
    cutVal{cutIndex, 2} = indReg;
    cutVal{cutIndex, 3} = theta;
    cutVal{cutIndex, 4} = rotImSize;
    temp = cutPoint;
      
    %Estimate for where the next cut should be
    %minus one  to use w/ getOrthVect
    %Include offset so that regions overlap (allowing us to do correlations
    %between points).
    thisPoint = min(maxPoint-1,cutPoint+thisPoint);
    lastPoint = cutPoint-lengthOverlap; 
    cutVal{cutIndex,1}(2) = cutPoint;
    
    %If we're close enough don't make a new region-need to do this in a
    %better way.
    if(abs(cutPoint-maxPoint)<5)
        if(displayProgress==true)
            disp('calcOptimalGut: Gut cut into the optimal sized lengths.');
        end
        cutPoint = maxPoint;
        isEndGut = true;
        
        %Set the end of this region to be the end of the gut.
        cutVal{cutIndex,1}(2) = maxPoint;
        
    end
    
    if(displayProgress==true);
        disp(['Cut found: ', num2str(cutVal{cutIndex,1}(2))]);
    end
    
    cutIndex = cutIndex+1;
     
    if(cutIndex>numRegions)
        if(displayProgress==true);
            disp('Number of cut regions exceeds original number of images! Error.');
        end
        
        return;
    end
end


    function [cutPoint, theta,indReg, rotImSize] = findCut(lastPoint, maxPoint,thisPoint,displayProgress)      
       
        lastPos = getOrthVect(centerLine(:,1), centerLine(:,2), 'rectangle',lastPoint);
                
        binPos(1) = lastPoint;
        binPos(2) = maxPoint;
        
        isMaxSize =false;
        %Point at which we'll stop the binary search...it's doubtful we'll have to
        %go very far
        maxNumIts = 5;
        its = 0;
        while(isMaxSize==false)
            thisPos = getOrthVect(centerLine(:,1), centerLine(:,2), 'rectangle',thisPoint);          
            %note: we might need to play around with this for a bit
            %To get around feature that getOrthVect returns a box at thisPoint
            pos =[thisPos(1:2,:); lastPos(2,:); lastPos(1,:)];
            
            thisMask = poly2mask(pos(:,1), pos(:,2), height, width);
            thisMask = thisMask.*mask;
            
            %Find the optimal angle to rotate this mask to minimize the area of the
            %minimal confining rectangle of the outline of the gut.
            [xRange, yRange, ~, ~] = optimalAngle(thisMask, 'quick');
            
            %See which regions overlap with this mask
            whichRegions = cellfun(@(regionMask)ismember(2, regionMask(:)+thisMask(:)), regionMask);
            indReg = whichRegions==1;
            %See how much memory we would need to produce an array of this size
            
            %For the z-depth
            theseRegions = param.regionExtent.Z(:,indReg);
            %Collapse this array
            theseRegions = theseRegions>0;
            theseRegions = sum(theseRegions,2);
            %Find first and last non-zeros entry-this will give the necessary range
            %in z
            minZ = find(theseRegions~=0,1, 'first');
            maxZ = find(theseRegions~=0,1, 'last');
            
            zRange = maxZ-minZ+1;
            
            %Number of pixels in double precision that we can load in
            totMemory = xRange*yRange*zRange;
            
            %Update the next thisPoint using binary search
            if(totMemory>maxArraySize)
                binPos(2) = thisPoint;
                thisPoint = binPos(1)+round((thisPoint-binPos(1))/2);
                lastPoint = binPos(1);
                
            elseif(totMemory<maxArraySize)
                binPos(1) = thisPoint;
                lastPoint = thisPoint;
                thisPoint = thisPoint + round((binPos(2)-thisPoint)/2);

            elseif(totMemory==maxArraySize||abs(thisPoint-maxPoint)<5)
                isMaxSize = true;
            elseif(abs((totMemory-maxArraySize)/maxArraySize -1)<0.2)
                %If we're within 20 percent of the maximum size, return
                %this as a good cut...We don't have to be super precise.
                isMaxSize = true;
                
            end
            %If we're pretty close to the end then don't bother to make
            %a new region
            if(abs(thisPoint-maxPoint)<5)
                isMaxSize=true;
            end
            
            if(its>=maxNumIts )
                isMaxSize=true;
            end

            its = its+1;
            if(displayProgress==true)
                fprintf(1, '.');
            end
        end
       
        [~, ~, theta, rotImSize] = optimalAngle(thisMask, 'slow');
        cutPoint = thisPoint;
    end


end
