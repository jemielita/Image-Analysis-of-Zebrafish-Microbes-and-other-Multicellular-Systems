%bacteriaCensus: Estimate the number of bacteria in the gut of a fish at a
%given moment in time.
%
% AUTHOR: Matthew Jemielita, April 16, 2013


function rProp = bacteriaCensus(varargin)


%% Load in the images that were filtered using the wavelet-based spot
%detector.

switch nargin
    case 0
        %Hard coded for now, but will load in
        nR = 1;
        nS = 27;
        
        fileDir = 'F:\gutSegmentationTest';
        
        fileName = ['Scan_', num2str(nS), '_reg', num2str(nR), '.mat'];
        
        temp = load(fileName);
        im = temp.imDenoised;

    case 1
        im = varargin{1};
        plotVal = true;
    case 2
      im = varargin{1};
      plotVal = varargin{2};
        
        %Unnecessary code now
        %nS = varargin{1};
        %nR = varargin{2};
        
        %fileDir = 'F:\gutSegmentationTest';
        
        %fileName = ['Scan_', num2str(nS), '_reg', num2str(nR), '.mat'];
        
        %temp = load(fileName);
        %im = temp.imDenoised;
end


%% Clean up the image and do a threshold-based segmentation

%Apply gut mask


im(im<0) = 0;
%Filter out small objects
minObjSize = 50; %Objects that are likely not bacteria
maxObjSize = 10000; %Objects that are likely clumps of bacteria

%For doing hysteresis thresholding
minThresh = 600;
maxThresh = 800; %How can we provide a more robust estimate of this threshold?

imSeg = zeros(size(im), 'uint8');
imSeg(im>minThresh) = 1;
imSeg(im>maxThresh) = 2;

numR = sum(imSeg(:));
numRprev = 0;

%Remove small regions from each plane
for nS=1:size(im,3)
    mask = bwareaopen(imSeg(:,:,nS)==2, minObjSize);
    thisIm = imSeg(:,:,nS);
    thisIm(~mask) = 0;
    imSeg(:,:,nS) = thisIm;
end

% Linking together regions
fprintf(1, 'Linking together 3d regions:');

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

bw = imSeg==2;
rProp = regionprops(bw, im, 'Centroid', 'Area', 'MeanIntensity');

%Calculate eccentricity from 3d projections
labelM = bwlabeln(bw);
uniqL = unique(labelM(labelM>0));
for nL = 1:length(uniqL)
   thisL = uniqL(nL);
   maxL = max(labelM==thisL,[],3);
   ecc = regionProps(maxL, 'Eccentricity');
   rProp(i).eccentricity = ecc.Eccentricity;
end

%% Plot values if desired

%plotVal=true;

if(plotVal==true)
%    figure; imshow(max(im,[],3), [0 1000]);
%    
%    hold on
%    cM = rand(length(rProp),3);
%    for i=1:length(rProp)
%       plot(rProp(i).Centroid(1), rProp(i).Centroid(2), 'o', 'Color', [1 0 0],...
%           'MarkerSize', 10);
%       
%        
%    end 
      
   %Save the image with the location of each of the found spots
  % mkdir(['spot_Scan_', num2str(nS)]);
   for z=1:size(im,3)
      close all
      figure;
      imshow(im(:,:,z),[0 1000]);
      hold on
      for i=1:length(rProp)
         if(abs(rProp(i).Centroid(3)-z)<1)
             if(rProp(i).Area<100)
                 plot(rProp(i).Centroid(1), rProp(i).Centroid(2), 'o', 'Color', [1 0 0],...
                'MarkerSize', 10);
             else
                 plot(rProp(i).Centroid(1), rProp(i).Centroid(2), 'o', 'Color', [0 0 1],...
                'MarkerSize', 10);
             end
                 
         end
   
      end
      pause
     % fileName = ['spot_Scan_', num2str(nS), '_nR', num2str(nR), filesep, 'pco', num2str(z), '.tif'];
     % print('-dtiff', '-r300', fileName);
      
   end
 end

end