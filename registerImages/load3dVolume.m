%load3dVolume:Load a 3D volume of a particular region of the gut
%
%Note: need to optimize this for speed-this will likely be a bottleneck in
%much of our analysis.
%
% USAGE: imStack = load3dVolume(param, imVar, loadType)
%       
%        imStack = load3dVolume(param, imVar, 'single', regionNumber);
%        imStack = load3dVolume(param, imVar, 'multiple', cutNumber);
%        imStack = load3dVolume(param, imVar, loadType, dataType, '32bit');
%
% INPUT: -param: parameters associated with this scan
%        -imVar structure containing the following elements
%           imVar.color = color (ex. '488nm', '568nm');
%           imvar.zNum = which z plane to use-currently not being used
%           imVar.scanNum = which scan number to load in
%        -loadType: 'single' or 'multiple'. If 'single', user must also
%        provide a region to load in. If 'multiple', user must provide a
%        a cut number which gives which cut region to load in. In addition
%        the field param.cutRegion must be set. The function calcOptimalCut
%        must be used to find this cut.
%        -dataType:(optional) which type of array to make. Currently only
%        support for uint16, uint32, and double. Default is double.
%
% OUTPUT: imStack: 3d volume containing the entire desired 3d image stack.
%
% AUTHOR: Matthew Jemielita, Written: June 14, 2012. Modified: July 31, 2012

function imStack = load3dVolume(param, imVar, loadType,varargin)

%% Loading in variables
switch loadType
    case 'single'
        regionNumber = varargin{1};
    case 'multiple'
        cutNumber = varargin{1};
end

if nargin==6
    dataType = varargin{6};
elseif nargin==4
    dataType = 'double';
else 
    disp('Number of inputs must be either 4 or 6!');
    return
end

%% Load in image stack
switch loadType
    case 'single'
        imStack = loadSingleRegion(param, imVar, regionNumber, dataType);
    case 'multiple'
        imStack = loadCutRegion(param, imVar, cutNumber, dataType);
end

end
%Load in all images in a one region
function im = loadSingleRegion(param, imVar, regNum, dataType)
%Allocating a huge array for the entire image stack
colorNum =  find(strcmp(param.color, imVar.color));

%Getting a list of all the image to load in
zList = param.regionExtent.Z(param.regionExtent.Z(:,regNum)~=-1,regNum);
totalZ = size(zList,1);

