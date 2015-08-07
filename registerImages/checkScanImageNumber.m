function err = checkScanImageNumber(totalNumScans, totalNumRegions, totalNumColors, param)


%Check to make sure that every scan has the same number of images in it
    for nS=1:totalNumScans
        for nR = 1:totalNumRegions
            for nC = 1:totalNumColors
                dirName = [param.directoryName filesep 'Scans' filesep 'scan_', num2str(nS), filesep ...
                    'region_', num2str(nR), filesep param.color{nC}];
                
                imComp{nR}(nS,nC) = length(ls(dirName));
                
            end
        end
    end
    checkSz = cellfun(@(x)length(unique(x)), imComp);
    if(unique(checkSz)==1)
        fprintf(1, 'All scans have the same number of images!\n');
       err = 0;
    else
        err = 1;
        fprintf(2, 'Scans contains a different number of images in each scan! Fix!\n')
        %Output list of scans so the user can check things:
        
        for nR = 1:totalNumRegions
            for nS=1:totalNumScans
                    for nC=1:totalNumColors
                       numIm(nC) = imComp{nR}(nS, nC);
                    end
                    fprintf(1, ['Region: ', num2str(nR) 'Scan ' num2str(nS), ' # images:  ' num2str(numIm) , '\n']);
                    
            end
        end
        
    
    end
    
end