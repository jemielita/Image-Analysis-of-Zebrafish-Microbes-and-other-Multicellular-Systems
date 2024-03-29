%saveCroppedBatch: For a given directory that has been cropped using
%multipleRegionCrop.m save the cropped region to a new directory, or
%overwrite the existing directory.
%
%USAGE: saveCroppedBatch(param, cropDir, fileType, cropType)
%       saveCroppedBatch(param, cropDir, fileType, cropType, minCrop)
%       saveCroppedBatch(param, cropDir, fileType, cropType, minCrop, minCropBorderSize)
%INPUT    param: parameter file for a given directory of images. Generated by
%
%    multipleRegionCrop. Using multipleRegionCrop.m the user must have
%    cropped down the images to the desired size.
%
%    cropDir: the directory to save the cropped region to. This directory
%    can be the directory that the images are taken from. If it is this
%    program will overwrite the images in that directory
%
%    fileType: 'tiff' or 'png'. Save the result in either format
%
%    cropType: 'all', 'xy', or 'z'. Crop the images either in the 'xy' plane,
%    'z' plane or in both ('all'). Only 'xy' currently supported.
%
%    minCrop (optional, default= false): true/false. If true saveCropped Batche uses the
%    code calcMinCrop() to find the minimum cropping rectangles around the
%    gut based on the outline of the gut.
%
%    minCropBorderSize (optional) Default border size if minCrop is true is
%    0. Gives the width (in microns) around the gut outline the regions are
%    cropped down to.
%
%AUTHOR: Matthew Jemielita

function saveCroppedBatch(param, cropDir, fileType,cropType, varargin)

sList = 'all';
switch nargin
    case 4
        minCrop = false;
    case 5
        minCrop = varargin{1};
        minCropBorderSize = 0;
    case 6
        minCrop = varargin{1};
        minCropBorderSize = varargin{2};
    case 7
        minCrop = varargin{1};
        minCropBorderSize = varargin{2};
        sList = varargin{3};
    otherwise
        fprintf(2, 'saveCroppedBatch takes 4-6 inputs!');
        return
end

%Check inputs

if(~ismember(fileType, ['png', 'tiff']))
    frpintf(2, 'Can only accept png and tiff as files types to save to!\n');
    return
end
if(~ismember(cropType, ['all', 'xy', 'z']))
   fprintf(2, 'Can only accept all xy and z as crop types!\n'); 
    return
end
    

%Get some needed variables.
allRegion = [param.expData.Scan.region];
isScan =  cellfun(@(x)strcmp(x, 'true'), {param.expData.Scan.isScan});
%Remove regions that are not scans (i.e. videos)
allRegion = allRegion(isScan==1);

%Variables for the scans
totalNumRegions = length(unique(allRegion));
totalNumScans = param.expData.totalNumberScans;
totalNumColors = size(param.color,2);


%Check to make sure that the directories all have the same number of images
err = checkScanImageNumber(totalNumScans, totalNumRegions, totalNumColors, param);
if(err==1)
    fprintf(2, 'Number of scans is different!\n');
    return;
end

    
%Auto crop down if desired.
if(minCrop==true)
    [~, param] = calcMinCrop(param, false, minCropBorderSize);
end
%calculate maximum intensity projections
calcProjections(param);



%See if we're cropping a subset or all of the images otherwise use the
%input scan list
if(strcmp(sList, 'all'))
    sList = 1:totalNumScans;
end
if(sList(end)>totalNumScans)
    fprintf(2, 'Maximum number of scans exceeded!\n');
    return
end

loadType = 'individual'; %This is a slightly faster way to do it than loading in each images individually
allImages = [];

%Create a new directory structure if necessary
if(~strcmp(cropDir, param.directoryName))
    for nS=1:totalNumScans
        for nR = 1:totalNumRegions
            for nC = 1:totalNumColors
                dirName = [cropDir filesep 'Scans' filesep 'scan_', num2str(nS), filesep ...
                    'region_', num2str(nR), filesep param.color{nC}];
                if(~isdir(dirName))
                    mkdir(dirName);
                end
                
            end
        end
    end
end



parameters = param.expData;
timeData = param.expData.timeData;

%Make a backup of the original experimentalData.mat files if we're
%overwriting the directory
if(strcmp(cropDir, param.directoryName))
   copyfile( [cropDir, filesep, 'ExperimentData.mat'],...
       [cropDir, filesep, 'ExperimentData.mat_backup']);
end

