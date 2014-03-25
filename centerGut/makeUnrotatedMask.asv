%makeUnrotatedMask: Make a series of unrotated masks for different gut
%regions
%
% AUTHOR: Matthew Jemielita, March 20, 2014

function [] = makeUnrotatedMask(param)

maxS = length(param.regionExtent.polyAll);

for nS=1:maxS
    
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

