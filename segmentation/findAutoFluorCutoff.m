   function autoFluorMaxInten = findAutoFluorCutoff(param, trainingListLocation)
        %Go through scans and find only spots found in the autofluorescent region
        %Use these to find a threshold that removes 95% of the
        %autofluorescent cells in the first scan-this is usually the time
        %that these cells are the brightest.
        
        minS = 1;
        maxC = length(param.color);
        fileDir = param.dataSaveDirectory;
        
        
        scanNum = minS;
        
        for colorNum=1:maxC
            
            inputVar = load(trainingListLocation{colorNum});
            trainingList = inputVar.allData;
            
            rProp = load([fileDir filesep 'singleBacCount'...
                filesep 'bacCount' num2str(scanNum) '.mat']);
            rProp = rProp.rProp;
            
            rProp = rProp{colorNum};
            
            rProp = bacteriaLinearClassifier(rProp, trainingList);
            rProp = rProp([rProp.gutRegion]==3);
            
            meanList = sort([rProp.MeanIntensity]);
            ind = round(0.95*length(meanList));
            
            autoFluorMaxInten(colorNum) = meanList(ind);
            
        end
        
    end