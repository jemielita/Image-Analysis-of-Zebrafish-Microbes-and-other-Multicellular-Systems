%analyzeGutSingleRegion: analyze features of a certain region of the gut.
%The exact ordering of filtering and analysis is chosen by the user.
%
%USAGE regFeatures = analyzeGutSingleRegion(param, cutNum,analysisType,
%                    scanNum, colorList)
%
%INPUT param: experimental parameters
%      cutNum: which cut of the gut to analyze (from param.cutVal)
%      analysisType: structure with n entries where each entry is a
%      particular step in the analysis protocol
%      analysisType(i).name: name of the filtering or analysis we will do
%      this region of the gut
%      analysisType(i).param: cell array that contains all parameters
%      needed to do this filtering/analysis
%      analysisType(i).return = true or false: return this part of the
%      analysis. If not set then regFeatures{i} will be empty
%      scanNum: which scan number to analyze
%      colorList: cell array containing all colors to analyze. If colorList
%      = 'all', then all colors will be analyzed
%OUTPUT regFeatures: cell array with n entries that give the results of
%       each step of the analysis.
%    ex. analysisType.Name = 'lineDist'
%        analysisType.return = 'true'
%     regFeatures then contains the intensity curve as a function of the
%     length of the gut
%
%AUTHOR: Matthew Jemielita, August 3, 2012

function regFeatures = analyzeGutSingleRegion(param,cutNum,analysisType,...
    scanNum, colorList)

%% Loading in parameters for analyzing this scan
%Load in this region
imVar.color = colorList;
imVar.zNum = '';
imVar.scanNum = scanNum;

totNumSteps = length(analysisType);

regFeatures = cell(totNumSteps,length(colorList));

%Repeating analysis for each color.
%mlj: Should switch things up a bit to make it easier to do 2-color
%analysis on large data stacks. But this can wait for now.
for colorNum =1:length(colorList)
    color = colorList{colorNum};
    %% Loading in image stack
    [imStack, centerLine, gutMask] = constructRotRegion(cutNum, scanNum, color, param);

    %Just for testing the code structure
%     gutMask = '';
%     imStack = '';
%     
 
    totNumSteps = length(analysisType);
    
    %% Doing all the analysis steps
    
    for stepNum = 1:totNumSteps
        regFeatures{stepNum, colorNum} = ...
            analysisStep(imStack, centerLine, gutMask, analysisType,regFeatures,...
            stepNum);      
    end
    
    
end


%% Discard entries in regFeatures
% Remove entries that we don't want to keep
for stepNum = 1:totNumSteps
    for colorNum =1:length(colorList)
        
        if(analysisType(stepNum).return==false)
            regFeatures{stepNum,colorNum} = [];
        end
    end
end


end


%Large switch function that contains all the analysis functions that we've
%worked on so far
function regFeatures = analysisStep(imStack, centerLine, gutMask,...
    analysisType, regFeatures, stepNum)

switch analysisType(stepNum).name
    case 'radialProjection'
        %mlj: Need to build in support for preallocating arrays
        regFeatures = radialProjection(imStack, centerLine, gutMask);
        
    case 'linearIntensity'
        regFeatures = intensityCurve(imStack, gutMask);
    
    case 'radialDistribution'
        %Find the point in this analysis chain where we calculate the
        %radial projections
        
        %Use previously calculated radial projections
        ind = analysisType(stepNum).param.father;
        if(~strcmp(analysisType(ind).name, 'radialProjection'))
            fprintf(2, 'radialDistribution error: Pointer to radial projections is incorrect!');
            error = 1;
            return
        else
           regFeatures = radDistAll(regFeatures{ind}, centerLine, ...
               analysisType(stepNum).param);
        end
        
    case 'test'
        regFeatures = 1:length(centerLine);
end


%mlj: need to deal with saving the results appropriately.

end

function intenR = radDistAll(radIm, centerLine, analParam)
radBin = analParam.binSize;

ind = 1:length(radIm);

%Calculating the radial distribution for each of these regions.
intenR = arrayfun(@(x) radDist(radIm{x},  radBin), ind,...
    'UniformOutput', false);
%mlj: should we make the end result a matrix?

end