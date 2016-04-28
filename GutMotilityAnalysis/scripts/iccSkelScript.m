%% Skeleton Script for skeletonizing images of icc stains
% Should I do image normalization (with the histogram, etc)?

wt = imread('100615 wt sib phox2bGFP Elavl AcTub Ano1 d6 z2-mid-max.tif');
ret = imread('100615 ret phox2bGFP Elavl AcTub Ano1 d6 z2-mid-ve-max.tif');

figure; imshow(wt);
figure; imshow(ret);

%% Initialize ROI, first image set
imRowsROI = 154:410;
imColsROI = 362:612;

figure; imshow(wt(imRowsROI,imColsROI,:));
figure; imshow(ret(imRowsROI,imColsROI,:));

%% Histogram Equalization (is ret dimmer?)
threshPower = 2;
wtBoolG = squeeze(wt(imRowsROI,imColsROI,1));
wtBoolGHistEq = histeq( wtBoolG, 256 );
wtThresh = graythresh(wtBoolGHistEq);
wtThresh = 1-(1-wtThresh)^threshPower;
wtBool = im2bw(wtBoolGHistEq, wtThresh);

retBoolG = squeeze(ret(imRowsROI,imColsROI,1));
retBoolGHistEq = histeq( retBoolG, 256 );
retThresh = graythresh(retBoolGHistEq);
retThresh = 1-(1-retThresh)^threshPower;
% retThresh = wtThresh;
retBool = im2bw(retBoolGHistEq, retThresh);

figure;imshow(wtBool,[]);
figure;imshow(retBool,[]);

% Perform Skeletonization
NDilate = 3;
NErode = NDilate;

wtOpen = bwmorph( wtBool, 'open' );
retOpen = bwmorph( retBool, 'open' );

% wtClose = bwmorph( wtBool, 'close' );
% retClose = bwmorph( retBool, 'close' );

wtDilateClose = bwmorph(wtOpen, 'dilate', NDilate);
wtDilateClose = bwmorph(wtDilateClose, 'erode', NErode);
retDilateClose = bwmorph(retOpen, 'dilate', NDilate);
retDilateClose = bwmorph(retDilateClose, 'erode', NErode);

wtSkel = bwmorph(wtDilateClose, 'skel', Inf);
retSkel = bwmorph(retDilateClose, 'skel', Inf);

wtImage = zeros( size(wtBoolG,1), size(wtBoolG,2), 3 );
wtImage(:,:,1) = double(wtBoolG)/double(max(wtBoolG(:)));
wtImage(:,:,2) = wtSkel;

retImage = zeros( size(retBoolG,1), size(retBoolG,2), 3 );
retImage(:,:,1) = double(retBoolG)/double(max(retBoolG(:)));
retImage(:,:,2) = retSkel;

figure;imshow(wtImage,[]);
figure;imshow(retImage,[]);

%% Use same threshold (is ret more sparse than wt?)
threshPower=3;

bothThresh = graythresh(wtBoolG);
bothThresh = 1-(1-bothThresh)^threshPower;

wtBool = im2bw(wtBoolG, bothThresh);
retBool = im2bw(retBoolG, bothThresh);

sparseWTBool = zeros(size(wtBool,1),size(wtBool,2));
sparseWTBoolArea = zeros(size(wtBool,1),size(wtBool,2));
sparseRetBool = zeros(size(retBool,1),size(retBool,2));

wtBoolIRM = imregionalmax( wtBool );
retBoolIRM = imregionalmax( retBool );

retRP = regionprops(retBoolIRM,'all');
wtRP = regionprops(wtBoolIRM,'all');

% Generate sparse images for ret
for i=1:size(retRP,1)
    tempPos = round([retRP(i).Centroid]);
    sparseRetBool( tempPos(2), tempPos(1) ) = 1;
end

% Randomly generate sparse images for wt
randomizedWTBoolNums = randperm(size(wtRP,1));
for i=1:size(retRP,1) % This is supposed to be retRP
    tempPos = round([wtRP(randomizedWTBoolNums(i)).Centroid]);
    sparseWTBool( tempPos(2), tempPos(1) ) = 1;
end

% Generate sparse images for wt based on size of puncta
[~, wtRPAreaIndices] = sort([wtRP.Area],2,'descend');
for i=1:size(retRP,1) % This is supposed to be retRP
    tempIndex = wtRPAreaIndices(i);
    tempPos = round([wtRP(tempIndex).Centroid]);
    sparseWTBoolArea( tempPos(2), tempPos(1) ) = 1;
end

% wtSparse = zeros( size(wtBoolIRM,1), size(wtBoolIRM,2), 3 );
% wtSparse(:,:,1) = double(wtBoolG)/double(max(wtBoolG(:)));
% wtSparse(:,:,2) = sparseWTBool;
% figure;imshow(wtSparse,[]);

% retSparse = zeros( size(retBoolIRM,1), size(retBoolIRM,2), 3 );
% retSparse(:,:,1) = double(retBoolG)/double(max(retBoolG(:)));
% retSparse(:,:,2) = sparseRetBool;
% figure;imshow(retSparse,[]);

% wtSparseA = zeros( size(wtBoolIRM,1), size(wtBoolIRM,2), 3 );
% wtSparseA(:,:,1) = double(wtBoolG)/double(max(wtBoolG(:)));
% wtSparseA(:,:,2) = sparseWTBoolArea;
% figure;imshow(wtSparseA,[]);

NDilate = 7;
N = 0;
SE = strel('disk',NDilate,N);
sparseRetOpen = imdilate( sparseRetBool, SE);
sparseWTOpen = imdilate( sparseWTBool, SE);
sparseWTOpenArea = imdilate( sparseWTBoolArea, SE);

wtSkelSparse = bwmorph(sparseWTOpen, 'skel', Inf);
wtSkelSparseArea = bwmorph(sparseWTOpenArea, 'skel', Inf);
retSkelSparse = bwmorph(sparseRetOpen, 'skel', Inf);

wtSparse = zeros( size(wtBoolIRM,1), size(wtBoolIRM,2), 3 );
wtSparse(:,:,1) = double(wtBoolG)/double(max(wtBoolG(:)));
wtSparse(:,:,2) = wtSkelSparse;
figure;imshow(wtSparse,[]);

retSparse = zeros( size(retBoolIRM,1), size(retBoolIRM,2), 3 );
retSparse(:,:,1) = double(retBoolG)/double(max(retBoolG(:)));
retSparse(:,:,2) = retSkelSparse;
figure;imshow(retSparse,[]);

wtSparseA = zeros( size(wtBoolIRM,1), size(wtBoolIRM,2), 3 );
wtSparseA(:,:,1) = double(wtBoolG)/double(max(wtBoolG(:)));
wtSparseA(:,:,2) = wtSkelSparseArea;
figure;imshow(wtSparseA,[]);