%bacteriaCountTimeSeries: Process spot detection code further to 
function [numBac, bacProp] =  bacteriaCountTimeSeries(param, varargin)

%Variables for doing in-place moving of the analysis.
scanNum = 'all';
inputSpotLoc = 'none';

switch nargin
    case 1
        %Values found that minimize f-score for particular manually
        %annotated gut region.
        cullProp.radCutoff(1) = 40; %Cutoff in the horizontal direction
        cullProp.radCutoff(2) = 3;
        cullProp.minRadius = 2;
        cullProp.minInten = 229;
        cullProp.minArea = 1;
        
        
        analysisType = 'firstpass';
    case 2
        analysisType = varargin{1};
        
        %Values found that minimize f-score for particular manually
        %annotated gut region.
        cullProp.radCutoff(1) = 40; %Cutoff in the horizontal direction
        cullProp.radCutoff(2) = 3;
        cullProp.minRadius = 2;
        cullProp.minInten = 229;
        cullProp.minArea = 1;
    case 3
        analysisType = varargin{1};
        cullProp = varargin{2};
        if(strcmp(cullProp, 'defaultCullProp'))
            cullProp.radCutoff(1) = 40; %Cutoff in the horizontal direction
            cullProp.radCutoff(2) = 3;
            cullProp.minRadius = 2;
            cullProp.minInten = 229;
            cullProp.minArea = 1;
        end
        
    case 5
        analysisType = varargin{1};
        cullProp = varargin{2};
        if(strcmp(cullProp, 'defaultCullProp'))
            cullProp.radCutoff(1) = 40; %Cutoff in the horizontal direction
            cullProp.radCutoff(2) = 3;
            cullProp.minRadius = 2;
            cullProp.minInten = 229;
            cullProp.minArea = 1;
        end
        
        %Load in found bacterial spots from our analysis pipeline
        scanNum = varargin{3};
        inputSpotLoc = varargin{4};
        
end

%Scan parameters
scanParam = load([param.dataSaveDirectory filesep 'analysisParam.mat']);
scanParam = scanParam.scanParam;


if(strcmp(scanNum, 'all'))
    minS = 1;
    maxS = param.expData.totalNumberScans;
else
    minS = scanNum;
    maxS = scanNum;
end

numColor = length(scanParam.color);




cd(param.dataSaveDirectory);
if(~isdir([param.dataSaveDirectory filesep 'singleBacCount']))
    fprintf(1, 'Making directory to save single bacteria');
    mkdir([param.dataSaveDirectory filesep 'singleBacCount']);
    fprintf(1, '.\n');
end
bacSaveDir = [param.dataSaveDirectory filesep 'singleBacCount'];


%Find out where the single bacteria count code is saved
analysisParameters = load([param.dataSaveDirectory filesep 'analysisParam.mat']);
analysisTypeList = analysisParameters.analysisType;
analysisNum = cellfun(@(x)strcmp(x, 'spotDetection'), {analysisTypeList.name});
analysisNum = find(analysisNum==1);

colorList = analysisParameters.scanParam.color;
param.centerLineAll = analysisParameters.param.centerLineAll;


%colorList = {'488nm', '568nm'};

switch analysisType 
    case 'all'
        
    case 'firstpass'
        %First pass of the data
        cullProp.firstPass = true;
        bacCountFirstPass;
        
    case 'updateGutPosNumber'
        %Update the position of the bacteria along the length of the gut
        %1-D projection-done by default in firstpass
        updateGutPosNumber();
