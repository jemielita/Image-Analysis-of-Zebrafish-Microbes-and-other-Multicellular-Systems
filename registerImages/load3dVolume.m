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
%        imStack = load3dVolume(param, imVar, 'crop', cropRect);
% INPUT: -param: parameters associated with this scan
%        -imVar structure containing the following elements
%           imVar.color = color (ex. '488nm', '568nm');
%           imvar.zNum = if empty load in the entire z-stack. If single
%           value load in just that plane. If contains two values then load
%           in the z frames in that range. Currently variable z-load in is
%           only supported for loadTypes of 'crop' or 'polygonRegion'.
%           imVar.scanNum = which scan number to load in.
%        -loadType: 'single': User must provide a cut number which gives
%                   which cut region to load in. In addition the field
%                   param.cutRegion must be set. (mlj: I don't think this 
%                   is true anymore...should check)The function calcOptimalCut
%        must be used to find this cut.
%        'multiple': User must provide a cut number which gives which cut
%        region to load in.
%        'crop': User must provide a cropping rectangle (cropRect), which
%        gives the location of the particular region to load in. If there
%        are two values load in all images within the range of these
%        values. The crop rectangle will be rounded to the nearest integer before being applied.
%        Currently the error checking on the inputs isn't great so
%        be careful!
%        'polygonRegion': User must provide a polygonal region (poly) to load
%        from. This polygon is used to calculate a minimum bounding box
%        around this polygon and everthing in this box is loaded. Pixels
%        that fall outside the polygon, but are still within this bounding
%        box are set to NaN.
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
elseif nargin==5
    dataType = varargin{2};
    
    
elseif nargin==4
    dataType = 'uint16';
    if(strcmp(loadType, 'crop'))
        cropRect = varargin{1};
        cropRect = round(cropRect);
    end
    if(strcmp(loadType, 'polygonRegion'))
       regPoly = varargin{1}; 
    end
    
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
    case 'crop'
        imStack = loadCroppedRegion(param, imVar, cropRect);
    case 'polygonRegion'
        imStack = loadPolygonRegion(param, imVar, regPoly);
        
end



%Deal with -1 put in to find regions outside gut
imStack(imStack==-1) = nan;
end

