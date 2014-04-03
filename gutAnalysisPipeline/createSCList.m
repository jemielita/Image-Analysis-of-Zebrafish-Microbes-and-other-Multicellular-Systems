%createSCList: Create exhaustive integer list of scans and colors to
%analyze
%
% USAGE [sL, cL] = createSCList(param)
%
% AUTHOR Matthew Jemielita, April 2, 2014

function [sL, cL] =createSCList(param)

sList = 1:param.expData.totalNumberScans;
cN = length(param.color);

sL = repmat(sList,cN,1);sL = sL(:);
cL = repmat((1:cN)', length(sList),1);cL = cL(:);
end