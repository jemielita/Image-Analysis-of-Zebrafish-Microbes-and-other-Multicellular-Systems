%spotClassifier: Contains tools for building and using classifiers for our
%list of found bacterial spots. This includes both classifiers that are
%somewhat crude: manual spot removal and intensity thresholds in the region
%of autofluorescent cells and more sophisticated like support vector
%machines.

classdef spotClassifier
    
   properties
       svmStruct = [];
       tList = [];
       autoFluorMaxInten = [];
       feat = {'MeanIntensity', 'Area', 'MaxIntensity', 'MinIntensity'};
       rescaleFactor = [];
       boxVal = []; %For giving the softness of the SVM margins.
      
       featRng = NaN;
   end
   
   methods
       function obj = createTrainingList(obj, nc,sList, removeBugInd, saveDir)
           %Assemble a training list from this data
           
           %Clear previously made training list
           obj.tList = [];
           
           for i = 1:length(sList)
               ns = sList(i);
               inputVar = load([saveDir filesep 'bacCount' num2str(ns) '.mat']);
               rProp = inputVar.rProp{nc};
               
               %Only build classifier for points before the autofluorescent
               %region
               rProp = obj.selectGutRange(rProp, 1:2);
               rProp = obj.removeOutsideRang(rProp);
               
               %Find manually kept and removed spots
               ind = removeBugInd{ns, nc};
               remSpots = ismember([rProp.ind],ind);
               keptSpots = ~ismember([rProp.ind],ind);
               numKeptSpots = sum(keptSpots);
               numRemSpots = sum(remSpots);
               
               %Should be written more generally to call any number of
               %classification features
           
               for j = 1:length(obj.feat)
                   t(:,j) = [[rProp(keptSpots).(obj.feat{j})], [rProp(remSpots).(obj.feat{j})]];
               end
               t(1:numKeptSpots-1,length(obj.feat)+1) = 1;
               t(numKeptSpots:end,length(obj.feat)+1) = 0;  
               
               obj.tList = [obj.tList; t];
           end   
       end
       
       function obj = createSVMclassifier(obj)
           if(isempty(obj.tList))
               fprintf(2, 'Need to construct a training list first!\n');
               return
           end
           
           for i=1:length(obj.feat)
               tList(:,i)  = obj.tList(:,i)./obj.featRng.maxR.(obj.feat{i});
           end
           
           
           Y = tList(:,end); Ynom = nominal(Y==1);

           
           figure;
           numKeptSpots = sum(Y==1);
           
           %obj.tList(:,[1,3]) = log(obj.tList(:,[1,3]));
           boxCon = [obj.boxVal(1)*ones(numKeptSpots,1); obj.boxVal(2)*ones(size(tList,1)-numKeptSpots,1)];
           displayData = true;
           if(displayData==true)
               svmStruct = svmtrain(tList(:,1:2), Ynom, 'showplot', true, 'Kernel_Function', 'quadratic', 'boxconstraint', boxCon, ...
                   'autoscale', true);
               
           end
           
           svmStruct = svmtrain(tList(:,1:4), Ynom, 'showplot', true, 'Kernel_Function', 'quadratic', 'boxconstraint', boxCon,'autoscale', true);
           
           % Calculate the confusion matrix
           
           group = svmclassify(svmStruct,tList(:,1:4));
           
           N = length(group);
           
           bad = ~strcmp(group, Ynom);
           ldaResubErr  = sum(bad)/N;
           
           [ldaResubCM,grpOrder] = confusionmat(Ynom,group)
           
           
           obj.svmStruct = svmStruct;
          
       end
      
       function rProp = SVMclassify(obj, rProp)
           %Construct array of values for each of the found spots
           
           %cenratio: not calculated correctly.
           cen = [rProp.CentroidOrig];
           cen = reshape(cen, 3, length(cen)/3);
           cenRatio = max(cen, [],1)./min(cen, [],1);
           
           allData(:,1) = log([rProp.MeanIntensity]);
           allData(:,2) = log([rProp.Area]);
           allData(:,3) = cenRatio;
           
           
           for i=1:4
               allData(:,i) = [rProp.(obj.feat{i})];
               allData(:,i) = allData(:,i)./obj.featRng.maxR.(obj.feat{i});
           end
           
           svmClass = svmclassify(obj.svmStruct{1}, allData);
           
           rProp = rProp(svmClass =='true');
           
           rProp = obj.removeOutsideRang(rProp);
       end
       
       function rProp = manuallyRemovedBugs(obj, rProp, saveDir)
           
           %Load in list of removed bugs, if we manually removed some.
           remBugsSaveDir = [saveDir filesep 'singleBacCount' filesep 'removedBugs.mat'];
           if(exist(remBugsSaveDir, 'file')==2)
               removeBugInd = load(remBugsSaveDir);
               removeBugInd = removeBugInd.removeBugInd;
               removeBugInd = removeBugInd{scanNum, colorNum};
               
               rProp(removeBugInd) = [];
           end
       end
       
       function rProp = autoFluorCutoff(obj, rProp)
           inAutoFluor = [rProp.gutRegion]==3; 
           %Remove low intensity points in this region
           outsideAutoFluor = [rProp.gutRegion]~=3;
           
           inAutoFluorKept = [rProp.MeanIntensity]>obj.autoFluorMaxInten;
           inAutoFluor = and(inAutoFluor,inAutoFluorKept);
           
           keptSpots = or(outsideAutoFluor, inAutoFluor);
           rProp = rProp(keptSpots);
           
       end
      
       function obj = setFeatRang(obj, minR, maxR)
           %Set the maximum and minimum value for each feature, irrespective of any further classification
           for i=1:length(obj.feat)
               obj.featRng.minR.(obj.feat{i}) = minR(i);
               obj.featRng.maxR.(obj.feat{i}) = maxR(i);
          end
       end
       
       function rProp = removeOutsideRang(obj, rProp)
       %Remove all objects that fall outside the range that we've prescribed for the spot values
       
       
       for i=1:length(obj.feat)
       ind = [rProp.(obj.feat{i})]> obj.featRng.minR.(obj.feat{i}) & ...
           [rProp.(obj.feat{i})]< obj.featRng.maxR.(obj.feat{i});
       
       rProp = rProp(ind);
       
       end
       
       
       end
       
       function obj = spotClassifier(obj)
          
           %Default min range for all features, and convert into
           %human-readable form.
           minR = [200,20,300, 200];
           maxR = [10000,10000, 10000, 10000 ];
           obj = setFeatRang(obj, minR, maxR);
          
       end
   end
   
   methods (Static)
       function spots = selectGutRange(spots, rList)
          %Only keep bacteria that are within the gut regions given by
          %rList
          gutRegion = [spots.gutRegion];
          gutRegion = ismember(gutRegion, rList);
          
          spots = spots(gutRegion);
       end
        
   end

end