%Load in all images in a one region
    function im = loadSingleRegion(param, imVar, regNum, dataType)
        %Allocating a huge array for the entire image stack
        colorNum =  find(strcmp(param.color, imVar.color));
        
        %Getting a list of all the image slices to load in.        
        [zList,totalZ, ~] = getZRange(param, 'region', regNum);
        
        
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
            
            [whichType, imFileName] = whichImageFileType(scanDir, regNum, param, imNum,colorNum);
            switch whichType
                case 1
                    try
                        im(:,:,nZ)= imread(imFileName,'PixelRegion', {[xInI xInF], [yInI yInF]});
                    catch
                        disp('This image doesnt exist-fix up your code!!!!');
                    end
                case 2
                    inputImage = imread(imFileName);
                    im(:,:,nZ) = inputImage(xInI:xInF, yInI:yInF);
            end
                    
        end
        
        %Load in mask showing variable maximum z-heights for different parts of the
        %gut-used to remove surface cells
        if(isfield(param.regionExtent, 'redozCropBox'))
            redoCrop = param.regionExtent.redozCropBox;
        else 
            redoCrop = 1;
        end
        if(isfield(param.regionExtent, 'zCropBox')&& redoCrop==1)
            
            zCrop = param.regionExtent.zCropBox{imVar.scanNum};
            
            %Find the parts of these masks that lie within the region that we're
            %loading in
            zCropMask = zeros(size(im,1), size(im,2));
            zCropMaskDir = zeros(size(im,1), size(im,2));
            thisMask = zeros(size(zCropMask));
            
            for i=1:length(zCrop)
                thisMask(:) = 0;
                cXI = max(zCrop{i}{2}(2)-xOutI,1);
                cXF = min(zCrop{i}{2}(4)+cXI, size(im,1));
                
                cYI = max(zCrop{i}{2}(1)-yOutI, 1);
                cYF = min(zCrop{i}{2}(3) +cYI, size(im,2));
                
                cXI = round(cXI);cXF = round(cXF); cYI = round(cYI); cYF = round(cYF);
                thisMask(cXI:cXF, cYI:cYF) = zCrop{i}{4};
                
                %Save location of mask and whether it's a top or bottom
                %mask.
                zCropMask(thisMask~=0) = thisMask(thisMask~=0);
                
                switch zCrop{i}{3}
                    case 'top'
                        zCropMaskDir(thisMask~=0) = 1;
                    case 'bottom'
                        zCropMaskDir(thisMask~=0) = -1;
                end
                
                
            end
            
            cropZ = unique(zCropMask(:));
            cropZ(cropZ==0) = [];
            
            
            for nZ=1:length(cropZ)
                minZ = param.regionExtent.Z(cropZ(nZ),regNum);
                if(minZ==-1)
                    return
                end
                %Convoluted way of cropping top or bottom regions.
                if(sum(zCropMaskDir(zCropMask==cropZ(nZ)))>0)
                    for thisZ=minZ+1:size(im,3)
                        temp = im(:,:,thisZ);
                        temp(zCropMask==cropZ(nZ)) = nan;
                        im(:,:,thisZ) = temp;
                    end
                else
                    for thisZ=1:minZ
                        temp = im(:,:,thisZ);
                        temp(zCropMask==cropZ(nZ)) = nan;
                        im(:,:,thisZ) = temp;
                    end
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
%     zList = param.regionExtent.Z(:, indReg);
%     zList = zList>0;
%     zList = sum(zList,2);
%     minZ = find(zList~=0, 1, 'first');
%     maxZ = find(zList~=0, 1, 'last');
%     finalDepth = maxZ-minZ+1;
    [zList, finalDepth, zRange] = getZRange(param, 'multipleRegions', indReg);
    minZ = zRange(1); maxZ = zRange(2);
    
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
            
            %Find out how we've stored the images
            [whichType, imFileName] = whichImageFileType(scanDir, regNum, param, imNum,colorNum);
            
            try
                
                switch whichType
                    case 1
                        %Load tiff image
                        
                        switch dataType
                            case 'uint16'
                                imOrig(xOutI:xOutF, yOutI:yOutF) = imOrig(xOutI:xOutF, yOutI:yOutF) +...
                                    uint16(imread(imFileName,'PixelRegion', {[xInI xInF], [yInI yInF]}));
                            case 'double'
                                imOrig(xOutI:xOutF, yOutI:yOutF) = imOrig(xOutI:xOutF, yOutI:yOutF) +...
                                    double(imread(imFileName,'PixelRegion', {[xInI xInF], [yInI yInF]}));
                        end
                        
                        
                    case 2
                        %Load png image
                        inputImage = imread(imFileName);
                        
                        switch dataType
                            case 'uint16'
                                
                                imOrig(xOutI:xOutF, yOutI:yOutF) = imOrig(xOutI:xOutF, yOutI:yOutF) +...
                                    uint16(inputImage(xInI:xInF, yInI:yInF));
                            case 'double'
                                imOrig(xOutI:xOutF, yOutI:yOutF) = imOrig(xOutI:xOutF, yOutI:yOutF) +...
                                    double(imread(inputImage(xInI:xInF, yInI:yInF)));
                        end
                        
                        
                end
                
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
        
    end
    fprintf(1, '\n');
    
    end
    
    
    
    function im = loadCroppedRegion(param, imVar, cropRect)
    colorNum =  find(strcmp(param.color, imVar.color));
   
    %Get regions to load in
    [regList, ~] = regionOverlap(param, cropRect);
    
    if(isempty(regList))
        fprintf(2, 'Region is empty! Returning an empty image');
        im = [];
    end
    
    
    %Get z-range for this list of regions
    [zList, depth, zRange] = getZRange(param, 'multipleRegions', regList);
    minZ = zRange(1); maxZ = zRange(2);
    
    %Construct image array of appropriate size
    height = cropRect(4)+1;
    width = cropRect(3)+1;
    
    im = zeros(height, width, depth);
    
    baseDir = [param.directoryName filesep 'Scans' filesep];
    %Going through each scan
    scanDir = [baseDir, 'scan_', num2str(imVar.scanNum), filesep];
    
    %Go through z list step by step
    for nZ=1:minZ:maxZ
        for i = 1:length(regList)
            regNum = regList(i);
            imNum = param.regionExtent.Z(nZ, regNum);
            if(imNum==-1)
                %This region doesn't exist at this particular z-plane
                continue
            end
            [whichType, imFileName] = whichImageFileType(scanDir, regNum, param, imNum,colorNum);
            
            %Get the extent of this region
            [xInI, xInF, yInI, yInF, xOutI, xOutF, yOutI, yOutF] = getXYrange(param, colorNum, regNum, height,width,cropRect);
            
            switch whichType
                case 1
                    %Load tiff image
              %      try
              
              try
                  im(xOutI:xOutF,yOutI:yOutF,nZ)=...
                      double(imread(imFileName,'PixelRegion', {[xInI xInF], [yInI yInF]}));
              catch
                  disp('This image doesnt exist-fix up your code!!!!');
              end
                    
                    
                case 2
                    try
                        %Load png image
                        inputImage = imread(imFileName);
                        im(:,:,nZ) = inputImage(xInI:xInF, yInI:yInF);
                    catch
                        disp('This image doesnt exist-fix up your code!!!!');
                    end
            end
            
        
        end
    end