end

    function [] = bacCountFirstPass()
        %Directory to save single bacteria count analysis

        for nS=minS:maxS
            
            fprintf(1, ['Processing scan ' num2str(nS) '...\n']);
            rPropAll = cell(length(colorList),1);
            for nC=1:length(colorList)

            
            %Load data
            %spotLoc = load(['BacteriaCount', num2str(nS), '.mat']);
            %spotLoc = spotLoc.spotLoc;
            
            %Load data-produced by analyzeGutTimeSeries
            %if(nC==2)
        loadType = 1;
        
            
            if(strcmp(inputSpotLoc, 'none'))
        
                if(loadType==1)
                    spotLoc = load(['singleCountRaw', filesep, 'Analysis_Scan', num2str(nS), '.mat']);
                else
                    spotLoc = load(['Analysis_Scan', num2str(nS), '.mat']);
                end
        %spotLoc = spotLoc{nC, analysisNum};
        
        
            %The current indexing is screwy-need to fix this up.
            %spotLoc = spotLoc{1};
            
            %else
          %     spotLoc = load(['bacCount_analysis_all_highCutoff', filesep, 'Analysis_Scan', num2str(nS), '.mat']);
            %end
                        spotLoc = spotLoc.regFeatures;
                
                     %   spotLoc = spotLoc{nC,3};
                     %  spotLoc = spotLoc{3}; %Why do we need this?
            else
                spotLoc = inputSpotLoc;
            end
                   
            numBac{nS} = [];
           
            numReg = size(spotLoc{nC,3},1);
            
            
            for nR=1:numReg
                %Again, the indexing is somewhat screwy.
             %   if(nC==1)
               % rProp = spotLoc{1}{nR}{analysisNum,nC};
              %  else
               %    rProp = spotLoc{1}{nR}{1}; 
                %end
              %  rProp = spotLoc{nR}{nC};
           if(loadType==2)
               rProp = spotLoc{nR}{3,nC};
           elseif (loadType ==1)
               %rProp = spotLoc{1};
               rProp = spotLoc{nC,3}{nR};
           end
                [gutMask, xOffset, yOffset, gutMaskReg] = getMask(param, nS, nR, 'cutmask');
                
                rProp = cullFoundBacteria(rProp, gutMask, cullProp,xOffset, yOffset);
          
                rProp = findBacLoc(rProp, gutMaskReg,param,nR,nS);
                rProp = findGutRegion(rProp, nS,param);
                rProp = getRotatedIndices(param,nR,nS,rProp,nC);

                numBac{nS} = [numBac{nS}, length(rProp)];
                
                bacProp{nS,nR} = rProp;
                if(~isempty(rProp))
                    rPropAll{nC} = [rPropAll{nC} ; rProp];
                end
            end
            
            fprintf(1, '.');
            end
        
        %greenBug = load([bacSaveDir filesep 'bacCount' num2str(nS) '.mat']);
        %greenBug = greenBug.rProp{1};
        %rProp = cell(2,1);
        %rProp{1} = greenBug;
       % rProp{2} = rPropAll{1};
        %Save first pass of analysis
        rProp = rPropAll;
        fileName = [bacSaveDir filesep 'bacCount' num2str(nS) '.mat'];
        save(fileName, 'rProp');
        
        end
        fprintf(1,'\n');
        
    end

    function [] = updateGutPosNumber()
             %Directory to save single bacteria count analysis
        for nS=minS:maxS
            
            fprintf(1, ['Processing scan ' num2str(nS) '...\n']);
            rPropAll = cell(length(colorList),1);
            
            cL = param.centerLineAll{nS};
            for nC=1:length(colorList)
            
            %Load data
            %spotLoc = load(['BacteriaCount', num2str(nS), '.mat']);
            %spotLoc = spotLoc.spotLoc;
            
            %Load data-produced by analyzeGutTimeSeries
            %spotLoc = load(['Analysis_Scan', num2str(nS), '.mat']);
            %spotLoc = spotLoc.regFeatures;
          %  spotLoc = spotLoc{nC, analysisNum};
            %The current indexing is screwy-need to fix this up.
            %spotLoc = spotLoc{1};
            fileName = [bacSaveDir filesep 'bacCount' num2str(nS) '.mat'];
            
            spotLoc = load(fileName);
            rProp = spotLoc.rProp;
            cL = param.centerLineAll{nS};
            
            for nB =1:length(rProp{nC})
               pos = rProp{nC}(nB).Centroid(1:2);
               [~,ind] = min((cL(:,1)-pos(1)).^2 + (cL(:,2)-pos(2)).^2);
              
            end
               
           
            %numReg = size(spotLoc,1);numReg = 2;
            %for nR=1:numReg
                %Again, the indexing is somewhat screwy.
                
               % rProp = spotLoc{1}{nR}{analysisNum,nC};
                                rProp = spotLoc{1}{nR}{nC};

                [gutMask, xOffset, yOffset, gutMaskReg] = getMask(param, nS, nR, 'cutmask');
                
                rProp = cullFoundBacteria(rProp, gutMask, cullProp,xOffset, yOffset);
                
                rProp = findBacLoc(rProp, gutMaskReg,param,nR,nS);

                rProp = getRotatedIndices(param,nR,nS,rProp);

                numBac{nS} = [numBac{nS}, length(rProp)];
                
                bacProp{nS,nR} = rProp;
                
                rPropAll{nC} = [rPropAll{nC} ; rProp];
            %end
            
            fprintf(1, '.');
            end
            
        %Save updated gut position number
        rProp = rPropAll;
        fileName = [bacSaveDir filesep 'bacCount' num2str(nS) '.mat'];
        save(fileName, 'rProp');
        
        end
        fprintf(1,'\n'); 
        
    end
