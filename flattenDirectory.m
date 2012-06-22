%Convert a directory structure into one that can easily be read into
%Hyugens.

function flattenDirectory(fileDir, filePrefix, fileType, whichDir, param)

%Get some needed variables.
totalNumRegions = length(unique([param.expData.Scan.region]));
totalNumScans = param.expData.totalNumberScans;
totalNumColors = size(param.color,2);


%Go through the directory structure and load the appropriate images,
%crop them, and then save the result as either a TIFF or PNG.

for nS=1:totalNumScans
    mess = ['Cropping scan ', num2str(nS)];
    fprintf(2, mess);
    
    for nR = 1:totalNumRegions
        for nC = 1:totalNumColors 
            %See if we're flattening on unflattening a directory
            switch whichDir
                case 'flatten'
                    outputDirName = [fileDir filesep filePrefix '_S',num2str(nS), 'nR', num2str(nR), ...
                        '_', param.color{nC}, '.tif'];
                    inputDirName =  [param.directoryName filesep 'Scans' filesep 'scan_', num2str(nS), filesep ...
                        'region_', num2str(nR), filesep param.color{nC}];
                case 'unflatten'
                    temp = outputDirName;
                    outputDirName = inputDirName;
                    inputDirName = temp;
            end
            
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
            
            saveIndividualImages();
            
            
        end

    end
    
    fprintf(2, '\n');
end


    function [] = saveIndividualImages()
        
        for nI = 1:totalNumIm
            
            switch whichDir
                case 'flatten'
                    fN = [inputDirName, filesep, 'pco', num2str(nI-1), '.tif'];
                    
                    %Loading in this image
                    imI = imread(fN,...
                        'PixelRegion', {[xInI xInF], [yInI yInF]});
                    %Saving this image to the new location, in either a
                    %tiff or png format.
                    
                case 'unflatten'
                    fN = inputDirName;
                    %Loading in this image
                    imI = imread(fN,...
                        'PixelRegion', {[xInI xInF], [yInI yInF]}, 'Index', nI);
            end
            
            switch fileType
                case 'tiff'
                    fNout = outputDirName;
                    imwrite(imI, fNout, 'WriteMode', 'append');
                case 'png'
                    fNout = [outputDirName, filesep, 'pco', num2str(nI-1), '.png'];
                    imwrite(imI, fNout);
                    if(strcmp(fileDir, param.directoryName))
                        delete(fN);%If we're overwriting the original file, then delete the .tiff file and replace it with a .png
                    end
            end
            fprintf(2, '.');
        end
        
    end


end