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
       feat = {'objMean','bkgMean', 'wvlMean','objStd','bkgStd','Volume', 'ksTest','centroidFit','MajorAxisLength','MinorAxisLength','Area','Eccentricity', 'convexArea'};
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
               
               %Temporary...
               keptSpots = setdiff(1:length(rProp), removeBugInd{ns, nc});
               remSpots = removeBugInd{ns,nc};
               
               %ind = [rProp(keptSpots).ind];
               ind = [rProp(remSpots).ind];
               
               %Only build classifier for points before the autofluorescent
               %region
               rProp = obj.selectGutRange(rProp, 1:2);
               rProp = obj.removeOutsideRang(rProp);
               
               %Find manually kept and removed spots
               %ind = removeBugInd{ns, nc};
               remSpots = ismember([rProp.ind],ind);
               keptSpots = ~ismember([rProp.ind],ind);
               numKeptSpots = sum(keptSpots);
               numRemSpots = sum(remSpots);
               
               
               %Should be written more generally to call any number of
               %classification features
               t = zeros(length(rProp), length(obj.feat));
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
           
           
           Y = obj.tList(:,end); Ynom = nominal(Y==1);
           
           for i=1:length(obj.feat)
           %    tList(:,i)  = obj.tList(:,i)./obj.featRng.maxR.(obj.feat{i});
               tList(:,i)  = obj.tList(:,i)./max(obj.tList(:,i));
           end
           
           for i=1:length(obj.feat)
              obj.featRng.maxR.(obj.feat{i}) = max(obj.tList(:,i)); 
           end

           figure;
           numKeptSpots = sum(Y==1);
           
           %obj.tList(:,[1,3]) = log(obj.tList(:,[1,3]));
           boxCon = [obj.boxVal(1)*ones(numKeptSpots,1); obj.boxVal(2)*ones(size(tList,1)-numKeptSpots,1)];
           displayData = true;
           if(displayData==true)
               svmStruct = svmtrain(tList(:,[10,2]), Ynom, 'showplot', true, 'Kernel_Function', 'polynomial', 'polyorder', 5,'boxconstraint', boxCon, ...
                   'autoscale', true);
               
           end
           
           svmStruct = svmtrain(tList(:,1:13), Ynom, 'showplot', true, 'Kernel_Function', 'polynomial', 'polyorder', 5,'boxconstraint', boxCon,'autoscale', true);
           
           % Calculate the confusion matrix
           
           group = svmclassify(svmStruct,tList(:,1:13));
           
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
           
%           allData(:,1) = log([rProp.MeanIntensity]);
 %          allData(:,2) = log([rProp.Area]);
  %         allData(:,3) = cenRatio;
           
           for i=1:length(obj.feat)
              allData(:,i) = [rProp.(obj.feat{i})]; 
              allData(:,i) = allData(:,i)./obj.featRng.maxR.(obj.feat{i});
           end
           
           svmClass = svmclassify(obj.svmStruct, allData);
           
           rProp = rProp(svmClass =='true');
           
           rProp = obj.removeOutsideRang(rProp);
       end
       
       function rProp = manuallyRemovedBugs(obj, removeBugInd)
           
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
      
       function obj = setAutoFluorCutoff(obj, rProp)
          %inten = setAutoFluorCutoff(obj, rProp): Set the autofluorescent 
          %cutoff to be used. The cuttoff will be set to mean +2*stdDev of 
          %the mean intensity of the spots given as input. Other schemes
          %would work as well. Suggest giving the input rProp as one of the
          %1st scans, where there are very few bacteria in this region
          inAutoFluor = [rProp.gutRegion]==3; 
          rProp = rProp(inAutoFluor);
          inten = mean([rProp.objMean]) +std([rProp.objMean]);
          obj.autoFluorMaxInten = inten;
       end
       
       function obj = setFeatRang(obj, minR, maxR)
           %Set the maximum and minimum value for each feature, irrespective of any further classification
           for i=1:length(obj.feat)
               obj.featRng.minR.(obj.feat{i}) = minR;
               obj.featRng.maxR.(obj.feat{i}) = maxR;
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
           minR = 0;
           maxR = Inf;
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