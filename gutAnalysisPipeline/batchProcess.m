%batchProcess: Go through a series of different fish directories and do the
%same batch process task on each
%
% exact format for this code needs to be thought through more.
% USAGE: batchProcess(commandList)
%
% INPUT: commandList: cell array containing strings of commands to execut
% Each string must have the format : sampleFunction(a, b, *), where * is
% the wildcard indicating the location for the param file to load. This
% code is somewhat in flux.
%

function [] = batchProcess(commandList)

files = uipickfiles;

for nF=1:length(files)
    thisFileBase = files(nF); thisFileBase = thisFileBase{1};
    
    % Find the subdirectory that contains the param.mat file
    cd(thisFileBase);
    thisFileRoot = rdir('**\*param.mat');
    thisFileRoot = thisFileRoot(1).name; %Should be able to load multiple files, but not right now.
    fileDir = [thisFileBase filesep thisFileRoot];
%  fileDir = [thisFile filesep 'gutOutline' filesep 'param.mat'];
  input = load(fileDir);
  param = input.param;
  
  disp(['Batch processing: ', param.directoryName])
  for nC = 1: length(commandList)
    ind = regexp(commandList{nC}, '[*]');
    thisCommand = [commandList{nC}(1:ind-1), 'param', commandList{nC}(ind+1:end)];
    eval(thisCommand);
      
ba  end
end

end
