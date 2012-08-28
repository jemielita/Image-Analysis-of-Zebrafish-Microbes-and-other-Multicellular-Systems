% analyzeGutScan: Run a variety of different analysis procedures on a series of
% images of zebrafish gut. This program is written so that it should be
% possible to easily add in different analysis protocols later in time.
%
%

function regFeatAll = analyzeGut(analysisType, scanParam, param)


%Cell array that will contain all the results of our calculation
totNumCut = size(param.cutVal,1);

regFeat = cell(totNumCut,1);

for cutNum=1:totNumCut
 regFeat{cutNum} = analyzeGutSingleRegion(param, cutNum, analysisType,...
     scanParam.scanNum, scanParam.color);
end

%% Unpack the results

%Find number of saved analysis steps
analInd = find([analysisType.return]==true);
totNumSteps = length(analInd);
totNumColor = length(scanParam.color);

lineLength = size(param.centerLineAll{scanParam.scanNum},1);
regFeatAll = cell(totNumColor,totNumSteps, lineLength);

%% Save the results

for colorNum=1:totNumColor;
    for stepNum=1:totNumSteps
        
        %Store entry as either a cell or an array
        if(iscell(regFeat{cutNum}{analInd(stepNum),colorNum}))
            regFeatAll{colorNum, stepNum} = cell(lineLength,1);
        else
            regFeatAll{colorNum, stepNum} = zeros(lineLength,1);
        end
        
        %Now unpack the result
        for cutNum=1:totNumCut
            thisCut = param.cutVal{cutNum,1}(1):param.cutVal{cutNum,1}(2);
            
            if(iscell(regFeat{cutNum}{analInd(stepNum),colorNum}))
                for i=1:length(thisCut)
                    regFeatAll{colorNum,stepNum}{thisCut(i)} = ...
                        regFeat{cutNum}{analInd(stepNum),colorNum}{thisCut(i)};
                end
                
            else
                regFeatAll{colorNum,stepNum}(thisCut) = ...
                    regFeat{cutNum}{analInd(stepNum),colorNum};
            end
            
        end
        
    end
end



end



