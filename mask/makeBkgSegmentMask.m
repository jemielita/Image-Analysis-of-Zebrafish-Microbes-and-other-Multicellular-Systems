%makeBkgSegmentMask(param): Make the estimated background intensity
%segmented mask for all time points
%
% INPUT: param: parameter file for fish
%        scanNum: (optional, default all)
%        colorNum: (optional, default all)
% AUTHOR: Matthew Jemielita, March 24, 2014

function [] = makeBkgSegmentMask(param, varargin)

if(nargin==1)

    sList = 1: length(param.regionExtent.polyAll);
    cList = 1: length(param.color);
    
else
    sList = varargin{1};
    cList = varargin{2};
end




for i=1:length(sList);
    nS = sList(i);
    % inputVar = load([param.dataSaveDirectory filesep 'masks' filesep 'maskUnrotated_' num2str(nS) '.mat']);
    
    
    fprintf(1, ['Making mask for scan ', num2str(nS)]);
    for j=1:length(cList)
        nC = cList(j);
        
        fprintf(1, '.');
       segMask =  bkgSegment(nS, nC, param);
        
        save([param.dataSaveDirectory filesep 'bkgEst' filesep 'bkgEst_' param.color{nC} '_nS_' num2str(nS) '.mat'], 'segMask', '-v7.3');
    end
    fprintf(1, '\n');
    
end

end

