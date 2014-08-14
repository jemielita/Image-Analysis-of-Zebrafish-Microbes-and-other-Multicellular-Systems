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
    maxThresh = 30;
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
            imSeg(yMin:yMax, xMin:xMax,nZ) = bwareaopen(imSeg(yMin:yMax, xMin:xMax,nZ)>maxThresh, 10);
            imSeg(yMin:yMax, xMin:xMax,nZ) = imclearborder(imSeg(yMin:yMax, xMin:xMax,nZ)==1);

        case true
            
            im(yMin:yMax, xMin:xMax,nZ) = cv.spotDetectorFast(imIn,4);
    end
    %Using a median filter on each frame to remove salt and pepper noise
    %thisFrame(yMin:yMax, xMin:xMax) = medfilt2(thisFrame(yMin:yMax, xMin:xMax), [5 5]);
    
   
    fprintf(1, '.');
    
end
imSeg = imresize(imSeg,  [height, width]);
im = imresize(im, [height, width]);

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
end
if(inPlace==false)
    spotLoc = regionprops(imSeg==1, im, 'Centroid', 'Area', 'MeanIntensity', 'BoundingBox', 'MaxIntensity', 'MinIntensity', 'WeightedCentroid');
else
    spotLoc = regionprops(im>maxThresh, im, 'Centroid', 'Area', 'MeanIntensity', 'BoundingBox');
end

%Remove super small spots
 spotLoc([spotLoc.Area]<=10) = [];

end