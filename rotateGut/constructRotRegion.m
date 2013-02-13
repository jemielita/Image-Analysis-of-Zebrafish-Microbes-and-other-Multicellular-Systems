%constructRotRegion: For a given fish and region of rotated gut return the
%rotated image stack and rotated regions that we will use for analysis.
%
%USAGE [imStack, rotCenterLine, rotMask] = constructRotRegion(regNum,
%scanNum, color, param)
%
%INPUT: cutNum: region in the optimally cut gut to load
%       scanNum: scan number to load
%       color: color to load (ex. '488nm', '568nm'
%       param: structure with experimental parameters
%       onlyMask (optional): only calculate the center line and gut mask if
%       true
%OUTPUT: imStack: (optional) 3D stack containing rotated gut
%        rotCenterLine: points that pass through the center of the rotated
%        gut
%        rotMask: region masks that will be used to calculate the intensity
%        at different points along the center line
%
%AUTHOR: Matthew Jemielita, August 1, 2012

function varargout = constructRotRegion(cutNum,...
scanNum, color, param,varargin )

%% Quality check inputs
imVar.color = color;
imVar.zNum = ''; 
imVar.scanNum = scanNum;
%% Get gut mask and center line
[rotMask, rotCenterLine] = getMaskAndLine(param, scanNum, cutNum,imVar.color);

%If we're only calculating the masks, then return at this point
if(nargin==5 && varargin{1} ==true)
    varargout{1} = rotCenterLine;
    varargout{2} = rotMask;
    return
end

%% Load in image stack 

fprintf(1, '\n Loading in image stack...');

loadType = 'multiple'; %To return optimal cut.

%Loading in images as double.
imStack = load3dVolume(param, imVar, loadType, [cutNum,scanNum]);
fprintf(1,'...done!\n');


%% Set all points outside the gut mask to be NaN
outsideMask = ~rotMask;
fprintf(1, 'Setting region outside gut to NaN.');
for i=1:size(imStack,3)
    temp = imStack(:,:,i);
    temp(outsideMask) = NaN;
    imStack(:,:,i) = temp;
    fprintf(1, '.');
end
fprintf(1, '\n');

if(nargout==3)
    varargout{1} = imStack;
    varargout{2} = rotCenterLine;
    varargout{3} = rotMask;
elseif(nargout==2)
    varargout{1} = rotCenterLine;
    varargout{2} = rotMask;
end

fprintf(1, '\n');
end

function [rotMask, rotCenterLine] = getMaskAndLine(param, scanNum,cutNum,color)
%% Calculate rotated masks
cutVal = param.cutValAll{scanNum};
%Get mask of rotated gut
height = param.regionExtent.regImSize{1}(1);
width = param.regionExtent.regImSize{1}(2);

poly = param.regionExtent.polyAll{scanNum};
gutMask = poly2mask(poly(:,1), poly(:,2), height,width);

%Rotate the  mask
xMin =cutVal{cutNum, 4}(5); xMax = cutVal{cutNum,4}(6);
yMin = cutVal{cutNum,4}(3); yMax = cutVal{cutNum,4}(4);

theta = cutVal{cutNum,3};

gutMask = double(gutMask);

centerLine = param.centerLineAll{scanNum};

%Cut down the size of the center line
centerLine = centerLine(cutVal{cutNum,1}(1):cutVal{cutNum,1}(2),:);
 
gutMask(round(centerLine(1,2)), round(centerLine(1,1))) = 2;
%gutMaskRot = imrotate(gutMask,theta);

%% Calculate rotated center line and gut mask

[rotCenterLine,cutMask] = getRotatedLineAndMask(centerLine, cutVal, cutNum,height,width,gutMask);

%Rescale the rotated gut mask



%% Get rotated mask
rotMask = curveMask(cutMask, rotCenterLine, param,'rectangle');

%Fill in blank spots in the gut mask

rotMask = fillInMask(rotMask, cutMask);

%% Remove regions that have been selected as background

%See if we've also done a segmentation of the background fluorescence in
%the gut. If so, then also include those points
if(isfield(param.regionExtent, 'bulbMask'))
    
    for nC=1:length(param.color)
        
        % rotMaskAll{nC}{1} = rotMask;
        %for nSeg = 2:length(param.regionExtent.bulbMask{nC})+1
        rect = param.regionExtent.bulbRect;
        rect = round(rect);
        
        colorNum = find(strcmp(color, param.color));
        thisMask = ones(height, width);
        
        sizeM = size(thisMask(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)));
        sizeB = size(param.regionExtent.bulbMask{nC}(:,:,scanNum));
        %If sizes are different, adjust height and width of the rectangle
        rect(4) = rect(4)+ sizeB(1)-sizeM(1);
        rect(3) = rect(3) + sizeB(2)-sizeM(2);

        thisMask(rect(2):rect(2)+rect(4), rect(1):rect(1)+rect(3)) = param.regionExtent.bulbMask{nC}(:,:,scanNum);
        rotSegMask = imrotate(thisMask, theta);
        rotSegMask = rotSegMask(xMin:xMax,yMin:yMax);
        
        rotSegMask = rotSegMask==0;
        for nM=1:size(rotMask,3)
            thisRegMask = rotMask(:,:,nM);
            thisRegMask(rotSegMask) = NaN;
            rotMaskAll{nC}(:,:,nM) = thisRegMask;
        end
        
        % end
    end
    
    rotMask = rotMaskAll;
end

end

function [rotCenterLine,cutMask] = getRotatedLineAndMask(centerLine, cutVal, cutNum,height, width,gutMask)