for thisS=1:length(sList);
    nS = sList(thisS);
    
    mess = ['Cropping scan ', num2str(nS)];
    fprintf(2, mess);

   
    for nR = 1:totalNumRegions

        for nC = 1:totalNumColors

            outputDirName = [cropDir filesep 'Scans' filesep 'scan_', num2str(nS), filesep ...
                'region_', num2str(nR), filesep param.color{nC}];
            inputDirName =  [param.directoryName filesep 'Scans' filesep 'scan_', num2str(nS), filesep ...
                'region_', num2str(nR), filesep param.color{nC}];
            
            index = find([param.expData.Scan.region]==nR,nC);
            index = index(nC);%Return the appropriate region for this color
            
            totalNumIm = param.expData.Scan(index).nImgsPerScan;%Assuming there are equal number of images in both channels...
            %a reasonable assumption.
            
            %Same code as in registerSingleImage.m
            %The different regionExtent for different
            %colors-necessary if there was a glitch in image
            %acquisition that made the two colors offset...should be a
            %rare bug but we have seen it.
            if(length(param.regionExtent.XY)==1)
                thisRegion = param.regionExtent.XY;
                if(iscell(thisRegion))
                    thisRegion = thisRegion{1};
                end
            elseif(length(param.regionExtent.XY)==totalNumColors)
                thisRegion = param.regionExtent.XY{nC};
            else
                disp('The number of different colors in param.regionExtent.XY does not match the total number of colors!');
                return;
            end
            
            xOutI = thisRegion(nR,1);
            xOutF = thisRegion(nR,3)+xOutI-1;
            
            yOutI = thisRegion(nR,2);
            yOutF = thisRegion(nR,4)+yOutI -1;
            xInI = thisRegion(nR,5);
            xInF = xOutF - xOutI +xInI;
            
            yInI = thisRegion(nR,6);
            yInF = yOutF - yOutI +yInI;
            
            switch loadType  
                case 'individual'
                    %Load in each image one after another and then save
                    saveIndividualImages();
                case 'wholeStack'
                    %Allocate memory for this image stack if necessary
                    saveWholeStack(); 
            end
            
            
        end

    end   
    fprintf(2, '\n');
end

%mlj:commented out
%calcProjections(param);
%Saving the new range of pixel locations
for nC = 1:totalNumColors
    
    if(length(param.regionExtent.XY)==1&&~iscell(param.regionExtent.XY))
        param.regionExtent.XY(:,5)= 1;
        param.regionExtent.XY(:,6) = 1;
    elseif(length(param.regionExtent.XY)==totalNumColors)
        param.regionExtent.XY{nC}(:,5) = 1;
        param.regionExtent.XY{nC}(:,6) = 1;
    else
        disp('The number of different colors in param.regionExtent.XY does not match the total number of colors!');
        return;
    end
end

%Note: currently not updating the experimentData.txt file!!!!
%Also save the full param structure so that we can use this to load in the
%appropriate variables after cropping the images.
if(~isdir([cropDir filesep 'gutOutline']))
    mkdir(cropDir, 'gutOutline');
end

param.directoryName = cropDir;
param.dataSaveDirectory = [cropDir filesep 'gutOutline'];

save([cropDir filesep 'gutOutline', filesep 'param.mat'], 'param');
save([cropDir filesep 'ExperimentData.mat'], 'parameters', 'timeData', 'param');


%Recalculate the MIP for this new cropping region
%calcProjections(param);


    function [] = saveIndividualImages()
        
        for nI = 1:totalNumIm
            fN = [inputDirName, filesep, 'pco', num2str(nI-1), '.tif'];
            %Loading in this image
            info = imfinfo(fN);
            
            %For now, only crop if not the maximum size-this is a cheap way
            %to get around us accidentally starting this code at the center
            %of a scan.
            
            imI = imread(fN,...
                'PixelRegion', {[xInI xInF], [yInI yInF]});
            %Saving this image to the new location, in either a
            %tiff or png format.
            switch fileType
                case 'tiff'
                    fNout = [outputDirName, filesep, 'pco', num2str(nI-1), '.tif'];
                    imwrite(imI, fNout);
                case 'png'
                    fNout = [outputDirName, filesep, 'pco', num2str(nI-1), '.png'];
                    imwrite(imI, fNout);
                    if(strcmp(cropDir, param.directoryName))
                        delete(fN);%If we're overwriting the original file, then delete the .tiff file and replace it with a .png
                    end
            end
            
            fprintf(2, '.');
        end
        
    end

    function [] = saveWholeStack()

       xSize = xInF-xInI+1;
       ySize = yInF-yInI+1;
       zSize = totalNumIm;
       if(isempty(allImages))
           allImages = zeros(xSize, ySize, zSize);
       end
       
       if(sum(size(allImages)==[xSize ySize zSize])~=3)
          allImages = zeros(xSize, ySize, zSize);   
       end
       
       for nI = 1:totalNumIm
           fN = [inputDirName, filesep, 'pco', num2str(nI-1), '.tif'];
           %Loading in this image
           allImages(:,:,nI) = imread(fN,...
               'PixelRegion', {[xInI xInF], [yInI yInF]});
       end
       
       for nI=1:totalNumIm
           switch fileType
               case 'tiff'
                   fNout = [outputDirName, filesep, 'pco', num2str(nI-1), '.tif'];
                   imwrite(allImages(:,:,nI), fNout);
               case 'png'
                   fNout = [outputDirName, filesep, 'pco', num2str(nI-1), '.png'];
                   imwrite(allImages(:,:,nI), fNout);
                   if(strcmp(cropDir, param.directoryName))
                       delete(fN);%If we're overwriting the original file, then delete the .tiff file and replace it with a .png
                   end
           end
           
       end
       
       
        
    end

end