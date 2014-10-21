%countSingleBacteria: Count the number of single bacteria in this region
%using a wavelet-based filtering scheme. Several features of the predicted
%spots will be calculated, allowing post-filtering of the spots to remove
%ones that were incorrectly labelled.
%
% AUTHOR: Matthew Jemielita
%
% spotLoc = countSingleBacteria(im, spotFeatures, colorNum, param)
%

function spotLoc = countSingleBacteria(im, spotFeatures, colorNum, param, varargin)

if(nargin==5)
    %For mapping the spot locations onto positions down the length of the
    %gut.
    gutMask = varargin{1};
    
    %Replace elements in im as we go-to avoid creating new array in memory
    inPlace = false;
   
else
    inPlace = false;
end

%Loading in filtering parameters
%minObjSize = spotFeatures.minSize;
%maxObjSize = spotFeatures.maxSize;

%Turning all the nan into 0's for this step of the analysis: We should do
%our spot detection stuff at the last step of our analysis.
im(isnan(im)) = 0;

minThresh = 100;

%mlj: maxThresh = 200 is decent for green, maxThresh = 30 should work for
%red-we'll see tomorrow
if(isempty(spotFeatures))
    maxThresh = 400;
else
    maxThresh = spotFeatures.intenThresh(colorNum);
end

%maskAll = zeros(size(im), 'uint8');
% Filter image using wavelet filter
fprintf(1, 'Filtering image and segmenting.');

thisFrame = zeros(size(im,1), size(im,2));
tic;

height = size(im,1);
width = size(im,2);

im = imresize(im,0.5);
if(inPlace==false)
    imSeg = zeros(size(im), 'double');
    bw = zeros(size(im),'double');
end

for nZ=1:size(im,3)
    
    thisFrame(:) = 0;
    %Find minimum and maximum extent of the region that needs to have spots
    %located in.
    thisMask = im(:,:,nZ)==250;
    
    if(sum(thisMask(:))==0)
        %Note sure why we're seeing blank frames-should look at load
        %3dvolume code-this gets around it though.
         continue;
    end
    xMin = find(sum(thisMask,1)>0, 1,'first');
    xMax = find(sum(thisMask,1)>0, 1, 'last');
    yMin = find(sum(thisMask,2)>0, 1, 'first');
    yMax = find(sum(thisMask,2)>0, 1, 'last');
    
    %Using the new fast c++ code that Ryan wrote.
    imIn = double(im(yMin:yMax,xMin:xMax,nZ));
    
    switch inPlace
        case false
            imSeg(yMin:yMax, xMin:xMax,nZ) = cv.spotDetectorFast(imIn,4);
            
            %Clean up small regions
           %imSeg(yMin:yMax, xMin:xMax,nZ) = bwareaopen(imSeg(yMin:yMax, xMin:xMax,nZ)>maxThresh, 10);
            %imSeg(yMin:yMax, xMin:xMax,nZ) = imclearborder(imSeg(yMin:yMax, xMin:xMax,nZ)==1);

            bw(yMin:yMax, xMin:xMax,nZ) = bwareaopen(imSeg(yMin:yMax, xMin:xMax,nZ)>maxThresh, 10);
            bw(yMin:yMax, xMin:xMax,nZ) = imclearborder( bw(yMin:yMax, xMin:xMax,nZ)==1);
        case true
            
            im(yMin:yMax, xMin:xMax,nZ) = cv.spotDetectorFast(imIn,4);
    end
    %Using a median filter on each frame to remove salt and pepper noise
    %thisFrame(yMin:yMax, xMin:xMax) = medfilt2(thisFrame(yMin:yMax, xMin:xMax), [5 5]);
    
    fprintf(1, '.');
    
end
imSeg = imresize(imSeg,  [height, width]);
im = imresize(im, [height, width]);
bw = imresize(bw, [height, width]);

fprintf(1, '\n');

%Dilate the mask so that we don't count spots on the edge
%mlj: This should all be done within the c++ code above.
gutExt = max(gutMask,[],3)==0;
se = strel('disk', 20);
gutExt = imdilate(gutExt, se);

for nZ=1:size(im,3)
   temp = im(:,:,nZ);
   temp(gutExt)= 0;
   im(:,:,nZ) = temp;
   
   temp = imSeg(:,:,nZ);
   temp(gutExt) = 0;
   imSeg(:,:,nZ) = temp;
   
   temp = bw(:,:,nZ);
   temp(gutExt) = 0;
   bw(:,:,nZ) = temp;
end

%% Find information about each of these spots and their background

%Get label matrix
bw = bwlabeln(bw);
bwBkg = bw;

%Calculate properties of the original image for each of the found spots
xlist = 0:50:3000;
prop = regionprops(bw, im, 'Centroid', 'Area', 'MeanIntensity', 'BoundingBox', 'MaxIntensity', 'MinIntensity', 'WeightedCentroid','PixelIdxList');

%Calculate properties of the wavelet transformed image
propWv = regionprops(bw, imSeg, 'Centroid', 'Area', 'MeanIntensity', 'MaxIntensity', 'MinIntensity', 'WeightedCentroid','PixelIdxList');