end

function [gutMask, xOffset, yOffset, gutMaskReg] = getMask(param, nS,nR, loadType,nC)

switch loadType
    
    case 'indivreg'
        allZ = param.regionExtent.Z;
        allZ = allZ>0;
        
        maxZ = sum(allZ,1);
        
        height = param.regionExtent.regImSize{1}(1);
        width = param.regionExtent.regImSize{1}(2);
        
        thisRegion = param.regionExtent.XY{1};
        xOutI = thisRegion(nR,1);
        xOutF = thisRegion(nR,3)+xOutI-1;
        
        yOutI = thisRegion(nR,2);
        yOutF = thisRegion(nR,4)+yOutI -1;
        
        xInI = thisRegion(nR,5);
        xInF = xOutF - xOutI +xInI;
        
        yInI = thisRegion(nR,6);
        yInF = yOutF - yOutI +yInI;
        
        %Make gut masks
        
        polyX = param.regionExtent.polyAll{nS}(:,1);
        polyY = param.regionExtent.polyAll{nS}(:,2);
        gutMask = poly2mask(polyX, polyY, height, width);
        thisMask = gutMask(xOutI:xOutF, yOutI:yOutF);
        
        %Find smallest cropping region
        xMin = find(sum(thisMask,2)~=0,1,'first');
        xMax = find(sum(thisMask,2)~=0, 1, 'last');
        
        yMin = find(sum(thisMask,1)~=0, 1, 'first');
        yMax = find(sum(thisMask,1)~=0, 1, 'last');
        
        
        xOffset = param.regionExtent.indivReg(nS, nR, 1);
        yOffset = param.regionExtent.indivReg(nS, nR,2);
    case 'cutmask'
        gutMask = load([param.dataSaveDirectory filesep 'masks' filesep 'mask_' num2str(nS) '.mat']);
        gutMask = gutMask.gutMask{nR};
        xOffset = 1;
        yOffset = 1;
        
        %To deal with MIP gut segmentation code
        if(iscell(gutMask))
           gutMask = gutMask{nC};
        end
        
        gutMaskReg = gutMask;
        %Make a solid mask from this mask
        gutMask = sum(gutMask,3)>0;
        
        
end


end

function rProp = findBacLoc(rProp, gutMaskReg,param,nR,nS)
%Find the location of the found spots down the length of the gut (from our
%1-D line projection code).
%Also find the location of each of these found bacteria in the original
%reference frame of the images.

%figure; imshow(max(gutMaskReg,[],3));
%hold on

cutVal = load([param.dataSaveDirectory filesep 'masks' filesep 'cutVal.mat']);
cutVal = cutVal.cutValAll;
cutVal = cutVal{nS};


%Find the location down the gut of different points 
%Required offset to get correct location of the spots in the 1-D
%projection.
minCut = cutVal{nR,1}(1);
for nB = 1:length(rProp)
   xy = [rProp(nB).Centroid(2), rProp(nB).Centroid(1)];
   xy = round(xy);
 
   val = 0;
   for i =1:size(gutMaskReg,3)
      val = max([val, gutMaskReg(xy(1), xy(2),i)]);  
   end
  rProp(nB).sliceNum = minCut-1+val;
  
end

        
end

function rProp = findGutRegion(rProp, nS,param)
%Find which region of the gut these bacteria are in:
% 1: Between EJ and the ~ end of the bulb reigon
% 2: Between ~ end of the bulb region and the beginning of the
% autofluorescent region (this is by far the least well defined region).
% 3: Somewhere inside the region containing autofluorescent cells in the
% posterior of the gut.
% 4: After the autofluorescent cells, but before the ~ end of the gut.
% 5: Outside the gut.

for nB =1:length(rProp)
   rProp(nB).gutRegion  = find(rProp(nB).sliceNum > param.gutRegionsInd(nS,:),1, 'last');
end

end

function rProp = getRotatedIndices(param,cutNumber,scanNum, rProp,nC)
%Find the rotated and original indices for the rotated cut region and add
%in a centroid location in the original reference frame.

%Code lifted from constructRotRegion.m