hw = [width; height];
theta = -deg2rad(cutVal{cutNum,3});
rotMat = [cos(theta), -sin(theta); sin(theta), cos(theta)];

%Rotate about the center of the image
centerLineO(:,1)= centerLine(:,1)-(width/2);
centerLineO(:,2) = centerLine(:,2)-(height/2);

%rotCenterLine = rotMat*(centerLineO'+repmat(hw,1,size(centerLineO,1)));
rotCenterLine = rotMat*(centerLineO');

rotCenterLine = rotCenterLine';

%rotCenterLine(:,1) = rotCenterLine(:,1)+(width/2);
%rotCenterLine(:,2) = rotCenterLine(:,2)+(height/2);


%Rotate the gut mask
[y,x] = find(gutMask==1);
gutInd = [x-(width/2),y-(height/2)];
gutIndRot = rotMat*(gutInd');
gutIndRot = gutIndRot';

minX = min([1, min(gutIndRot(:,1)), min(rotCenterLine(:,1))])-1;
minY = min([1, min(gutIndRot(:,2)), min(rotCenterLine(:,2))])-1;

gutIndRot(:,1) = gutIndRot(:,1) -minX;
gutIndRot(:,2) = gutIndRot(:,2) - minY;
rotCenterLine(:,1) = rotCenterLine(:,1)- minX;
rotCenterLine(:,2) = rotCenterLine(:,2) - minY;

maxX = max([max(gutIndRot(:,1)), max(rotCenterLine(:,1))]);
maxY = max([max(gutIndRot(:,2)), max(rotCenterLine(:,2))]);

gutIndRot = floor(gutIndRot);
gutMaskRot = zeros(maxY,maxX);
ind = sub2ind(size(gutMaskRot), gutIndRot(:,2), gutIndRot(:,1));
gutMaskRot(ind) = 1;
gutMaskRot = ~bwareaopen(~gutMaskRot, 10);

%Crop down gut region to this cut.

initPos = 2; finalPos = size(rotCenterLine,1)-1;
cutPosInit = getOrthVect(rotCenterLine(:,1), rotCenterLine(:,2), 'rectangle', finalPos);
cutPosFinal = getOrthVect(rotCenterLine(:,1), rotCenterLine(:,2), 'rectangle', initPos);
pos = [cutPosFinal(1:2,:); cutPosInit(2,:); cutPosInit(1,:)];

cutMask = poly2mask(pos(:,1), pos(:,2), size(gutMaskRot,1), size(gutMaskRot,2));
cutMask = cutMask.*gutMaskRot;

%Crop down size of mask
[x,y] = find(bwperim(cutMask)==1);
xMin = min(x);xMax = max(x);
yMin = min(y); yMax = max(y);
cutMask = cutMask(xMin:xMax, yMin:yMax);
rotCenterLine(:,1) = rotCenterLine(:,1)-yMin;
rotCenterLine(:,2) = rotCenterLine(:,2)-xMin;

%Remove tips of 
%When using the imrotate command the image size is potentially changed. In
%order find out what the correct offset on the rotated center line find
%the difference in centroid location between the rotated and unrotated
%image.
%cOrig = regionprops(gutMask>0, 'Centroid');
%cRot = regionprops(gutMaskRot>0,'Centroid');
%rotCenterLine(:,1) = rotCenterLine(:,1) + cRot.Centroid(1)-cOrig.Centroid(1);
%rotCenterLine(:,2) = rotCenterLine(:,2) + cRot.Centroid(2)-cOrig.Centroid(2);

%Then deal with the resizing we're going to do on the rotated image.
%rotCenterLine(:,1) = rotCenterLine(:,1) -cutVal{cutNum,4}(3);
%rotCenterLine(:,2) = rotCenterLine(:,2) - cutVal{cutNum,4}(5);
end
 
function rotMask = fillInMask(rotMask, cutMask)

rotMaskAll = zeros(size(rotMask,1), size(rotMask,2));
for i =1:size(rotMask,3)
   rotMaskAll = rotMaskAll+rotMask(:,:,i);
end
rotMaskAlll = rotMaskAll>0;

exMask = cutMask-rotMaskAll;
exMask = exMask==1;

%Go through all regions
allReg = unique(rotMask(rotMask>0));

for nR =1:length(allReg)
   thisReg = allReg(nR);
   
   %Get this particular wedge, and it's location in rotMask
   wedgeMask = zeros(size(rotMask,1),size(rotMask,2));
   for i=1:size(rotMask,3)
       wedgeMask = wedgeMask + (rotMask(:,:,i)==thisReg);
       if(sum(wedgeMask(:))~=0)
           maskSlice = i;
           break
       end
   end
   wedgeMask = bwmorph(wedgeMask, 'dilate');
   
   inWedge = bwconncomp(wedgeMask, 8);
   inExMask = bwconncomp(exMask,8);


   exMaskOrig = exMask;
   for nM = 1:inExMask.NumObjects
       ind =  inExMask.PixelIdxList{nM};
       if(sum(intersect(inWedge.PixelIdxList{1},ind)))
          %If there's an intersection, remove this region from exMask and
          %add it to the appropriate region of rotMask
          exMask(ind) = 0;
           
          thisRotMask = rotMask(:,:,maskSlice);
          thisRotMask(ind) = thisReg;
          rotMask(:,:,maskSlice) = thisRotMask;
          
          temp = zeros(size(exMask));
          temp(ind) = 1;
%           imshow((thisRotMask>0)+5*temp,[]);
%           pause(0.1);
       end
   end
   
    
    
end


end