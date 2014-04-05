%clump3dSegThreshTimeSeries: Do clump analysis for all time points for a
%particular fish
%
% USAGE [] = clump3dSegThreshTimeSeries(param)
% Results are all (currently) saved to individual locations in the folder.

function [] = clump3dSegThreshTimeSeries(param)

[sL, cL] = createSCList(param);

arrayfun(@(x,y)clump3dSegThreshAll(param, x,y, true), sL, cL);

end