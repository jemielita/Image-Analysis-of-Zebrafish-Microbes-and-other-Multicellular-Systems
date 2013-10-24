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
            
%             if(iscell(trainingListLocation))
%                 inputVar = load(trainingListLocation{colorNum});
%             else
%                 inputVar = load(trainingListLocation);
%             end
%             
%             trainingList = inputVar.allData;
            
            rProp = load([fileDir filesep 'singleBacCount'...
                filesep 'bacCount' num2str(scanNum) '.mat']);
            rProp = rProp.rProp;
            
            if(iscell(rProp))
                rProp = rProp{colorNum};
            end
               
            
           % rProp = bacteriaLinearClassifier(rProp, trainingList);
            rProp = rProp([rProp.gutRegion]==3);
            
            meanList = sort([rProp.MeanIntensity]);
            ind = round(0.95*length(meanList));
            
            autoFluorMaxInten(colorNum) = meanList(ind);
            
        end
        
    end