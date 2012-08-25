% analyzeGutScan: Run a variety of different analysis procedures on a series of
% images of zebrafish gut. This program is written so that it should be
% possible to easily add in different analysis protocols later in time.
%
%

function regFeatAll = analyzeGut(analysisType, scanParam, param)


%% Resize the center line size to reflect the sample spacing we want to run our analysis at
param.centerLineAll{scanParam.scanNum} =...
    smoothCurve(param.centerLineAll{scanParam.scanNum},scanParam.stepSize);
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

%Reparameterize the curve to change the spacing between points we're
%sampling the gut at.
function poly = smoothCurve(poly, stepSize)
%Parameterizing curve in terms of arc length
t = cumsum(sqrt([0,diff(poly(:,1)')].^2 + [0,diff(poly(:,2)')].^2));
%Find x and y positions as a function of arc length
polyFit(:,1) = spline(t, poly(:,1), t);
polyFit(:,2) = spline(t, poly(:,2), t);

polyT(:,2) = interp1(t, polyFit(:,2),min(t):stepSize:max(t),'spline', 'extrap');
polyT(:,1) = interp1(t, polyFit(:,1),min(t):stepSize:max(t), 'spline', 'extrap');

%Redefining poly
poly = cat(2, polyT(:,1), polyT(:,2));

end