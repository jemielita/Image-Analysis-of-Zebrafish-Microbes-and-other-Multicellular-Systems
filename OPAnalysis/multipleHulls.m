
%Multiple convex hulls

function [] = multipleHulls(fileDir, sMin, sMax, type)
plotData = 'false';
for i=sMin:sMax
    
    if(type==1)
        fN = [fileDir,filesep, 'OP_Scan', sprintf('%03d', i), '.mat'];
    else
        
        fN = [fileDir, filesep, 'an', sprintf('%03d', i), '_cmle.mat'];
    end
    %     imT = load(fN);
    %     imT = imT.mO-imT.mD;
    %     imT = imT>0;
    
    imT = load(fN);
    imT = imT.imT;
    [convexPt, linePt, perimVal] = opWidth(imT,i);
    
    if(strcmp(plotData, 'false'))
        conF = [fileDir,filesep,'OP_Scan', sprintf('%03d', i), 'convex.mat'];
        save(conF, 'convexPt', 'linePt', 'perimVal');
    end
end

end