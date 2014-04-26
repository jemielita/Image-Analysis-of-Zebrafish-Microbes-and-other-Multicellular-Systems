%makeUnrotatedMask: Make a series of unrotated masks for different gut
%regions
% INPUT: param: parameter file for fish
%        scanNum: (optional, default all)
% AUTHOR: Matthew Jemielita, March 20, 2014

function [] = makeUnrotatedMask(param, varargin)

if(nargin==1)
    sList = 1: length(param.regionExtent.polyAll);    
else
    sList = varargin{1};
end

for i=1:length(sList);
    nS = sList(i);
   % inputVar = load([param.dataSaveDirectory filesep 'masks' filesep 'maskUnrotated_' num2str(nS) '.mat']);
   
       fprintf(1, ['Making mask for scan ', num2str(nS), '\n']); 
        poly = param.regionExtent.polyAll{nS};
        imSize = param.regionExtent.regImSize{1};
        gutMask = poly2mask(poly(:,1), poly(:,2), imSize(1), imSize(2));
         
        cl = param.centerLineAll{nS};
        gutMask = curveMask(gutMask, cl,'', 'rectangle');
        
        save([param.dataSaveDirectory filesep 'masks' filesep 'maskUnrotated_' num2str(nS) '.mat'], 'gutMask', '-v7.3');
    
end

end