%Calculate properites of the background around each spot
spotLoc = [];
for i=1:length(prop)
    
    bb = round(prop(i).BoundingBox);
    bb(4:5) = bb(4:5)+10;
    xMin = max([1, bb(1)]);
    xMax = min([size(im,2),bb(1) + bb(4)]);
    
    yMin = max([1, bb(2)]);
    yMax = min([size(im,1), bb(2)+bb(5)]);
    
    zMin = max([1, bb(3)]);
    zMax = min([size(im,3),bb(3)+bb(6)]);
    
    temp = bw( yMin:yMax,xMin:xMax,zMin:zMax);
    
    %While we've made this sub-image calculate some properites of the 2d
    %plane
    prop2d = regionprops(max(temp,[],3)==i, 'Eccentricity', 'MajorAxisLength', 'MinorAxisLength', 'Area','ConvexArea');
    spotLoc(i).MajorAxisLength = prop2d.MajorAxisLength;
    spotLoc(i).MinorAxisLength = prop2d.MinorAxisLength;
    spotLoc(i).Area2d = prop2d.Area;
    spotLoc(i).convexArea = prop2d.ConvexArea;
    %Subtract away the original spot and any regions that might belong to
    %other particles
    bwBkg(yMin:yMax,xMin:xMax,zMin:zMax) = i*(imdilate(temp==i, ones(8,8,8))-(temp>0));    
end

bwBkg(bwBkg<0) = 0;
propBkg = regionprops(bwBkg, im, 'Centroid', 'Area', 'MeanIntensity', 'BoundingBox', 'MaxIntensity', 'MinIntensity', 'WeightedCentroid','PixelIdxList');

%Construct intensity histograms for each of these found spots
histIm = arrayfun(@(x)hist(im(prop(x).PixelIdxList),xlist),1:length(prop), 'UniformOutput', false); 
histWv = arrayfun(@(x)hist(imSeg(propWv(x).PixelIdxList),xlist),1:length(propWv), 'UniformOutput', false); 
histBkg = arrayfun(@(x)hist(im(propBkg(x).PixelIdxList),xlist),1:length(prop), 'UniformOutput', false); 

for i=1:length(prop)
    spotLoc(i).wvlMean = propWv(i).MeanIntensity;
    spotLoc(i).objMean = prop(i).MeanIntensity;
   
    spotLoc(i).wvlStd = std(imSeg(propWv(i).PixelIdxList));
    spotLoc(i).objStd = std(im(prop(i).PixelIdxList));
    
    spotLoc(i).totInten = prop(i).MeanIntensity.*prop(i).Area;
    spotLoc(i).totIntenWv = propWv(i).MeanIntensity.*propWv(i).Area;
    spotLoc(i).volume = prop(i).Area;
    %Background info
    spotLoc(i).bkgMean = propBkg(i).MeanIntensity;
    spotLoc(i).stdMean = std(im(propBkg(i).PixelIdxList));
    
    spotLoc(i).Centroid = prop(i).Centroid;
    %Run a k-s test comparing pixel intensities to estimated background
     %intensities
     if(sum(histIm{i}).*sum(histBkg{i}) ~=0)
         [~,spotLoc(i).ksTest] = kstest2(histIm{i}./sum(histIm{i}),histBkg{i}./sum(histBkg{i}));
     else
         spotLoc(i).ksTest = -1;
     end
end
    
%     
% spotLoc
% hgram.s = hist(im(label==1),x);
% hgram.bkg = hist(im(label==0),x);
% 
% hgram.s = hgram.s/sum(hgram.s);
% hgram.bkg = hgram.bkg/sum(hgram.bkg);
% 
% rProp.objMean = mean(im(label==1));
% rProp.bkgMean = mean(im(label==0));

%Calculate properties of the background for each of the spots

%Construct an estimate of the background for each of the spots
% for i=1:length(spotLoc)
%     spotLoc(i).BoundingBox = round(prop(i).BoundingBox);
%     
%     bb = spotLoc(i).BoundingBox;
%     bb(4:5) = bb(4:5)+10;
%     xMin = max([1, bb(1)]);
%     xMax = min([size(im,2),bb(1) + bb(4)]);
%     
%     yMin = max([1, bb(2)]);
%     yMax = min([size(im,1), bb(2)+bb(5)]);
%     
%     zMin = max([1, bb(3)]);
%     zMax = min([size(im,3),bb(3)+bb(6)]);
%     
%     temp = bw(yMin:yMax,xMin:xMax,zMin:zMax);
%     
%     %Subtract away the original spot and any regions that might belong to
%     %other particles
%     bwBkg(yMin:yMax,xMin:xMax,zMin:zMax) = i*(imdilate(temp==i, ones(8,8,8))-(temp>0));
%     
% end


%%
% 
% if(inPlace==false)
%     spotLoc = regionprops(imSeg==1, im, 'Centroid', 'Area', 'MeanIntensity', 'BoundingBox', 'MaxIntensity', 'MinIntensity', 'WeightedCentroid');
% else
%     spotLoc = regionprops(im>maxThresh, im, 'Centroid', 'Area', 'MeanIntensity', 'BoundingBox');
% uniend

%Remove super small spots
if(~isempty(spotLoc))
    spotLoc([spotLoc.Area2d]<=10) = [];
else
    spotLoc = []; %Need something to pass to the next part of our pipeline.
end

end