cutVal = load([param.dataSaveDirectory filesep 'masks' filesep 'cutVal.mat']);
cutVal = cutVal.cutValAll{scanNum};

thisCut = cell(4,1);
thisCut{1} = cutVal{cutNumber,1};
thisCut{2} = cutVal{cutNumber,2};
thisCut{3} = cutVal{cutNumber,3};
thisCut{4} = cutVal{cutNumber,4};

centerLine = param.centerLineAll{scanNum};

%colorNum = find(strcmp(param.color, imVar.color));
indReg = find(thisCut{2}==1);

%Get z extent that we need to load in
zList = param.regionExtent.Z(:, indReg);
zList = zList>0;
zList = sum(zList,2);
minZ = find(zList~=0, 1, 'first');
%maxZ = find(zList~=0, 1, 'last');
%finalDepth = maxZ-minZ+1;

%Get mask of gut
height = param.regionExtent.regImSize{1}(1);
width = param.regionExtent.regImSize{1}(2);
polyX = param.regionExtent.polyAll{scanNum}(:,1);
polyY = param.regionExtent.polyAll{scanNum}(:,2);
gutMask = poly2mask(polyX, polyY, height, width);

dataType = 'uint8';
imOrig = nan*zeros(height, width, dataType);

%Size of pre-cropped rotated image
imRotate = zeros(thisCut{4}(1), thisCut{4}(2), dataType);

%Final image stack
xMin =thisCut{4}(5); xMax = thisCut{4}(6);
yMin = thisCut{4}(3); yMax = thisCut{4}(4);
finalHeight = xMax-xMin+1;
finalWidth = yMax-yMin+1;

%im = nan*zeros(finalHeight, finalWidth, finalDepth, dataType);

%Crop down the mask to the size of the cut region
maxCut = size(cutVal,1);

%MlJ: temporary cludge
%thisCut{1}(2) = min([thisCut{1}(2), size(centerLine,1)-1]);
%MLj: remove above line

cutPosInit = getOrthVect(centerLine(:,1), centerLine(:,2), 'rectangle', thisCut{1}(2));
cutPosFinal = getOrthVect(centerLine(:,1), centerLine(:,2), 'rectangle', thisCut{1}(1));

pos = [cutPosFinal(1:2,:); cutPosInit(2,:); cutPosInit(1,:)];

cutMask = poly2mask(pos(:,1), pos(:,2), height, width);
cutMask = cutMask.*gutMask;

%Load in the entire volume
%baseDir = [param.directoryName filesep 'Scans' filesep];
%Going through each scan
%scanDir = [baseDir, 'scan_', num2str(imVar.scanNum), filesep];

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

[gutMask, ~, ~, ~] = getMask(param, scanNum, cutNumber, 'cutmask',nC);
% figure; 
% imshow(gutMask); title(['Rot image: ' num2str(scanNum)]);
% hold on
% for i=1:length(rProp)
%     plot(rProp(i).Centroid(1), rProp(i).Centroid(2), '*');
% end

%Get coordinates in original reference frame
xy = [rProp.Centroid];
xy = reshape(xy, 3, length(xy)/3);
xy = xy(1:2, :);
xy = xy';
xy = round(xy);

ind = sub2ind(size(gutMask),xy(:,2), xy(:,1));
%origInd = oI(ind);

%In case finalI doesn't include all points, find points that have minimum
%distance to found indices
%[xyInd(:,1), xyInd(:,2)] = ind2sub(size(gutMask), finalI);

indR = [];
for i=1:length(ind)
 [~,thisInd] = min(sqrt( (x-xy(i,2)).^2 + (y-xy(i,1)).^2));
 %thisInd
 %   indR(i) = oI(find(finalI==ind(i)));   
 %[thisInd, find(finalI==ind(i))]
 
 indR(i) = oI(thisInd);
end

if(~isempty(indR))
    [xyOr(:,1), xyOr(:,2)] = ind2sub(size(cutMask), indR);
end

for i=1:length(rProp)
   rProp(i).CentroidOrig(1:2) = [xyOr(i,2), xyOr(i,1)]; 
   
   %z location for the original image
   rProp(i).CentroidOrig(3) = rProp(i).Centroid(3) +minZ-1;
end

% figure; 
% imshow(cutMask); title('Original image');
% hold on
% for i=1:length(rProp)
%     plot(rProp(i).CentroidOrig(1), rProp(i).CentroidOrig(2), '*');
% end
% pause(0.5)
% close all

end





