% calcMinCrop: Calculate the minimum crop rectangle around each region of
% the fish based on the gut outline of the fish. The minimum crop rectangle
% is the smallest box that contains both the gut outline of the fish and a
% given border with.
%
% USAGE: regionExtent = calcMinCrop(param, updateParam, borderWidth)
%
% INPUT: param: parameter file for fish
%        updateParam: update (save) the parameter file for this fish.
%        borderWidth (Optional): width around the gut outline to save in micron(Default: 0);
%
% OUTPUT: regionExtent (optional): New crop region.
%         param (optional): Updated param file
% AUTHOR: Matthew Jemielita, May 20, 2013

function varargout = calcMinCrop(param, updateParam, varargin)

switch nargin
    case 2
        borderWidth = 0;
    case 3
        borderWidth = (1./0.1625)*varargin{1};
        borderWidth = round(borderWidth);
    otherwise
        fprintf(2, 'CalcMinProp: takes either 2 or 3 inputs!');
        return
end

%Load in all poly masks.

maxS = size(param.regionExtent.polyAll,1);

xSize = param.regionExtent.regImSize{1}(1);
ySize = param.regionExtent.regImSize{1}(2);
allMask = zeros(xSize, ySize);

fprintf(1, 'Loading in masks');
for nS=1:maxS
   p = param.regionExtent.polyAll{nS};
   mask = poly2mask(p(:,1), p(:,2), xSize, ySize);
   
   allMask = allMask+mask;
   fprintf(1, '.');
end
fprintf(1, '\n');
allMask = double(allMask>0);


%Add border
se = strel('disk', borderWidth,0);
allMask = imdilate(allMask, se);


%Find cropping regions
maxR = size(param.regionExtent.XY{1},1);

for nR=1:maxR
    thisR = param.regionExtent.XY{1}(nR,:);
    
    thisMask = allMask;
    
    minX = thisR(1);
    maxX = thisR(1)+thisR(3)-1;
    minY = thisR(2);
    maxY = thisR(2)+thisR(4)-1;
    
    thisMask(minX:maxX, minY:maxY) = 1+ thisMask(minX:maxX, minY:maxY);
    
    thisMask = thisMask==2;
    
    %Find extent of this region
    if(isempty(sum(thisMask,2)) || isempty(sum(thisMask,1)))
        fprintf(2, 'calcMinCrop currently requires gut outline to span all regions!');
        return
    end
    
    mmX(1) = find(sum(thisMask,2)>0, 1, 'first');
    mmX(2) = find(sum(thisMask,2)>0, 1, 'last');
    
    mmY(1) = find(sum(thisMask,1)>0, 1, 'first');
    mmY(2) = find(sum(thisMask,1)>0, 1, 'last');
    
    
    xOutI = mmX(1);
    xLength = mmX(2)-mmX(1);
    
    xInI = mmX(1)-minX+1;
    
    yOutI = mmY(1);
    yLength = mmY(2)-mmY(1);
    yInI = mmY(1) - minY+1;
    
    thisR  = [xOutI, yOutI, xLength, yLength,  xInI, yInI];
   
    for nC=1:length(param.regionExtent.XY)
        param.regionExtent.XY{nC}(nR,:) = thisR;
    end
  
    
%Diagnostics    
%     figure; 
%     %imshow(thisMask+allMask,[]);
%     boundBox = zeros(size(thisMask));
%     boundBox(xOutI,:) = 1;
%     boundBox(xOutI+xLength,:) = 1;
%     boundBox(:,yOutI) = 1;
%     boundBox(:,yOutI+yLength) = 1;
%     boundBox = bwmorph(boundBox, 'dilate');
%     
%     boundBox = bwmorph(boundBox, 'dilate');
%     
%     boundBox = bwmorph(boundBox, 'dilate');
%     imshow(thisMask+allMask+boundBox,[]);
%     
%     pause
%     close all
%     
end

switch nargout
    case 1
        varargout{1} = param.regionExtent.XY{1};
    case 2
        varargout{1} = param.regionExtent.XY{1};
        varargout{2} = param;
end

if(updateParam==true)
    fprintf(1, 'Updating param file');
   save([param.dataSaveDirectory filesep 'param.mat'],  'param');
   fprintf(1, '\n');
end

end