%For a given scan number and color, combine all the different regions
%together.

function im = registerSingleImage(nScan,colorType,zNum,im,data,param)
    
    totalNumRegions = length(unique([param.expData.Scan.region]));
    %%Now loading in the images
    %Base directory for image location
    baseDir = strcat(data.directory, filesep, 'Scans',filesep);
    
    %Going through each scan
    scanDir = strcat(baseDir, data.scan(nScan).directory, filesep);
    
    %And each color (in the debugging phase, we'll restrict ourselves
    %to one color

    imNum = param.regionExtent.Z(zNum,:);
    %Load in the associated images
    
    %Filling the input image with zeros, to be safe.
    im(:) = 0;
    im = uint16(im); %To match the input type of the images.
    for regNum=1:totalNumRegions
        
        %Get the range of pixels that we will read from and read out to.
        xOutI = param.regionExtent.XY(regNum,1);
        xOutF = param.regionExtent.XY(regNum,3);
        
        yOutI = param.regionExtent.XY(regNum,2);
        yOutF = param.regionExtent.XY(regNum,4);
        
        xInI = param.regionExtent.XY(regNum,5);
        xInF = xOutF - xOutI +1;
        
        yInI = param.regionExtent.XY(regNum,6);
        yInF = yOutF - yOutI +1;
        
        
        if(imNum(regNum)~=-1)
            imFileName = ...
                strcat(scanDir,  'region_', num2str(regNum),filesep,...
                colorType, filesep,'pco', num2str(imNum(regNum)),'.tif');
            
            im(xOutI:xOutF,yOutI:yOutF) = imread(imFileName,...
                'PixelRegion', {[xInI xInF], [yInI yInF]}) + ...
                         im(xOutI:xOutF,yOutI:yOutF);
        end
          
        %Overlapping the regions
        %Overlapping regions
        %This is potentially slow (however we need to be as quick as possible with this type of thing).
        %After we know this code works, we'll come back and write quicker code.
        
         
         %Overlap for regNum>1
         if(regNum>1 && imNum(regNum-1)>=0 &&imNum(regNum)>=0)
             im(param.regionExtent.overlapIndex{regNum-1} )= ...
                 0.5*im(param.regionExtent.overlapIndex{regNum-1});
            imNum
         end
        
    end
  
    
   
end