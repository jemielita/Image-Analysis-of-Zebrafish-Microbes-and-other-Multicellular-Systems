%clumpAnalysis: Constrct an appropriate filter for the segmentation of
%clumps in the gut of a fish.
%
% AUTHOR: Matthew Jemielita, March 20, 2014


function [] = clumpAnalysis(scanNum, colorNum, param)


im = loadMIP(param, scanNum, colorNum);

end

function im = loadMIP(param, scanNum, colorNum)
colorList = {'488nm', '568nm'};
im  = load([param.dataSaveDirectory filesep 'FluoroScan_' num2str(scanNum) '_' colorList{colorNum} '.tiff']);
    
end