%segmentGutMIP: high level function for segmenting the MIP image of the gut
%
% USAGE segMask = segmentGutMIP(im, segmentType, scanNum, colorNum)
%
% INPUT im: maximum intensity image of the gut.
%       segmentType: string giving the type of segmentation to use
%              'otsu': intensity level thresholding with some morphological
%              bell and whistles
%              'estimated background': find segmented region based on our
%              estimate of the background signal intensity from our coarse
%              analysis.
% OUTPUT segMask: binary mask with segmented regions given by 1s.
%
% AUTHOR: Matthew Jemielita, Aug 15, 2013

function segMask = segmentGutMIP(im, segmentType,scanNum, colorNum,param)

switch lower(segmentType.Selection)
    case 'otsu'
        segMask = otsuSegment(im);
    case 'estimated background'
        
        segMask = mipSegmentSeries(im, scanNum, colorNum, param, segmentType);
        
    case 'intenthresh'
        segMask = intensitySegment(im, scanNum, colorNum, param);
        
    case 'spot'
        segMask = spotSegment(param, colorNum, scanNum, imSize);
        
    case 'final seg'
        inputVar = load([param.dataSaveDirectory filesep 'bkgEst' filesep 'fin_' num2str(scanNum) '_' param.color{colorNum} '.mat']);
        segMask = inputVar.segMask;
    
end


end

function segMask = mipSegmentSeries(im, scanNum, colorNum, param, segmentType)

spotRad = 20;
segMask = showBkgSegment(im, scanNum, colorNum, param, segmentType.bkgOffset);
intenMask = intensitySegment(im, scanNum, colorNum, param);
spotMask = spotSegment(param, colorNum, scanNum, size(segMask),spotRad);




fileName = [param.dataSaveDirectory, filesep, 'bkgEst', filesep, 'fin_', num2str(scanNum), '_', param.color{colorNum}, '.mat'];

inputVar = load(fileName, 'segMask');
segMask =inputVar.segMask;
%segMask = graphCutSegment(im, segMask, spotMask, intenMask);


segMask = removeSmallObj(segMask, spotMask);


end

function segMask = graphCutSegment(im, segMask, spotMask,intenMask)

%Remove regions that don't have high intensity spots in it or single
%bacteria
cc = bwconncomp(segMask);
label = labelmatrix(cc);

ul = unique(label(:)); ul(ul==0) =[];

for i=1:length(ul)
    thisR = label==ul(i);
    thisR = thisR+intenMask;
    if(max(thisR(:))==1)
        %Then check to see if there are no spots in this region
        thisR = (label==ul(i))+spotMask;
        if(max(thisR(:))==1)
           label(label==ul(i)) = 0; 
        end
    end
    
end

segMask = label>0;

segMask = (segMask+spotMask)>0;



%% Further segment data using graph cut approach

cc = bwconncomp(segMask);

maskTot = zeros(size(segMask));
imMaster = im;
imMaster(~segMask) = NaN;
for i=1:cc.NumObjects
    fprintf(1, '.');
    mask = zeros(size(segMask));
   mask(cc.PixelIdxList{i}) = 1;
   [mask2, im, range] = minBoundBox(mask, imMaster);
   [~,maskM,~] = minBoundBox(mask, intenMask);
   mask = mask2;
   

   %To generate a histogram of potential intensities from source and
   %sink,dilate mask by a given amount and use that as the cutoff between
   %the two regions
   se = strel('disk',10);
   
   maskD = imdilate(maskM,se);
   
   [sourceHistProb, sourceHistVal]= hist(double(im(maskD)),50);
   
   [sinkHistProb, sinkHistVal] = hist(double(im(~maskD)),50);
   intenEst{1,1} = sinkHistProb;
   intenEst{1,2} = sinkHistVal;
   
   intenEst{2,1} = sourceHistProb;
   intenEst{2,2} = sourceHistVal;
   
   finMask = graphCut(im, maskM, ~maskD, intenEst);
   maskTot(range(1):range(3), range(2):range(4)) = double(finMask)+double(maskTot(range(1):range(3), range(2):range(4)));
   

%    %Now seeing how well we can do at our segmentation
%    imshow(im,[]);
%    alphamask(bwperim(mask), [1 0 0]);
%    alphamask(bwperim(finMask), [0 1 0]);
%    %Get histogram of pixel intensities in mask
   fprintf(1,'.');
  
   
end
fprintf(1,'\n');

segMask = maskTot>0;

end


function segMask = removeSmallObj(segMask, spotMask)
%Remove small objects that don't overlap with found spots

cc = bwconncomp(segMask);

for i=1:cc.NumObjects
   
    %Minimum size cutoff for graph cut
   if(length(cc.PixelIdxList{i})>1000)
       continue;
   end
   [x,y] = ind2sub(size(segMask), cc.PixelIdxList{i});
   
    bw = bwselect(spotMask, y, x, 4);
    if(sum(bw(:))==0)
       %No overlap between spot detection and graph cut-remove this small region
       segMask(cc.PixelIdxList{i}) = 0;        
    end
    
end

end


function segMask = otsuSegment(im)
im = mat2gray(im);
gT = graythresh(im(im~=0));

segMask = im > gT;

end

function segMask = intensitySegment(im, scanNum, colorNum, param)

colorInten = [1000,500];

segMask = im>colorInten(colorNum);

%Force everything outside the gut to be 0, regardless of intensity.
poly = param.regionExtent.polyAll{scanNum};
imSize = param.regionExtent.regImSize{1};
gutMask = poly2mask(poly(:,1), poly(:,2), imSize(1), imSize(2));
segMask(~gutMask) = 0;

end



function segMask = spotSegment(param, colorNum, scanNum, imSize,spotRad)

%% Remove regions around found bacterial spots
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

xyz = [rProp.CentroidOrig];
xyz = reshape(xyz,3,length(xyz)/3);

xyz = xyz(1:2,:);

%Go through each of these spots and add a circle to to the mask around the
%spot

segMask = makeCircleMask(imSize, xyz, spotRad);

end