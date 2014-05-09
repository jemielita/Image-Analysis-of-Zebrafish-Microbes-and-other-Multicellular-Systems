function totDiff = calcMIPOverlap(obj)

for scanNum = 1:obj.totalNumScans
    
    
    %Load in masks
    for colorNum = 1:obj.totalNumColor

        fileDir = obj.scan(scanNum, colorNum).saveLoc;
        inputVar = load([fileDir filesep 'param.mat']);
        param = inputVar.param;
        
        sN= obj.scan(scanNum, colorNum).scanNum;
        inputVar = load([fileDir filesep 'bkgEst' filesep 'fin_' num2str(sN) '_' param.color{colorNum} '.mat']);
        im{colorNum} = bwlabel(inputVar.segMask);
        
    end
    
    %Remove all single objects
    for colorNum = 1:obj.totalNumColor
        
        indRemList = [];
        for i=1:length([obj.scan(scanNum, colorNum).clumps.allData])
            indRem = obj.scan(scanNum, colorNum).clumps.allData(i).totalInten<obj.cut(colorNum);
            indRem2 = obj.scan(scanNum, colorNum).clumps.allData(i).gutRegion>=obj.totPopRegCutoff;
            
            if(isempty(indRem))
                indRem = 1;
            end
            if(isempty(indRem2))
                indRem2 = 1;
            end
            
            if(or(indRem,indRem2))
                indRemList = [indRemList, obj.scan(scanNum, colorNum).clumps.allData(i).IND];
            end
                
        end
        
       %Remove them:Note this currently seems somewhat buggy-not removing
       %all the spots that I think we should be.
       im{colorNum}(ismember(im{colorNum}, indRemList)) = 0;
        
    end
    
    
    
    %Looking at overlap between the different clusters
    imDiff = (im{1}>0)+(im{2}>0);
    imDiff = imDiff==2;
    
    temp = im{2}>0;
    
    totDiff(scanNum) = sum(imDiff(:))/sum(temp(:));
    totDiff(scanNum)
    
    
    
    
    
    
end