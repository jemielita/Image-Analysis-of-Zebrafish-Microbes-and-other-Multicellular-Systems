%Generate a structure for our scan parameters than can be run using the
%PSOM pipeline framework

function [pipeline, scanParam] = createAnalysisPipeline(analysisType, scanParamAll, param)

%scanList = scanParamAll.scanList;
scanList = 1:6;


command = 'b = cumsum(rand(100,c))';

pipeline.loadParam.command = 'load(files_in); save(files_out, ';

for sN = 1:length(scanList)
   
    %Get features of this particular scan
    scanParam(sN).color = scanParamAll.color;
    scanParam(sN).scanNum = sN;
    %Need to include new center line here
    
    %Set the command for this scan
    commandAnalyze = ['regFeat = analyzeGut(analysisType, scanParam(',...
        num2str(sN), '), param;'];
    commandLoad = 'load(files_in);';
    command = [commandLoad commandAnalyze];
  %  command = 'b = cumsum(rand(100,c))';
    thisScan = ['pipeline.scan', num2str(sN)];

    eval([thisScan, '.command = command']);
    paramDir = 'C:\temp2\gutA.mat';
    eval([thisScan, '.files_in = load(''', paramDir, '''); ']);
    
    %    eval([thisScan, '.files_in{1} = analysisType;']);
    %eval([thisScan, '.files_in{2} = scanParam;']);
    %eval([thisScan, '.files_in{3} = param;']);
    
    


end

end