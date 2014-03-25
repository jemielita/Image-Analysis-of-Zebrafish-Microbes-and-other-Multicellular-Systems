%makeBkgSegmentMask(param): Make the estimated background intensity
%segmented mask for all time points
%
% INPUT: param: parameter file for fish
%
% AUTHOR: Matthew Jemielita, March 24, 2014

function [] = makeBkgSegmentMask(param)

maxS = length(param.regionExtent.polyAll);
maxC = length(param.color);

for nS=1:maxS
    
    % inputVar = load([param.dataSaveDirectory filesep 'masks' filesep 'maskUnrotated_' num2str(nS) '.mat']);
    
    
    fprintf(1, ['Making mask for scan ', num2str(nS)]);
    for nC=1:maxC
        fprintf(1, '.');
       segMask =  bkgSegment(nS, nC, param);
        
        save([param.dataSaveDirectory filesep 'bkgEst' filesep 'bkgEst_' param.color{nC} '_nS_' num2str(nS) '.mat'], 'segMask', '-v7.3');
    end
    fprintf(1, '\n');
    
end

end

