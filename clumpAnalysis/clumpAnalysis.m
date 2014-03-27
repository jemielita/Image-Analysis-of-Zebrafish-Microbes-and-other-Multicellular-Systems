%clumpAnalysis: Constrct an appropriate filter for the segmentation of
%clumps in the gut of a fish.
%
% AUTHOR: Matthew Jemielita, March 20, 2014


function [] = clumpAnalysis(scanNum, colorNum, param)

im = loadMIP(param, scanNum, colorNum);

mask = applyMIPMask(im, scanNum, param);

intenCutoff = estimateIntensityCutoff(param, scanNum, colorNum);

end

function im = loadMIP(param, scanNum, colorNum)
colorList = {'488nm', '568nm'};
im  = imread([param.dataSaveDirectory filesep 'FluoroScan_' num2str(scanNum) '_' colorList{colorNum} '.tiff']);
    
end

function mask = applyMIPMask(im, scanNum, param)
poly = param.regionExtent.polyAll{scanNum};

mask = poly2mask(poly(:,1), poly(:,2), size(im,1), size(im,2));

end


function intenCutoff = estimateIntensityCutoff(param, scanNum, colorNum)
%Load in all found bacteria for this scan/color
rProp = load([param.dataSaveDirectory filesep 'singleBacCount'...
    filesep 'bacCount' num2str(scanNum) '.mat']);
rProp = rProp.rProp{colorNum};

remBugsSaveDir = [param.dataSaveDirectory filesep 'singleBacCount' filesep 'removedBugs.mat'];
if(exist(remBugsSaveDir, 'file')==2)
   removeBugInd = load(remBugsSaveDir); 
   removeBugInd = removeBugInd.removeBugInd;
end

keptSpots = setdiff(1:length(rProp), removeBugInd{scanNum, colorNum});

rPropClassified = rProp(keptSpots);
useRemovedBugList = false;
classifierType = 'svm';
distCutoff_combRegions = false;

rProp = bacteriaCountFilter(rPropClassified, scanNum, colorNum, param, useRemovedBugList, classifierType,distCutoff_combRegions);
rProp = rProp([rProp.gutRegion]<4);

imVar.color = param.color{colorNum};
imVar.scanNum = scanNum;

displayData = false;
for ind=1:length(rProp)

rect(1) = rProp(ind).CentroidOrig(1)-20;
rect(2) = rProp(ind).CentroidOrig(2)-20;
rect(3) = 40;
rect(4) = 40;

imVar.zNum(1) = max([1,rProp(ind).CentroidOrig(3)-5]);
imVar.zNum(2) = min([rProp(ind).CentroidOrig(3)+5, max(param.regionExtent.Z(:))]);

imVar.zNum(1) = round(imVar.zNum(1));
imVar.zNum(2) = round(imVar.zNum(2));

vol = load3dVolume(param, imVar, 'crop',rect);

%As a first pass let's use a Rosin threshold to get an estimate of where to
%cut off the intensity
[h, val] = hist(double(vol(:)),40);
i = rosin(h);

intenCutoff(ind,1) = val(i); %Actual cutoff
intenCutoff(ind,2) = mean(vol(vol>val(i)));


if(displayData==true);
    subplot(2,1,1); imshow(max(vol,[],3),[]);
    subplot(2,1,2); hist(double(vol(:)),30);
    %Note: Sometimes it seems like we're not properly capturing the bacterial
    %spots-Need to look at this more closely sometime soon.
    
    
    
    %imshow(max(vol,[],3),[])
    pause(0.5)
end
 
fprintf(1, '.');
end
fprintf(1, '\n');
end

function coarseMask = coarseGutSegment(im, mask, intenCutoff)

end


function mip = getBacMIP()

end