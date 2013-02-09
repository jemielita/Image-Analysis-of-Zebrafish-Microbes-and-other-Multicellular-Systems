minS=1;
maxS= 75;

for nS=1:120
    disp(['Segmenting scan ', num2str(nS)]);
    fileDir = ['Scans', filesep,'scan_',num2str(nS), filesep,'region_1', ...
        filesep, '488nm'];
    
    for i=minS:maxS
        imName = [fileDir, filesep, 'pco', num2str(i-1), '.png'];
        im(:,:,i) = imread(imName);
    end
    
   
    imMax = max(im,[],3);
    [imSeg, neutPos] = segmentNeutrophil(im);
    
    segMax = max(imSeg,[],3);
    segMax = segMax>0;
    save(['seg_',num2str(nS)], 'segMax','imSeg', 'neutPos', 'imMax', '-v7.3');
    
    
end
    


%Calculate the intensity of each of these regions
for nS=1:120
    load(['seg_', num2str(nS), '.mat']);
    
    fileDir = ['Scans', filesep,'scan_',num2str(nS), filesep,'region_1', ...
        filesep, '488nm'];
    
    for i=minS:maxS
        imName = [fileDir, filesep, 'pco', num2str(i-1), '.png'];
        im(:,:,i) = imread(imName);
    end
    neutPosStruct = regionprops(imSeg, im,'WeightedCentroid', 'Area', 'MeanIntensity');

    for i=1:length(neutPosStruct)
    neutPos(i,1:3) = neutPosStruct(i).WeightedCentroid(:);
    neutPos(i,4) = neutPosStruct(i).Area*neutPosStruct(i).MeanIntensity;
    end

    nS
    save(['segI_', num2str(nS), '.mat'], 'neutPos');
end
    
    
    

for nS=1:120
        load(['seg_', num2str(nS), '.mat']);
for i=1:size(neutPos,1)
    movieInfo(nS).xCoord(i,1) = neutPos(i,1);
    movieInfo(nS).yCoord(i,1) = neutPos(i,2);
    movieInfo(nS).zCoord(i,1) = 6.1538*neutPos(i,3);
    movieInfo(nS).amp(i,1) = neutPos(i,4);
    
    
    movieInfo(nS).xCoord(i,2) = 0;
    movieInfo(nS).yCoord(i,2) = 0;
    movieInfo(nS).zCoord(i,2) = 0;
    movieInfo(nS).amp(i,2) = 0;
end
nS
end


%Save tiff files of MIP
for nS=2:120
   load(['seg_',num2str(nS), '.mat']);
   imwrite(uint16(imMax), ['mip', sprintf('%03d', nS-1),'.tif']);
end


%Plot the tracked data
startend = [1 118];
dragtailLength = 3;
saveMovie = 1;
movieName = 'test';
filterSigma = 0;
classifyGaps = 0;
highlightES  = 1;
showRaw = 0;
imageRange = [1, 2160; 1, 2560];
onlyTracks = 1;
classifyLft = 2;
diffAnalysisRes = [];
intensityScale = 1;
colorTracks = 0;
firstImageFile = [];
dir2saveMovie = pwd;
minLength = 5;
plotFullScreen = 1;
movieType = 'avi';
overlayTracksMovieNew(tracksFinal,startend,dragtailLength,...
    saveMovie,movieName,filterSigma,classifyGaps,highlightES,showRaw,...
    imageRange,onlyTracks,classifyLft,diffAnalysisRes,intensityScale,...
    colorTracks,firstImageFile,dir2saveMovie,minLength,plotFullScreen,...
    movieType)

    


for nS=1:120
    load(['seg_', num2str(nS), '.mat'], 'segMax');
    sM(:,:,nS) = bwperim(segMax);
nS
end