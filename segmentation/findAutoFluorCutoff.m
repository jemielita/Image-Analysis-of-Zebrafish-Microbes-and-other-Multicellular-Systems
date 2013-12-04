   function autoFluorMaxInten = findAutoFluorCutoff(param, colorList)
        %Go through scans and find only spots found in the autofluorescent region
        %Use these to find a threshold that removes 95% of the
        %autofluorescent cells in the first scan-this is usually the time
        %that these cells are the brightest.
        
        minS = 1;
        maxC = length(param.color);
        fileDir = param.dataSaveDirectory;
        
        
        scanNum = minS;
        
        for i=1:length(colorList)
            
            scanEmpty= 0;
            while(scanEmpty==0)
            
            colorNum = colorList(i);
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
               if(length(rProp)>1)
                   rProp = rProp{colorNum};
               else
                   rProp = rProp{1};
               end
            end
               
            
           % rProp = bacteriaLinearClassifier(rProp, trainingList);
            rProp = rProp([rProp.gutRegion]==3);
            
            meanList = sort([rProp.MeanIntensity]);
            ind = round(0.95*length(meanList));
            
            if(~isempty(meanList))
                autoFluorMaxInten(colorNum) = meanList(ind);
                scanEmpty = 1;
            else
                scanEmpty = 0;
                scanNum = scanNum+1;
                scanNum
            end
            
            
            end
        end
        
    end