%     
%     for nR=1:length(regList)
%         regNum = regList(nR);
%         %Getting a list of all the image to load in
%         [zList, totalZ,~]  = getZRange(param, 'region', regNum);
%         if(isempty(zList))
%             fprintf(2, 'No valid z positions for this found bug! Screwy...\n');
%             fprintf(2, 'Returning all-zero matrix.\n');
%             
%             im = zeros(xInF-xInI+1,yInF-yInI+1,1);
%             return;
%         end
%         
%         if(~isempty(imVar.zNum))
%             if(length(imVar.zNum)==1)
%                 zList = imVar.zNum(1);
%             elseif(length(imVar.zNum)==2)
%                 ind = find(zList>=imVar.zNum(1) & zList<=imVar.zNum(2));
%                 zList = zList(ind);
%             end
%         end
% 
%         %Get the extent of this region
%         [xInI, xInF, yInI, yInF, xOutI, xOutF, yOutI, yOutF] = getXYrange(param, colorNum, regNum,cropRect);
%         %Make sure that the region extents don't go beyond the range of
%         %this image
%         
%         im = zeros(xInF-xInI+1,yInF-yInI+1, length(zList));
%         
%         baseDir = [param.directoryName filesep 'Scans' filesep];
%         %Going through each scan
%         scanDir = [baseDir, 'scan_', num2str(imVar.scanNum), filesep];
%         
%         for nZ = 1:totalZ
%             imNum = zList(nZ);
%             
%             [whichType, imFileName] = whichImageFileType(scanDir, regNum, param, imNum,colorNum);
%             switch whichType
%                 case 1
%                     %Load tiff image
%                     try
%                         im(:,:,nZ)= imread(imFileName,'PixelRegion', {[xInI xInF], [yInI yInF]});
%                     catch
%                         disp('This image doesnt exist-fix up your code!!!!');
%                     end
%                     
%                 case 2
%                     try
%                         %Load png image
%                         inputImage = imread(imFileName);
%                         im(:,:,nZ) = inputImage(xInI:xInF, yInI:yInF);
%                     catch
%                         disp('This image doesnt exist-fix up your code!!!!');
%                     end
%             end
%             
%             
%         end
%         
%     end
    
    end
    
    function im = loadPolygonRegion(param, imVar, regPoly)
    
    %Find the minimum bounding box for this region
    minVal = min(regPoly);
    maxVal = max(regPoly);
    
    cropRect = [minVal(1), minVal(2), maxVal(1)-minVal(1)+1, maxVal(2)-minVal(2)+1];
    
    
    %Using this cropping rectangle, load in the region
    im = loadCroppedRegion(param, imVar, cropRect);
    
    %Removing stuff outside the bounding box
    regPoly(:,1) = regPoly(:,1)-minVal(1);
    regPoly(:,2) = regPoly(:,2)-minVal(2);
    mask = poly2mask(regPoly(:,1), regPoly(:,2), size(im,1), size(im,2));
    mask = repmat(mask,[1,1,size(im,3)]);
    
    im(~mask) = 0;
    end
    
    
    function [xInI, xInF, yInI, yInF, xOutI, xOutF, yOutI, yOutF] ...
        = getXYrange(param, colorNum, regNum,height, width,varargin)
    
    switch nargin
        case 5
            
        case 6
            cropRect = varargin{1};
            
        otherwise
            
    end
    %Get the appropriate locations of pixels in the output image
    pos(1) = param.regionExtent.XY{colorNum}(regNum,1);
    pos(2) = pos(1) + param.regionExtent.XY{colorNum}(regNum,3);
    
    posC(1) = cropRect(2); posC(2) = cropRect(2)+cropRect(4);
    
    
    xOutI = 1;
    l = cropRect(4);
    xOutF = xOutI+l;
    
    if(posC(1)<pos(1))
        xOutI = xOutI + (pos(1)-posC(1));
        l = l -(pos(1)-posC(1));
    end
    
    if(posC(2)>=pos(2))
        %xOutF = xOutF - (posC(2)-pos(2));
        l = l-(posC(2)-pos(2))-1;
        xOutF = max([xOutI+1, xOutI+l]);
    end
    
    xInI = param.regionExtent.XY{1}(regNum,5)+(posC(1)-pos(1));
    xInI = max([1, xInI]);
    
    xInF = max([xInI +l, xInI+l]); %Annoying hack-something is slightly buggy in our code here
    
    
    
    %Get the appropriate locations of pixels in the output image
    %Y Range
    pos(1) = param.regionExtent.XY{colorNum}(regNum,2);
    pos(2) = pos(1) + param.regionExtent.XY{colorNum}(regNum,4);
    
    posC(1) = cropRect(1); posC(2) = cropRect(1)+cropRect(3);
    yOutI = 1;
    
    l = cropRect(3);
    yOutF = yOutI+l;
    
    
    if(posC(1)<pos(1))
        yOutI = yOutI + (pos(1)-posC(1));
        l = l -(pos(1)-posC(1));
        l = max([l, 1]);
        yOutF = yOutI +l;
    end
    
    if(posC(2)>=pos(2))
        %yOutF = yOutF -(posC(2)-pos(2));
        
        l = l-(posC(2)-pos(2))-1;
        l = max([l, 1]);
        yOutF = max([yOutI+l, yOutI+1]);
        
    end
    
    yInI = param.regionExtent.XY{1}(regNum,6)+(posC(1)-pos(1));
    
    yInI = max([1, yInI]);
    yInF = max([yInI+l, yInI+1]); %Annoying hack-something is slightly buggy in our code here
    
    if((xInF-xInI)~=(xOutF-xOutI) || (yInF-yInI)~=(yOutF-yOutI))
       fprintf(2, 'Input and output ranges do not match!\n');
    %   pause;
       return
    end
    
    if(yInF>param.regionExtent.XY{colorNum}(regNum,4)+1||xInF>param.regionExtent.XY{colorNum}(regNum,3)+1)
       fprintf(2, 'Input out of range for image!\n');
     %  pause;
       return;
    end
    
    if(xOutI<1||xInI<1 ||yInI<1||yOutI<1)
       fprintf(2, 'Negative values!\n');
      % pause
       return
    end
    
    if(xOutI>xOutF||xInI>xInF||yOutI>yOutF||yInI>yInF)
       fprintf(2, 'Wrong order!\n');
       %pause
       return
    end
    
    end

