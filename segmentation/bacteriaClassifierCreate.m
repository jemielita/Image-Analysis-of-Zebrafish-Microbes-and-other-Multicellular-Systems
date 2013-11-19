%bacteriaClassifierCreate: For a given set of fish, create a training list
%for classification and an SVM object for classification.
%
% USAGE [trainingList, svmStruct] = bacteriaClassifierCreate(paramList)
% 
% INPUT paramAll: cell array containing all the parameters to be used to
%                 create a training list.
%       saveData: structure containing .value (if true then save data, if false don't)
%                 and .saveLocation-location to save the data. If
%                 saveData.value = false, then no save location needs to be
%                 assigned.
%        displayData: if true then show a plot of the SVM for each color.
%        colorList: cell array containing which colors to analyze.

% Note: need to build in support for different classifiers for different
% scan numbers and  for inputting the weight for classification.
% AUTHOR Matthew Jemielita, Nov6, 2013

function [trainingList, svmStruct] = bacteriaClassifierCreate(paramAll, saveData, displayData, colorList)

%Find out which colors to calculate a training list for (sometimes we only
%have spots in some of the channels).
cList = [];
for nC=1:length(colorList)
    switch colorList{nC}
        case '488nm'
            cList(nC) = 1;
        case '568nm'
            cList(nC) = 2;
    end
    
end
       
   


%% Load in removed indices
removeBugIndAll = cell(length(paramAll),1);

for nF=1:length(paramAll)
    fileName = [paramAll{nF}.dataSaveDirectory '\singleBacCount',...
        filesep 'removedBugs.mat'];
    if(exist(fileName)==2)
        removeBugInd = load(fileName);
        removeBugIndAll{nF} = removeBugInd.removeBugInd;
    end

end


%% For each of the removed indices-get the correct and incorrectly labelled spots
[trainingListAll, rPropAll] = createTrainingList(removeBugIndAll, paramAll,cList);


%% Construct array to be used for SVM for the GFP and RFP channel

tLAll = cell(length(trainingListAll),1);
for i=1:length(cList)
    nC = cList(i);
    
    
    for i=1:length(trainingListAll{nC});
        tLAll{nC}= [tLAll{nC}; trainingListAll{nC}{i}];
    end
    Y{nC} = tLAll{nC}(:,4); Ynom{nC} = nominal(Y{nC}==1);
    tLAll{nC} = tLAll{nC}(:,1:3);
    
end


%% Find autofluorescent cutoff
% for nF=1:length(paramAll)
%    autoFluorMaxIntenAll{nF} = findAutoFluorCutoff(paramAll{nF},cList);
%   
%    nF
% end

%% Use SVM for classifier

nC = 2;
figure;
numKeptSpots = sum(Y{nC}==1);
boxCon = [2*ones(numKeptSpots,1); 0.001*ones(size(tLAll{nC},1)-numKeptSpots,1)];
if(displayData==true)
    svmStruct = svmtrain(tLAll{nC}(:,1:2), Ynom{nC}, 'showplot', true, 'Kernel_Function', 'linear', 'boxconstraint', boxCon);
end


svmStruct = svmtrain(tLAll{nC}(:,1:3), Ynom{nC}, 'showplot', true, 'Kernel_Function', 'linear', 'boxconstraint', boxCon);



% Calculate the confusion matrix

group = svmclassify(svmStruct,tLAll{nC});

N = length(group);

bad = ~strcmp(group, Ynom{nC});
ldaResubErr  = sum(bad)/N;

[ldaResubCM,grpOrder] = confusionmat(Ynom{nC},group)

%% Save results
if(saveData.value ==true)
   %Save the classifier
    save(saveData.saveLocation, 'svmStruct'); 
    
    %Save a pointer to the classifier in each of the fish gutOutline
    %folders
    for nF=1:length(paramAll)
        fileName = [paramAll{nF}.dataSaveDirectory filesep 'singleBacCount' filesep 'bacteriaClassifier.mat'];
        
        cullProp = ''; %No longer used.
        % autoFluorMaxInten = autoFluorMaxIntenAll(nF);
         autoFluorMaxInten = [900 900];
         trainingListLocation{1} = saveData.saveLocation;
         trainingListLocation{2} = saveData.saveLocation;
         
        save(fileName, 'autoFluorMaxInten', 'cullProp', 'trainingListLocation');
    end
end


end


    function [trainingListAll, rPropAll] = createTrainingList(removeBugIndAll, paramAll, cList)
        tlNum = [1 1]; %For indexing the training lists
        
        rPropAll= cell(2,1);
        rPropAll{1} = cell(1,1);
        rPropAll{2} = cell(1,1);
        
        
        for nF = 1:length(paramAll)
            
            if(~isempty(removeBugIndAll{nF}))
                sClass = cellfun(@(x)~isempty(x), removeBugIndAll{nF});
            else
                continue;
            end
            
            for i = 1:length(cList)
                nC= cList(i);
                remInd = find(sClass(:,nC)==1);
                
                for i=1:length(remInd)
                    nS = remInd(i);
                    fileRoot = [paramAll{nF}.dataSaveDirectory '\singleBacCount'];
                    
                    rProp = load([fileRoot, '\bacCount', num2str(nS), '.mat']);
                    rProp = rProp.rProp;
                    
                    %rProp = rProp{nC};
                    rProp = rProp{1};
                    
                    %Remove spots that were manually segmented.
                    keptSpots = setdiff(1:length(rProp), removeBugIndAll{nF}{nS, nC});
                    length(keptSpots)
                    removedSpots = removeBugIndAll{nF}{nS, nC};
                    
                    
                    if(isfield(rProp, 'gutRegion'))
                        inAutoFluor = [rProp.gutRegion]==3;
                        outsideAutoFluor = ~inAutoFluor;
                        %Remove low intensity points in this region
                        autoFluorMaxInten  = 350; %According the pixel values, most of these are fake
                        inAutoFluorRem = [rProp.MeanIntensity]>autoFluorMaxInten;
                        inAutoFluor = and(inAutoFluor,inAutoFluorRem);
                        
                        keptSpots = intersect(keptSpots, find(or(outsideAutoFluor, inAutoFluor)==1));
                        
                        % rProp = rProp(keptSpots);
                        %xyz = xyz(:, keptSpots);
                    end
                    length(keptSpots)
                    
                    
                    
                    %Not best place to put in index, but it'll do for now
                    for i=1:length(rProp)
                        rProp(i).ind = i;
                    end
                    
                    %Use cutoffs applied to our data-currently hardwired in, but this
                    %should be an input.
                    
                    colorThresh = [0,0];
                    areaThresh = [3,3];
                    rPropClassified = rProp; %Don't use this further classifier for this data.
                    %                     rPropClassified = rProp([rProp.Area]>areaThresh(nC));
                    %
                    %                     rPropClassified = rPropClassified([rPropClassified.MeanIntensity]>colorThresh(nC));
                    
                    %Finding out which spots were removed by the above thresholds
                    %     keptSpots = intersect(keptSpots, [rPropClassified.ind]);
                    
                    %   removedSpots = [removedSpots, setdiff([rProp.ind], [rPropClassified.ind])];
                    
                    %   removedSpots = unique(removedSpots);
                    
                    
                    %Remove spots that are past the autofluorescent region
                    %from both classifiers
                      insideGut = find([rProp.gutRegion]<=3);
                       keptSpots = intersect(keptSpots, insideGut);
                  % ['Kept spots: ', num2str(length(keptSpots))]
                  
                   %mlj: include all removed spots in our true negative
                    %classifier. Lot's of 5's for some reason.
                     % removedSpots = intersect(removedSpots, insideGut);
                    
                    
                    if(isempty(keptSpots))
                        continue
                    end
                    
                    %Add to list of training data
                    clear tl;
                    tl(:,1) = [[rProp(keptSpots).MeanIntensity], [rProp(removedSpots).MeanIntensity]];
                    tl(:,2) = [[rProp(keptSpots).Area], [rProp(removedSpots).Area]];
                    
                    cen = [[rProp(keptSpots).CentroidOrig], [rProp(removedSpots).CentroidOrig]];
                    cen = reshape(cen, 3, length(cen)/3);
                    cenRatio = max(cen, [],1)./min(cen, [],1);
                    tl(:,3) = cenRatio;
                    
                    tl(1:length(keptSpots),4) = 1;
                    tl(length(keptSpots)+1:end,4) = 0;
                    
                    trainingListAll{nC}{tlNum(nC)} = tl;
                    
                    length(keptSpots)
                    rPropAll{nC}{tlNum(nC)} = rProp([keptSpots, removedSpots]);
                    tlNum(nC) = tlNum(nC) + 1;
                    %  figure; plot(trainingListAll{1}{tlNum(nC)-1}(:,1))
                    
                end
                
                
            end
            
            
        end
    end
    

