% analyzeGutScan: Run a variety of different analysis procedures on a series of
% images of zebrafish gut. This program is written so that it should be
% possible to easily add in different analysis protocols later in time.
%
%

function regFeatAll = analyzeGut(analysisType, scanParam, param,...
    centerLine, gutMask)


%Cell array that will contain all the results of our calculation
totNumCut = size(param.cutVal,1);

regFeat = cell(totNumCut,1);

for cutNum=1:totNumCut
 regFeat{cutNum} = analyzeGutSingleRegion(param, cutNum, analysisType,...
     scanParam.scanNum, scanParam.color,scanParam,...
     centerLine{cutNum}, gutMask{cutNum});
end
%% Unpack the results

%Find number of saved analysis steps
analInd = find([analysisType.return]==true);
totNumSteps = length(analInd);
totNumColor = length(scanParam.color);

lineLength = size(param.centerLineAll{scanParam.scanNum},1);
regFeatAll = cell(totNumColor,totNumSteps);

%% Save the results

for colorNum=1:totNumColor;
    for stepNum=1:totNumSteps
        
        %Unpack differently for different calculations
        
        switch analysisType(stepNum).name
            case 'spotDetection'
                for cutNum=1:totNumCut
                   regFeatAll{colorNum, stepNum}{cutNum} = regFeat{cutNum}; 
                end
                
                %Additionally transfer the result to the folder
                %'singleBacCount' after doing slightly more processing.
                bacteriaCountTimeSeries(param, 'firstpass', 'defaultCullProp', scanParam.scanNum, regFeat)
                
                
            otherwise
                %Store entry as either a cell or an array
                if(iscell(regFeat{1}{analInd(stepNum),colorNum}))
                    regFeatAll{colorNum, stepNum} = cell(lineLength,1);
                else
                    
                    firstEl = param.cutVal{1,1}(1);
                    numEl = size(regFeat{1}{analInd(stepNum),colorNum}(firstEl,:),2);
                    regFeatAll{colorNum, stepNum} = zeros(lineLength,numEl);
                end
                
                %Now unpack the result
                for cutNum=1:totNumCut
                    thisCut = param.cutVal{cutNum,1}(1):param.cutVal{cutNum,1}(2);
                    
                    %MESSSY~!!!!!!JKH!@LK!@H
                    if(iscell(regFeat{cutNum}{analInd(stepNum),colorNum}))
                        for i=1:length(thisCut)
                            regFeatAll{colorNum,stepNum}{thisCut(i)} = ...
                                regFeat{cutNum}{analInd(stepNum),colorNum}{i};
                        end
                        
                    else
                        
                        val =  regFeat{cutNum}{analInd(stepNum),colorNum};
                        ind = find(sum(val,2)~=0);
                        thisCut = thisCut(ind);
                        %Only update values that are not-equal to zero.
                        regFeatAll{colorNum,stepNum}(thisCut,:) = val(ind,:);
                    end
                    
                end
        end
        
    end
end





clearvars -except regFeatAll;
end



