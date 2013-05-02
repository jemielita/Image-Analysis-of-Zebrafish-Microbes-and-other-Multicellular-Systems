%countSingleBacteria: Count the numbe of single bacteria in this region
%using a wavelet-based filtering scheme. Several features of the predicted
%spots will be calculated, allowing post-filtering of the spots to remove
%ones that were incorrectly labelled.
%
% AUTHOR: Matthew Jemielita
%
% spotLoc = countSingleBacteria(im, spotFeatures, colorNum, param)
%

function spotLoc = countSingleBacteria(im, spotFeatures, colorNum, param)

%Loading in filtering parameters
%minObjSize = spotFeatures.minSize;
%maxObjSize = spotFeatures.maxSize;

minThresh = 100;
maxThresh = 200;

%imSeg = zeros(size(im), 'uint8');
imSeg = zeros(size(im), 'double');
maskAll = zeros(size(im), 'uint8');
% Filter image using wavelet filter
fprintf(1, 'Filtering image and segmenting.');
for nZ=1:size(im,3)
   [mask,thisFrame] = spotDetector(double(im(:,:,nZ)));
   mask = uint8(mask);
   mask(thisFrame>maxThresh) =1;
   mask(thisFrame>minThresh) = mask(thisFrame>minThresh)+1;
   
   maskAll(:,:,nZ)= mask;
   imSeg(:,:,nZ) = thisFrame;
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

spotLoc = regionprops(imSeg>200, imSeg, 'Centroid', 'Area', 'MeanIntensity', 'BoundingBox');
spotLoc([spotLoc.Area]<500)  = [];
% Linking together regions
fprintf(1, 'Linking together 3d regions:');
numR = sum(imSeg(:));
numRprev = 0;
while(numRprev ~= numR)

    for i = 2:size(im,3)-1
        [r,c] = find(imSeg(:,:,i-1)+imSeg(:,:,i+1)>2);
        
        %Find regions that overlap with
        thisPlane = imSeg(:,:,i);
        bw = bwselect(thisPlane,c,r,4);
        thisPlane(bw) = 2;
        imSeg(:,:,i) = thisPlane;       
    end
    
    numRprev = numR;
    numR = sum(imSeg(:));
    fprintf(1, '.');
end
fprintf(1, 'done!\n');

%Get properties of each of the identified bacteria
bw = imSeg==2;
spotLoc = regionprops(bw, im, 'Centroid', 'Area', 'MeanIntensity', 'BoundingBox');

%Calculate eccentricity from 3d projections
labelM = bwlabeln(bw);
uniqL = unique(labelM(labelM>0));
for nL = 1:length(uniqL)
   thisL = uniqL(nL);
   maxL = max(labelM==thisL,[],3);
   ecc = regionprops(maxL, 'Eccentricity');
   spotLoc(thisL).Eccentricity = ecc.Eccentricity;
end



end