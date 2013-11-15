%bacteriaClassifierCreate: For a given set of fish, create a training list
%for classification and an SVM object for classification.
%
% USAGE [trainingList, svmStruct] = bacteriaClassifierCreate(paramList)
%
%
% AUTHOR Matthew Jemielita, Nov6, 2013

function [trainingList, svmStruct] = bacteriaClassifierCreate(paramAll)


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
[trainingListAll, rPropAll] = createTrainingList(removeBugIndAll, paramAll);


%% Construct array to be used for SVM for the GFP and RFP channel

tLAll = cell(2,1);
for nC= 1:2
    for i=1:length(trainingListAll{nC});
        tLAll{nC}= [tLAll{nC}; trainingListAll{nC}{i}];
    end
    Y{nC} = tLAll{nC}(:,4); Ynom{nC} = nominal(Y{nC}==1);
    tLAll{nC} = tLAll{nC}(:,1:3);
    
end

%% Use SVM for classifier

nC = 2;
figure;
numKeptSpots = sum(Y{nC}==1);
boxCon = [4*ones(numKeptSpots,1); 0.5*ones(size(tLAll{nC},1)-numKeptSpots,1)];
svmStruct = svmtrain(tLAll{nC}(:,1:2), Ynom{nC}, 'showplot', true, 'Kernel_Function', 'linear', 'boxconstraint', boxCon);

svmStruct = svmtrain(tLAll{nC}(:,1:3), Ynom{nC}, 'showplot', true, 'Kernel_Function', 'linear', 'boxconstraint', boxCon);



end


    function [trainingListAll, rPropAll] = createTrainingList(removeBugIndAll, paramAll)
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
            
            for nC=1:size(sClass,2)
                remInd = find(sClass(:,nC)==1);
                
                for i=1:length(remInd)
                    nS = remInd(i);
                    fileRoot = [paramAll{nF}.dataSaveDirectory '\singleBacCount'];
                    
                    rProp = load([fileRoot, '\bacCount', num2str(nS), '.mat']);
                    rProp = rProp.rProp; rProp = rProp{nC};
                    %Remove spots that were manually segmented.
                    keptSpots = setdiff(1:length(rProp), removeBugIndAll{nF}{nS, nC});
                    
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
                    
                    
               
                    
                    %Not best place to put in index, but it'll do for now
                    for i=1:length(rProp)
                        rProp(i).ind = i;
                    end
                    
                    %Use cutoffs applied to our data-currently hardwired in, but this
                    %should be an input.
                    
                    colorThresh = [0,0];
                    areaThresh = [3,3];
                    
                    rPropClassified = rProp([rProp.Area]>areaThresh(nC));
                    
                    rPropClassified = rPropClassified([rPropClassified.MeanIntensity]>colorThresh(nC));
                    
                    %Finding out which spots were removed by the above thresholds
                    keptSpots = intersect(keptSpots, [rPropClassified.ind]);
                    
                    removedSpots = [removedSpots, setdiff([rProp.ind], [rPropClassified.ind])];
                    
                    removedSpots = unique(removedSpots);
                    
                    
                    %Remove spots that are past the autofluorescent region
                    %from both classifiers
                    insideGut = find([rProp.gutRegion]<=3);
                    keptSpots = intersect(keptSpots, insideGut);
                    
                    removedSpots = intersect(removedSpots, insideGut);
                    
                    
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
                    
                    
                    rPropAll{nC}{tlNum(nC)} = rProp([keptSpots, removedSpots]);
                    tlNum(nC) = tlNum(nC) + 1;
                  %  figure; plot(trainingListAll{1}{tlNum(nC)-1}(:,1))
                    
                end
                
                
            end
            
            
        end
    end


