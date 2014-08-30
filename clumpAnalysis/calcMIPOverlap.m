function totDiff = calcMIPOverlap(obj)

fprintf(1, 'Calculating cluster overlap between different colors');
for scanNum = 1:obj.totalNumScans
    
    %Load in masks
    for colorNum = 1:obj.totalNumColor
        fileDir = [obj.scan(scanNum,colorNum).saveLoc filesep 'masks' filesep ...
            'clumpAndIndiv_nS' num2str(obj.scan(scanNum,colorNum).scanNum) '_'...
            obj.scan(scanNum,colorNum).colorStr '.mat'];
       
        inputVar = load(fileDir);
        
        %Only look at clusters, not individuals, in calculating the
        %overlap.
        segMask = inputVar.segMask==2;
        
        im{colorNum} = segMask;        
    end
    
    %Looking at overlap between the different clusters
    imDiff = (im{1}>0)+(im{2}>0);
    imDiff = imDiff==2;
    
    temp = im{2}>0;
    
    totDiff(scanNum) = sum(imDiff(:))/sum(temp(:));
    
    fprintf(1, '.');
end
fprintf(1, '\n');