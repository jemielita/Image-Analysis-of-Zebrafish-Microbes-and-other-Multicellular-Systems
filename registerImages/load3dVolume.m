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
%
% AUTHOR: Matthew Jemielita, Written: June 14, 2012. Modified: July 31, 2012

function imStack = load3dVolume(param, imVar, loadType,varargin)

%% Loading in variables
switch loadType
    case 'single'
        regionNumber = varargin{1};
    case 'multiple'
        cutNumber = varargin{1}(1);
        scanNum = varargin{1}(2);
end

if nargin==6
    dataType = varargin{6};
elseif nargin==4
    dataType = 'uint16';
else 
    disp('Number of inputs must be either 4 or 6!');
    return
end

%% Load in image stack


switch loadType
    case 'single'
        imStack = loadSingleRegion(param, imVar, regionNumber, dataType);
    case 'multiple'
        imStack = loadCutRegion(param, imVar, cutNumber, scanNum,dataType);
end


%Deal with -1 put in to find regions outside gut
imStack(imStack==-1) = nan;
imStack = imStack +1;


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
im = nan*zeros(param.regionExtent.XY{colorNum}(regNum,3),...
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


%Load in mask showing variable maximum z-heights for different parts of the
%gut-used to remove surface cells 
if(isfield(param.regionExtent, 'zCropBox'))
    zCrop = param.regionExtent.zCropBox{1};
    
    %Find the parts of these masks that lie within the region that we're
    %loading in
    zCropMask = zeros(size(im,1), size(im,2));
    thisMask = zeros(size(zCropMask));
        
    for i=1:length(zCrop)
        thisMask(:) = 0;
        cXI = max(zCrop(i).pos(2)-xOutI,1);
        cXF = min(zCrop(i).pos(4)+cXI, size(im,1));
        
        cYI = max(zCrop(i).pos(1)-yOutI, 1);
        cYF = min(zCrop(i).pos(3) +cYI, size(im,2));
        
        cXI = round(cXI);cXF = round(cXF); cYI = round(cYI); cYF = round(cYF);
        thisMask(cXI:cXF, cYI:cYF) = zCrop(i).zHeight;
        zCropMask(thisMask~=0) = thisMask(thisMask~=0);
        
    end
    
    cropZ = unique(zCropMask(:));
    cropZ(cropZ==0) = [];
    
    
    for nZ=1:length(cropZ)
        minZ = param.regionExtent.Z(cropZ(nZ),regNum);
        if(minZ==-1)
            return
        end
        for thisZ=minZ+1:size(im,3)
            temp = im(:,:,thisZ);
            temp(zCropMask==cropZ(nZ)) = nan;
           im(:,:,thisZ) = temp;
        end
        
        
    end
end

end

%Load in all images in one particular cut of the gut
function im  = loadCutRegion(param, imVar, cutNumber, scanNum,dataType)

thisCut = cell(4,1);
thisCut{1} = param.cutVal{cutNumber,1};
thisCut{2} = param.cutVal{cutNumber,2};
thisCut{3} = param.cutVal{cutNumber,3};
thisCut{4} = param.cutVal{cutNumber,4};

centerLine = param.centerLineAll{scanNum};

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
polyX = param.regionExtent.polyAll{scanNum}(:,1);
polyY = param.regionExtent.polyAll{scanNum}(:,2);
gutMask = poly2mask(polyX, polyY, height, width);

imOrig = nan*zeros(height, width, dataType);

%Size of pre-cropped rotated image
imRotate = zeros(thisCut{4}(1), thisCut{4}(2), dataType);

%Final image stack
xMin =thisCut{4}(5); xMax = thisCut{4}(6);
yMin = thisCut{4}(3); yMax = thisCut{4}(4);
finalHeight = xMax-xMin+1;
finalWidth = yMax-yMin+1;

im = nan*zeros(finalHeight, finalWidth, finalDepth, dataType);

fprintf(1, 'im big');
%Crop down the mask to the size of the cut region
maxCut = size(param.cutVal,1);

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
[x,y] = ind2sub(size(imRotate), rI);

%Remove indices beyond this range
ind = [find(x<xMin); find(x>xMax); find(y<yMin); find(y>yMax)];
ind = unique(ind);
x(ind) = []; y(ind) = []; oI(ind) = []; rI(ind) = [];
x = x-xMin+1; y = y-yMin+1;
finalI = sub2ind([finalHeight, finalWidth], x,y);


for nZ=minZ:maxZ
    tic;
    imOrig(:)=-1; %Can't use nan, because then we can't add up regions-deal with minus one at the end.
    for i = 1:length(indReg)
       regNum = indReg(i);
       imNum = param.regionExtent.Z(nZ, regNum);
      
       if(imNum==-1)
           %This region doesn't exist at this particular z-plane
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
           imOrig(xOutI:xOutF, yOutI:yOutF) = imOrig(xOutI:xOutF, yOutI:yOutF) +...
               uint16(imread(imFileName{1},'PixelRegion', {[xInI xInF], [yInI yInF]}));     
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
        end
        
    end
    
    %Rotating the image by mapping to the appropriate pixels in the large
    %image stack
    im(finalI +finalHeight*finalWidth*(nZ-minZ)) = imOrig(oI);

    fprintf(1, '.');   
%toc
end


%Load in mask showing variable maximum z-heights for different parts of the
%gut-used to remove surface cells
if(isfield(param.regionExtent, 'zCropBox'))
    zCrop = param.regionExtent.zCropBox{scanNum};
    
    zCropMask = zeros(size(cutMask));
    thisMask = zCropMask;
    for i=1:length(zCrop)
        thisMask(:) = 0;
        cXI = zCrop(i).pos(2);
        cXF = zCrop(i).pos(4)+cXI;
        
        cYI = zCrop(i).pos(1)-yOutI;
        cYF = zCrop(i).pos(3) +cYI;
        
        cXI = round(cXI);cXF = round(cXF); cYI = round(cYI); cYF = round(cYF);
        thisMask(cXI:cXF, cYI:cYF) = zCrop(i).zHeight;
        zCropMask(thisMask~=0) = thisMask(thisMask~=0);
        
    end
    
    
    %Removing points outside the mask region
    zCropMask = zCropMask.*cutMask;
    
    %Get indices in the rotated
    zCropInd = zCropMask(oI);
    
    for nZ=minZ:maxZ
        ind = find(zCropInd==nZ);
        for thisZ=nZ:maxZ
            im(finalI(ind) +finalHeight*finalWidth*(nZ-minZ)) = 10000;
        end
    end
end



end

end