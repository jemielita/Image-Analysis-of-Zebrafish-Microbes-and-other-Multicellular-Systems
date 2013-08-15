%combineBacPop: Combine together data taken from different takes
%into one structure
%
% USAGE rProp = combineBacPop(takeData, trainingList);
%
% INPUT
%      takeData: nx1 structure containing the following fields"
%               takeData(n).fileDir: directory containing single bacteria
%               numbers
%               takeData(n).scanRange: [sMin, sMax]-range of scans to
%               combine together
%               takeDat(n).colorNum: number of colors
%     trainingList: (optional) cell array with takeDat.colorNum of fields
%     containing training data for the linear classifier for the different
%     colors.
%
% OUTPUT
%       rPropAll: combined # of Scans x by # of colors cell array containing
%       information about each found bacteria.
%
% AUTHOR: Matthew Jemielita, Aug 10, 2013


function rPropAll = combineBacPop(takeData,varargin)


switch nargin
    case 1
        tlIn = load('D:\HM21_Aeromonas_July3_EarlyTimeInoculation\fish3\gutOutline\cullProp\rProp.mat');
        trainingList{1} = tlIn.allData;
        
        tlIn = load(['D:\HM21_Aeromonas_July3_EarlyTimeInoculation\fish2\gutOutline\cullProp' filesep 'rProp.mat']);
        trainingList{2} = tlIn.allData;
        
    case 2
        
        for i=1:length(trainingListLoc)
            tlIn = load(trainingListLoc{1});
            trainingList{i} = tlIn.allData;
        end
        
end

scanAllNum = 1;

%Find threshold for autofluorescent cells based on what would cull 95% of
%identified cells in this region.
autoFluorMaxInten = findAutoFluorCutoff();

for takeNum = 1:length(takeData)
    
    minS = takeData(takeNum).scanRange(1); maxS = takeData(takeNum).scanRange(2);
    maxC = takeData(takeNum).colorNum;
    fileDir = takeData(takeNum).fileDir;
    
    for scanNum=minS:maxS
        
        for colorNum=1:maxC
            rProp = load([fileDir filesep 'singleBacCount'...
                filesep 'bacCount' num2str(scanNum) '.mat']);
            rProp = rProp.rProp;
            
            rProp = rProp{colorNum};
            
            
            %Some bug somewhere else doesn't properly label all bacteria
            for i=1:length(rProp)
                if(isempty(rProp(i).gutRegion))
                    rProp(i).gutRegion = 6;
                end
            end
            
            %In the display apply a harsher threshold for the spots found in
            %the autofluorescent region.
            if(isfield(rProp, 'gutRegion'))
                inAutoFluor = [rProp.gutRegion]==3;
                outsideAutoFluor = ~inAutoFluor;
                %Remove low intensity points in this region
                inAutoFluorRem = [rProp.MeanIntensity]>autoFluorMaxInten(colorNum);
                inAutoFluor = and(inAutoFluor,inAutoFluorRem);
                
                keptSpots = or(outsideAutoFluor, inAutoFluor);
                rProp = rProp(keptSpots);
                
            end
            
            rProp = bacteriaLinearClassifier(rProp, trainingList{colorNum});
            
            %Not really the correct place to do this, but find empty gut
            %locations and set them to 6-a.k.a undefiniable at this point
            for i=1:length(rProp)
                if(isempty(rProp(i).gutRegion))
                    rProp(i).gutRegion = 6;
                end
            end
            
            %Remove spots that are past the autofluorescent region
            insideGut = find([rProp.gutRegion]<=3);
            rProp = rProp(insideGut);
             
            rPropAll{scanAllNum, colorNum} = rProp;
            
        end
        scanAllNum = scanAllNum+1;
    end
    
    
end




    function autoFluorMaxInten = findAutoFluorCutoff()
        %Go through scans and find only spots found in the autofluorescent region
        %Use these to find a threshold that
        takeNum = 1;
        
        minS = takeData(takeNum).scanRange(1);
        maxC = takeData(takeNum).colorNum;
        fileDir = takeData(takeNum).fileDir;
        
        scanNum = minS;
        for colorNum=1:maxC
            rProp = load([fileDir filesep 'singleBacCount'...
                filesep 'bacCount' num2str(scanNum) '.mat']);
            rProp = rProp.rProp;
            
            rProp = rProp{colorNum};
            
            rProp = bacteriaLinearClassifier(rProp, trainingList{colorNum});
            rProp = rProp([rProp.gutRegion]==3);
            
            meanList = sort([rProp.MeanIntensity]);
            ind = round(0.95*length(meanList));
            
            autoFluorMaxInten(colorNum) = meanList(ind);
            
        end
        
    end

end


