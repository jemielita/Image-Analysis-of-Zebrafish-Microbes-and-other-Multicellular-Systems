%countSingleBacteria: Count the numbe of single bacteria in this region
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
maxThresh = 200;

if(inPlace==false)
    imSeg = zeros(size(im), 'double');
end

maskAll = zeros(size(im), 'uint8');
% Filter image using wavelet filter
fprintf(1, 'Filtering image and segmenting.');
for nZ=1:size(im,3)
   [~,thisFrame] = spotDetector(double(im(:,:,nZ)));
   
   
   %mask = uint8(mask);
   %mask(thisFrame>maxThresh) =1;
   %mask(thisFrame>minThresh) = mask(thisFrame>minThresh)+1;
   
  % maskAll(:,:,nZ)= mask;
  if(inPlace==false)
      imSeg(:,:,nZ) = thisFrame;
  else
      im(:,:,nZ) = thisFrame;
  end
  % imSeg(:,:,nZ)= mask;
   %Processing this z-slice
%    thisFrame(thisFrame<0) = 0;
%    mask = zeros(size(thisFrame));
%    mask(thisFrame>maxThresh) = 1;
%    mask(thisFrame>minThresh) = mask(thisFrame>minThresh)+1;
%    
%    maskMinObj = bwareaopen(mask==2, minObjSize);
%    mask(~maskMinObj) = 0;
%    
%
% bin = 0:10:max(thisFrame(:));
% hVal = hist(thisFrame(:), bin);
% ind = rosin(hVal);
% 
% thresh(nZ)= bin(ind);


%imSeg(:,:,nZ) = thisFrame;

%   imSeg(:,:,nZ) = uint8(mask);
   fprintf(1, '.');

end
fprintf(1, '\n');

if(inPlace==false)
    spotLoc = regionprops(imSeg>maxThresh, imSeg, 'Centroid', 'Area', 'MeanIntensity', 'BoundingBox');
else
    spotLoc = regionprops(im>maxThresh, im, 'Centroid', 'Area', 'MeanIntensity', 'BoundingBox');
end



end