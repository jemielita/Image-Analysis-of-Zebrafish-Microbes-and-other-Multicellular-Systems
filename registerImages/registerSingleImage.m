%For a given scan number and color, combine all the different regions
%together.

function im = registerSingleImage(nScan,colorType,zNum,im, imOr,data,param)
    
    totalNumRegions = length(unique([param.expData.Scan.region]));
    %%Now loading in the images
    %Base directory for image location
    baseDir = strcat(data.directory, filesep, 'Scans',filesep);
    
    %Going through each scan
    scanDir = strcat(baseDir, data.scan(nScan).directory, filesep);
    
    
    %And each color (in the debugging phase, we'll restrict ourselves
    %to one color

    imNum = param.registerImZ(zNum,:);
    %Load in the associated images
    for regNum=1:totalNumRegions
        if(imNum(regNum)~=-1)
            imFileName = ...
                strcat(scanDir,  'region_', num2str(regNum),filesep,...
                colorType, filesep,'pco', num2str(imNum(regNum)),'.tif');
            imOr(:,:, regNum) = imread(imFileName);
        else
            imOr(:,:,regNum) = zeros(2160,2560);
        end
        
           
    end
  
    %Now take the different regions and overlap them
    
    %Putting in the first region
    im(1:2160,1:2560) = imOr(:,:,1);
    
    %And then all the subsequent regions
    xInit = 1;
    yInit = 1;
    yInitPrev = yInit;
    xInitPrev = yInit;
    
    for regNum=2:totalNumRegions
        xInit = xInitPrev; %What it would be if there was no overlap between images
        xInit = xInit + param.registerImXY(regNum-1,2,2)-1;%And including the offset...not entirely positive about this one
        %need to look at data that also has an x-offset
        
        %Filling up the new region
        yInit = yInitPrev;
        yInit = yInit +param.registerImXY(regNum-1,1,1);
        im(xInit:xInit+2160-1, yInit:yInit+2560-1) = imOr(:,:,regNum);

        %Somewhat inefficient, but let's refill in areas of overlap
        %Only do this for regions that are both at this z-level.
        if(imNum(regNum)~=-1)
            xOv = param.registerImXY(regNum-1,1,4)-1;
            yOv = param.registerImXY(regNum-1,1,3);
            
            im(xInit:xInit+xOv, yInit:yInit + yOv) = (1.0/2.0)*...
                (imcrop(imOr(:,:,regNum-1),param.registerImXY(regNum-1,1,:))+...
                imcrop(imOr(:,:,regNum),param.registerImXY(regNum-1,2,:)));
            
            
            yInitPrev = yInit;
            xInitPrev = xInit;
        end
    end



end