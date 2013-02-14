%refineSegNeutrophil: For a given course segmentation of neutrophils refine
%the segmentation. The bulk of segmentation of neutrophils will be done in
%this program, since the course segmentation has almost no false positives
%(regions mistakenly identified as neutrophils).

function [intensityInfo] = refineSegNeutrophil(fileDir, imDir, minS, maxS, movieInfo,...
    getIntensityInfo)


nNeut = 1;

if(getIntensityInfo)
    %Counter for intensityInfo
    nI = 1;
end

for nS = minS:maxS
  
    %Load in course segmentation
    saveDir = [fileDir, filesep, 'seg_', num2str(nS), '.mat'];
    loadVar = load(saveDir, 'imSeg', 'neutPos');
    
    imSeg = loadVar.imSeg;
    neutPos = loadVar.neutPos;
    
    numReg = size(neutPos,1);
    
    %Counter to identify new regions as we segment the image
    newReg = numReg+1;
    
    %Get bounding box so that we can crop down each of these regions.
    rp = regionprops(imSeg, 'BoundingBox');
    
    %Load in entire image stack
    thisImBase = [imDir, filesep, 'Scan_', num2str(nS), filesep,...
            'region_1', filesep, '488nm', filesep, 'pco'];
    im = zeros(2160,2560,75);
    for nZ=1:75
        fN = [thisImBase num2str(nZ-1), '.png'];
        imIn(:,:,nZ) = imread(fN);
    end
    imIn = double(imIn);
    
    
    
    %Get features of each segmented neutrophil-will be used to classify,
    %and potentially further segment each of these regions.
    segFeat = getSegFeat(imSeg, imIn,neutPos, rp);
    
    
    displaySeg=true;
    if(displaySeg==true)
        %Masks for individual neutrophils when we segment them
        regMaskPerimAll = zeros(size(imSeg,1), size(imSeg,2));
        regMask2PerimAll = zeros(size(imSeg,1), size(imSeg,2));
        
        %Display full image region, but with the neutrophil of interest
        %highlighted
        mIm = max(imIn,[],3);
        %Remove the time stamp
        mIm(1:20,1:300) = 0;
        mIm = mat2gray(mIm);
        
        close all;
        hFig = figure; drawnow
        set(hFig, 'Position', [450 612 239 252])
        imshow(mIm,[0 0.1]);
        hold on
        
        maxInten = 0.1;
        hS =imshow(regMaskPerimAll,[0 maxInten]);
        set(hS, 'AlphaData', regMaskPerimAll);
        
        hP = imshow(regMask2PerimAll,[0 maxInten]);
        set(hP, 'AlphaData', regMask2PerimAll);
    end
    
    for nR=1:numReg
        xMin = rp(nR).BoundingBox(1); xMin = max([1 floor(xMin)]);
        yMin = rp(nR).BoundingBox(2); yMin = max([1, floor(yMin)]);
        zMin = rp(nR).BoundingBox(3); zMin = max([1, floor(zMin)]);
        
        xMax = xMin + rp(nR).BoundingBox(4); xMax = min([size(imSeg,2), xMax]);
        yMax = yMin + rp(nR).BoundingBox(5); yMax = min([size(imSeg,1), yMax]);
        zMax = zMin + rp(nR).BoundingBox(6); zMax = min([size(imSeg,3), zMax]);
        
        regSeg = imSeg(yMin:yMax,xMin:xMax,zMin:zMax)==nR;
        
        im = zeros(size(regSeg));
        
        for nZ=zMin:zMax
            %            fN = [thisImBase num2str(nZ-1), '.png'];
            %           imIn = imread(fN);
            im(:,:,nZ-zMin+1) = imIn(yMin:yMax,xMin:xMax,nZ);
        end
        
        displaySeg = true;
        
        if(displaySeg==true)
           regMaskPerimAll(:) = 0;
           regMask2PerimAll(:) = 0;
           
            regMask= max(regSeg,[],3);
            regMaskPerim = bwperim(regMask);
            
            regMaskPerimAll(yMin:yMax,xMin:xMax) = regMaskPerim;
            
            maxInten = 0.1;
            %hS =imshow(max(mIm(:))*regMaskPerimAll,[0 maxInten]);
            set(hS, 'CData', max(mIm(:))*regMaskPerimAll);
            set(hS, 'AlphaData', regMaskPerimAll);
       
            otsuT = graythresh(max(im,[],3));
            regMask2Perim = bwperim(max(im,[],3)>otsuT);
            regMask2Perim = bwmorph(regMask2Perim, 'dilate');
            regMask2PerimAll(yMin:yMax,xMin:xMax) = regMask2Perim;
            %hP = imshow(max(mIm(:))*regMask2PerimAll,[0 maxInten]);
            set(hP, 'CData', max(mIm(:))*regMask2PerimAll);
            set(hP, 'AlphaData', regMask2PerimAll);
            
            
            if(getIntensityInfo)
               prompt = 'Enter the number of neutrophils in the field of view, or 0 to ignore';
               numlines = 1;
               defaultanswer = {'1'};
               name = 'Neutrophil number';
               answer = inputdlg(prompt, name, numlines, defaultanswer);
               answer = answer{1};
               answer = str2num(answer);
               
               bin = 100:200:60000;
               intensityInfo(nI).hist = hist(double(im(:)),bin);
               intensityInfo(nI).numNeut = answer;
               
               inten = cumsum(neutInten(nS).hist.*bin);
               
               
               nI = nI+1;
            end
        end
    %    updatedSeg = segmentFunc(im, regSeg, segVal);
    
    imNeut = double(im).*double(regSeg);
    imNeut = imNeut(imNeut>500);
    totInten(nNeut) = sum(imNeut);
    nNeut  = nNeut+1;
    end
    
    %figure; hist(totInten,30);
   
    %pause
    %close all
nS
end






end

function segFeat = getSegFeat(imSeg, imIn,neutPos,rp)
numReg = size(neutPos,1);
for nR = 1:numReg
    xMin = rp(nR).BoundingBox(1); xMin = max([1 floor(xMin)]);
    yMin = rp(nR).BoundingBox(2); yMin = max([1, floor(yMin)]);
    zMin = rp(nR).BoundingBox(3); zMin = max([1, floor(zMin)]);
    
    xMax = xMin + rp(nR).BoundingBox(4); xMax = min([size(imSeg,2), xMax]);
    yMax = yMin + rp(nR).BoundingBox(5); yMax = min([size(imSeg,1), yMax]);
    zMax = zMin + rp(nR).BoundingBox(6); zMax = min([size(imSeg,3), zMax]);
    
    regSeg = imSeg(yMin:yMax,xMin:xMax,zMin:zMax)==nR;
    
    im = zeros(size(regSeg));
    im = imIn(yMin:yMax,xMin:xMax,zMin:zMax);
    
end

end
%Segmentation protocol for resegmenting a region 
function updatedSeg = segmentFunc(im, regSeg, segVal)



end