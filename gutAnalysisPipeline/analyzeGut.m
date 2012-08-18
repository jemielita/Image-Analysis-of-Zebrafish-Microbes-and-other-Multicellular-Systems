% analyzeGutScan: Run a variety of different analysis procedures on a series of
% images of zebrafish gut. This program is written so that it should be
% possible to easily add in different analysis protocols later in time.
%
%

function regFeatAll = analyzeGut(analysisType, scanParam, param)

imVar.scanNum = scanParam.scanNum;
imVar.color = scanParam.color;

totNumColor = length(scanParam.color);

totNumCut = size(param.cutVal,1);
totNumSteps = length(analysisType);

%Cell array that will contain all the results of our calculation
regFeat = cell(totNumCut,1);

for cutNum=1:totNumCut
 regFeat{cutNum} = analyzeGutSingleRegion(param, cutNum, analysisType,...
     scanParam.scanNum, scanParam.color);
end


%% Unpack the results

%Find number of saved analysis steps
analInd = find([analysisType.return]==true);
totNumSteps = length(analInd);
lineLength = size(param.centerLine,1);
regFeatAll = cell(totNumColor,totNumSteps, lineLength);


%% Save the results
for colorNum=1:totNumColor;
    for stepNum=1:totNumSteps
        
        %Now unpack the result
        for cutNum=1:totNumCut
            
            thisCut = param.cutVal{cutNum,1}(1):param.cutVal{cutNum,1}(2);
            
            for i=1:length(thisCut)
                regFeatAll{colorNum,stepNum, thisCut(i)} = ...
                    regFeat{cutNum}{analInd(stepNum),colorNum};
            end
        
        end
    end
end


end