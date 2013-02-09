%Segment a 3D volume of neutrophils, with the ultimate goal of tracking
%their motion over time.

function [imSeg, neutPos] = segmentNeutrophil(im)

%% Parameters for segmentation

%Threshold for region extents
minThresh= 800;
maxThresh = 1000;

smallestVolume = 1000;
smallestArea = 200;
%These values should come from the statistics of several neutrophils

%% Setting up volume to segment
%Get mask for pixels above the maximum threshold
imSeg = im>maxThresh;
imSeg = 2*imSeg + double(im>minThresh);

numR = sum(imSeg(:));
numRprev = 0;


%% Remove small regions from each plane

for nS=1:size(im,3)
   imSeg(:,:,nS) = imSeg(:,:,nS).*bwareaopen(imSeg(:,:,nS)>0, smallestArea);  
end

%% Linking together regions
fprintf(1, 'Linking together 3d regions:');

while(numRprev ~= numR)

    for nS = 2:size(im,3)-1
        [r,c] = find(imSeg(:,:,nS-1)+imSeg(:,:,nS+1)>2);
        
        %Find regions that overlap with
        thisPlane = imSeg(:,:,nS);
        bw = bwselect(thisPlane,c,r,4);
        thisPlane(bw) = 2;
        imSeg(:,:,nS) = thisPlane;       
    end
    
    numRprev = numR;
    numR = sum(imSeg(:));
    fprintf(1, '.');
end
fprintf(1, 'done!\n');

%% Remove small volume regions
imSeg(imSeg==1) = 0;
imSeg = bwareaopen(imSeg,smallestVolume);

%% Display the segmented region
% figure;
% for i=1:size(im,3)
% imshow(overlayIm(imadjust(im(:,:,i)),imSeg(:,:,i), ''));pause(1)
% end

%% Convert imSeg to label matrix;
imSeg = bwlabeln(imSeg);

%% Find center of mass of each region
neutPosStruct = regionprops(imSeg, im,'WeightedCentroid', 'Area', 'MeanIntensity');

%convert to nx3 matrix, where (n,:) gives the x,y,z position
%each identified neutrophil.
neutPos = zeros(length(neutPosStruct),3);
for i=1:length(neutPosStruct)
    neutPos(i,1:3) = neutPosStruct(i).WeightedCentroid(:);
    neutPos(i,4) = neutPosStruct(i).Area*neutPosStruct(i).MeanIntensity;
end


end

