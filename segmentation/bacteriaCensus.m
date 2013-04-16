%bacteriaCensus: Estimate the number of bacteria in the gut of a fish at a
%given moment in time.
%
% AUTHOR: Matthew Jemielita, April 16, 2013


function [] = bacteriaCensus()


%% Load in the images that were filtered using the wavelet-based spot
%detector.

%Hard coded for now, but will laod in
nR = 1;
nS = 18;

fileDir = 'F:\gutSegmentationTest';

fileName = ['Scan_', num2str(nS), '_reg', num2str(nR), '.mat'];

temp = load(fileName);
im = temp.imDenoised;

%% Clean up the image and do a threshold-based segmentation

%Apply gut mask


im(im<0) = 0;
%Filter out small objects
minObjSize = 400; %Objects that are likely not bacteria
maxObjSize = 10000; %Objects that are likely clumps of bacteria

%For doing hysteresis thresholding
minThresh = 800;
maxThresh = 1000; %How can we provide a more robust estimate of this threshold?

imSeg = zeros(size(im), 'uint8');
imSeg(im>maxThresh) = 2;
imSeg(im>minThresh) = 1;

numR = sum(imSeg(:));
numRprev = 0;

%Remove small regions from each plane
for nS=1:size(im,3)
    mask = bwareaopen(imSeg(:,:,nS)>0, minObjSize);
    thisIm = imSeg(:,:,nS);
    thisIm(~mask) = 0;
    imSeg(:,:,nS) = thisIm;
end

% Linking together regions
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


rProp = regionprops(bw, 'Centroid', 'Area');


%% Plot values if desired

plotVal= true;

if(plotVal==true)
   figure; imshow(max(im,[],3), [0 1000]);
   
   hold on
   cM = rand(length(rProp),3);
   for i=1:length(rProp)
      plot(rProp(i).Centroid(1), rProp(i).Centroid(2), 'o', 'Color', [1 0 0],...
          'MarkerSize', 10);
      
       
   end
end

end