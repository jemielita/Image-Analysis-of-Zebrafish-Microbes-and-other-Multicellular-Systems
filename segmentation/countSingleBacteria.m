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
    inPlace = true;
   
else
    inPlace = false;
end

%Loading in filtering parameters
%minObjSize = spotFeatures.minSize;
%maxObjSize = spotFeatures.maxSize;


minThresh = 100;

%mlj: maxThresh = 200 is decent for green, maxThresh = 30 should work for
%red-we'll see tomorrow
if(isempty(spotFeatures))
    maxThresh = 30;
else
    maxThresh = spotFeatures.intenThresh(colorNum);
end


if(inPlace==false)
    imSeg = zeros(size(im), 'double');
end

%maskAll = zeros(size(im), 'uint8');
% Filter image using wavelet filter
fprintf(1, 'Filtering image and segmenting.');


thisFrame = zeros(size(im,1), size(im,2));
for nZ=1:size(im,3)
    
    thisFrame(:) = 0;
    %Find minimum and maximum extent of the region that needs to have spots
    %located in.
    thisMask = ~isnan(im(:,:,nZ));
    
    if(sum(thisMask(:))==0)
        %Note sure why we're seeing blank frames-should look at load
        %3dvolume code-this gets around it though.
         continue;
    end
    xMin = find(sum(thisMask,1)>0, 1,'first');
    xMax = find(sum(thisMask,1)>0, 1, 'last');
    yMin = find(sum(thisMask,2)>0, 1, 'first');
    yMax = find(sum(thisMask,2)>0, 1, 'last');
    
    [~,thisFrame(yMin:yMax, xMin:xMax)] = spotDetector(double(im(yMin:yMax,xMin:xMax,nZ)));
    
    %mask = uint8(mask);
    %mask(thisFrame>maxThresh) =1;
    %mask(thisFrame>minThresh) = mask(thisFrame>minThresh)+1;
    
    % maskAll(:,:,nZ)= mask;
    
    %Using a median filter on each frame to remove salt and pepper noise
    thisFrame(yMin:yMax, xMin:xMax) = medfilt2(thisFrame(yMin:yMax, xMin:xMax), [5 5]);
    
    if(inPlace==false)
        imSeg(:,:,nZ) = thisFrame;
    else
        im(:,:,nZ) = thisFrame;
        
    end
    
    fprintf(1, '.');
    
end

 fprintf(1, '\n');

if(inPlace==false)
    spotLoc = regionprops(imSeg>maxThresh, imSeg, 'Centroid', 'Area', 'MeanIntensity', 'BoundingBox');
else
    spotLoc = regionprops(im>maxThresh, im, 'Centroid', 'Area', 'MeanIntensity', 'BoundingBox');
end


end