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

function regFeatures = analyzeGutSingleRegion(param, cutNum,analysisType,...
    scanNum, colorList)

%Load in this region
imVar.color = '488nm';
imVar.zNum = '';
imVar.scanNum = scanNum;

[imStack, centerLine, gutMask] = constructRotRegion(cutNum, scanNum, '488nm', param); 

totNumSteps = length(analysisType);
regFeatures = cell(totNumSteps,1);

for stepNum = 1:totNumSteps
  % regFeatures{stepNum} = analysisStep(
    
    
end



end