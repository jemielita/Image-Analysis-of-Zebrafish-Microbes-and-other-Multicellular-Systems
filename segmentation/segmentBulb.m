% Segment the gut to remove background signal from the bulb.
%
%

function [gutMaskAll, im] = segmentBulb(param, saveData, displayData)
%% Load in image stack
maxS = param.expData.totalNumberScans

fileDir = param.dataSaveDirectory;
color = param.color;

%Filter size for std. dev. filter
filtSize = 5;
meanOffset = 1.1;
rosinOffset = 1.3;

for nC=1:length(color)
    [imStd, imMean, im] = loadBulbRegion;
    
    gutMaskAll{nC} = segmentThisBulb(imStd, imMean, im);
end

if(saveData)
   param.regionExtent.bulbMask = gutMaskAll;
   save([param.dataSaveDirectory filesep 'param.mat'], 'param');
end


    function [imStd, imMean, im] = loadBulbRegion()
        
        fprintf(1, 'Loading in all regions and filtering');
        for nS=1:maxS
            fileIn = [fileDir, filesep, 'FluoroScan_',num2str(nS),'_', color{nC}, '.tiff'];
            imIn = imread(fileIn);
            
            %Now crop down this region
            rect = param.regionExtent.bulbRect;
            poly = param.regionExtent.polyAll{nS};
            fishMask = poly2mask(poly(:,1), poly(:,2), size(imIn,1), size(imIn,2));
            imIn = double(imIn).*fishMask;
            im(:,:,nS) = imcrop(imIn,rect);
            
            fishMask = imcrop(fishMask, rect);
            
            %Calculate a standard deviation filter
            imStd(:,:,nS) = stdfilt(im(:,:,nS), ones(filtSize,filtSize));
            
            %There's heavy lines near the edge of the gut b/c of the mask
            fishMask = imerode(fishMask, strel('disk', filtSize-1));
            imStd(:,:,nS) = imStd(:,:,nS).*fishMask;
            
            %Calculate the local mean in a 3x3 neighborhbood.
            imMean(:,:,nS) = localmean(im(:,:,nS));
            fprintf(1, '.');
        end
        
        fprintf(1, 'done!\n');
    end

    function gutMask = segmentThisBulb(imStd, imMean, im)
        
        fprintf(1, 'Segmenting background noise');
        for nS= 1:maxS
            
            poly = param.regionExtent.polyAll{nS};
            
            %Parameters for the peak finding
            pkh = 10;
            window= 10;
            
            imT = im(:,:,nS);
            imT2 = imT(:);
            imT2(imT2==0) = [];
            
            [data, ind] = hist(double(imT2), 1:2000);
            %Remove the last data point-this contains all the high intensity values
            data(end) = [];
            ind(end) =[];
            smth = smooth(ind,data, 51, 'sgolay',3);
            
            pkOffset = 1500;
            loc = [];
            while(isempty(loc))    
                minP = data(end)+ pkOffset;
                [pks,loc] = findpeaks(smth, 'MINPEAKHEIGHT', minP,...
                    'MINPEAKDISTANCE', 20);
                pkOffset = pkOffset -100;
            end
            
            
            pksOut =[]; locOut = [];
            for j=1:length(pks)
                xMin= max([1,loc(j)-window]);
                xMax = min([length(smth), loc(j)+window]);
                
                if(pks(j)==max(smth(xMin:xMax)))
                    pksOut = [pksOut; pks(j)];
                    locOut = [locOut; loc(j)];
                end
            end
            
            
            globalMask = imMean(:,:,nS)>meanOffset*locOut(end);
            se = strel('disk',3);
            globalMask = imclose(globalMask,se);
            globalMask = bwareaopen(globalMask, 10);
            
            %   imshow(overlayIm(imc(:,:,nS), globalMask),[])
            %   pause(1);segm
            
            %Use the Rosin threshold on the standard deviation filter to 
            %find where individual bacteria are
            %(This threshold scheme is good at finding centers of bright points in
            %a large background-it seems to also work rather well in our case.
            imUnrolled = imStd(:,:,nS); imUnrolled = double(imUnrolled(:));
            imUnrolled(imUnrolled==0) = [];
            T = rosin(hist(imUnrolled,1:500));
            T = rosinOffset*T;
            rosinMask = imStd(:,:,nS)>T;
            
            rosinMask = imclose(rosinMask,se);
            rosinMask = bwareaopen(rosinMask, 10);
            
            %Find the overlap between these two regions-only keep regions that
            %contain a subregion that passes the rosin threshold
            
            [x,y] = ind2sub(size(rosinMask),find(rosinMask==1));
            combMask = bwselect(globalMask, y,x);
            
            
            if(displayData)
                %    imshow(overlayIm(imT,rosinMask,combMask, globalMask),[0 1000]);
                imshow(overlayIm(imT,combMask,''),[0 800]);
                %   pause(1);
               title(['Scan number: ', num2str(nS)]);
               
                pause(1);
            else
                
                fprintf(1,'.');
            end
            gutMask(:,:,nS) = combMask;
        end
        fprintf(1, 'done!\n');
    end
end