%The array will be of type dataType (double, etc.) to make it possible to
%more efficiently use memory if possible (e.g. we don't need double
%precision if we're only calculating pixel intensity).
im = zeros(param.regionExtent.XY{colorNum}(regNum,3),...
    param.regionExtent.XY{colorNum}(regNum,4),totalZ, dataType);

%Get the extent of this region
xOutI = param.regionExtent.XY{colorNum}(regNum,1);
xOutF = param.regionExtent.XY{colorNum}(regNum,3)+xOutI-1;

yOutI = param.regionExtent.XY{colorNum}(regNum,2);
yOutF = param.regionExtent.XY{colorNum}(regNum,4)+yOutI -1;

xInI = param.regionExtent.XY{colorNum}(regNum,5);
xInF = xOutF - xOutI +xInI;

yInI = param.regionExtent.XY{colorNum}(regNum,6);
yInF = yOutF - yOutI +yInI;

baseDir = [param.directoryName filesep 'Scans' filesep];
%Going through each scan
scanDir = [baseDir, 'scan_', num2str(imVar.scanNum), filesep];


for nZ = 1:totalZ
    imNum = zList(nZ);
    
    imFileName = ...
        strcat(scanDir,  'region_', num2str(regNum),filesep,...
        param.color(colorNum), filesep,'pco', num2str(imNum),'.tif');
    try
        im(:,:,nZ)= imread(imFileName{1},'PixelRegion', {[xInI xInF], [yInI yInF]});
    catch
        disp('This image doesnt exist-fix up your code!!!!');
    end
end


end


%Load in all images in one particular cut of the gut
function im = loadCutRegion(param, imVar, cutNumber, dataType)

thisCut = cell(4,1);
thisCut{1} = param.cutVal{cutNumber,1};
thisCut{2} = param.cutVal{cutNumber,2};
thisCut{3} = param.cutVal{cutNumber,3};
thisCut{4} = param.cutVal{cutNumber,4};

centerLine = param.centerLine;

colorNum = find(strcmp(param.color, imVar.color));
indReg = find(thisCut{2}==1);

%Get z extent that we need to load in
zList = param.regionExtent.Z(:, indReg);
zList = zList>0;
zList = sum(zList,2);
minZ = find(zList~=0, 1, 'first');
maxZ = find(zList~=0, 1, 'last');
finalDepth = maxZ-minZ+1;

%Get mask of gut
height = param.regionExtent.regImSize{1}(1);
width = param.regionExtent.regImSize{1}(2);
polyX = param.regionExtent.poly(:,1);
polyY = param.regionExtent.poly(:,2);
gutMask = poly2mask(polyX, polyY, height, width);

imOrig = zeros(height, width, dataType);

%Size of pre-cropped rotated image
imRotate = zeros(thisCut{4}(1), thisCut{4}(2), dataType);

%Final image stack
xMin =thisCut{4}(5); xMax = thisCut{4}(6);
yMin = thisCut{4}(3); yMax = thisCut{4}(4);
finalHeight = xMax-xMin+1;
finalWidth = yMax-yMin+1;

im = zeros(finalHeight, finalWidth, finalDepth, dataType);

%Crop down the mask to the size of the cut region
maxCut = size(param.cutVal,1);
% 
% if(cutNumber==maxCut)
%     finalPoint = size(param.centerLine,1)-1;
%     cutPosInit = getOrthVect(centerLine(:,1), centerLine(:,2), 'rectangle',finalPoint);
% else
%     lastCut{1} = param.cutVal{cutNumber+1,:};
%     cutPosInit = getOrthVect(centerLine(:,1), centerLine(:,2), 'rectangle',lastCut{1});
% end
cutPosInit = getOrthVect(centerLine(:,1), centerLine(:,2), 'rectangle', thisCut{1}(2));
cutPosFinal = getOrthVect(centerLine(:,1), centerLine(:,2), 'rectangle', thisCut{1}(1));

pos = [cutPosFinal(1:2,:); cutPosInit(2,:); cutPosInit(1,:)];

cutMask = poly2mask(pos(:,1), pos(:,2), height, width);
cutMask = cutMask.*gutMask;



%Load in the entire volume
baseDir = [param.directoryName filesep 'Scans' filesep];
%Going through each scan
scanDir = [baseDir, 'scan_', num2str(imVar.scanNum), filesep];

%Find the indices to map the original image points onto the rotated image
theta = thisCut{3};
[oI, rI] = rotationIndex(cutMask, theta);

for nZ=minZ:maxZ
    
    imOrig(:) = 0;
    for i = 1:length(indReg)
       regNum = indReg(i);
       imNum = param.regionExtent.Z(nZ, regNum);
      
       if(imNum==-1)
           %This region isn't at this particular z-plane
           continue
       end
           
       %Get the extent of this region
       xOutI = param.regionExtent.XY{colorNum}(regNum,1);
       xOutF = param.regionExtent.XY{colorNum}(regNum,3)+xOutI-1;
       
       yOutI = param.regionExtent.XY{colorNum}(regNum,2);
       yOutF = param.regionExtent.XY{colorNum}(regNum,4)+yOutI -1;
       
       xInI = param.regionExtent.XY{colorNum}(regNum,5);
       xInF = xOutF - xOutI +xInI;
       
       yInI = param.regionExtent.XY{colorNum}(regNum,6);
       yInF = yOutF - yOutI +yInI;
       
       %Load in the image
       imFileName = ...
           strcat(scanDir,  'region_', num2str(regNum),filesep,...
           param.color(colorNum), filesep,'pco', num2str(imNum),'.tif');
       try
       
           thisIm = imread(imFileName{1},'PixelRegion', {[xInI xInF], [yInI yInF]});
           
           %Cast loaded image to the appropriate data type
           switch dataType
               case 'double'
                   thisIm = double(thisIm);
               case 'uint16'
                   thisIm = uint16(thisIm);
               case 'uint32'
                   thisIm = uint32(thisIm);
           end          
           imOrig(xOutI:xOutF, yOutI:yOutF) = imOrig(xOutI:xOutF, yOutI:yOutF) + thisIm;
      
       catch
           disp('This image doesnt exist-fix up your code!!!!');
       end
         
    end
    
    imNum = param.regionExtent.Z(nZ, indReg);
    %Deal with overlapping regions
    for nR = 2:length(indReg)
        thisReg = indReg(nR-1);
        
        %Overlapping regions
        %This is potentially slow (however we need to be as quick as possible with this type of thing).
        %After we know this code works, we'll come back and write quicker code.
        
        %Overlap for regNum>1
        if(imNum(nR-1)>=0 &&imNum(nR)>=0)
            imOrig(param.regionExtent.overlapIndex{colorNum,thisReg} )= ...
                0.5*imOrig(param.regionExtent.overlapIndex{colorNum,thisReg});
            %    im(:) =1;
            %   im(param.regionExtent.overlapIndex{regNum-1} ) = 0;
        end
        
    end
    
    %Applying mask
    imOrig = imOrig.*cutMask;

    %Rotating the image
    imRotate(:) = 0;
    imRotate(rI) = imOrig(oI);

    im(:,:,nZ-minZ+1) = imRotate(xMin:xMax,yMin:yMax);
    
    fprintf(1, '.');
end

end