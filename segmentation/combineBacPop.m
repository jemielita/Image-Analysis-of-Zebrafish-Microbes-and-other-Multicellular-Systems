%combineBacPop: Combine together data taken from different takes
%into one structure
%
% USAGE rProp = combineBacPop(takeData);
% 
% INPUT
%      takeData: nx1 structure containing the following fields"
%               takeData(n).fileDir: directory containing single bacteria
%               numbers
%               takeData(n).scanRange: [sMin, sMax]-range of scans to
%               combine together
%               takeDat(n).colorNum: number of colors
%
% OUTPUT
%       rPropAll: combined # of Scans x by # of colors cell array containing
%       information about each found bacteria.
%
% AUTHOR: Matthew Jemielita, Aug 10, 2013


function rPropAll = combineBacPop(takeData,varargin)

switch nargin 
    case 1
        trainingList = load(['D:\HM21_Aeromonas_July3_EarlyTimeInoculation\fish2\gutOutline\cullProp' filesep 'rProp.mat']);
    case 2
        trainingList = load(trainingListLoc);     
end
trainingList = trainingList.allData;

scanAllNum = 1;

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
                autoFluorMaxInten  = 300; %According the pixel values, most of these are fake
                inAutoFluorRem = [rProp.MeanIntensity]>autoFluorMaxInten;
                inAutoFluor = and(inAutoFluor,inAutoFluorRem);
                
                keptSpots = or(outsideAutoFluor, inAutoFluor);
                rProp = rProp(keptSpots);
                
            end
            

            
            switch colorNum
                case 1
                    cullProp.radCutoff = [10 3];
                    cullProp.minRadius = 2;
                    cullProp.minInten = 200;
                    cullProp.minArea = 5;
                    rProp = cullFoundBacteria(rProp, '', cullProp, '', '');
                    
                    
                case 2
                    rProp = bacteriaLinearClassifier(rProp, trainingList);
            end
            
                
            %Not really the correct place to do this, but find empty gut
            %locations and set them to 6-a.k.a undefiniable at this point
            for i=1:length(rProp)
                if(isempty(rProp(i).gutRegion))
                    rProp(i).gutRegion = 6;
                end
            end
            
            
        rPropAll{scanAllNum, colorNum} = rProp;

        end
        scanAllNum = scanAllNum+1;
    end
    
    
end




end


