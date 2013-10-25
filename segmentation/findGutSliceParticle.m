%findGutSliceParticle: Find the slice in the gut that each of the found
%spots is located in.
% NOTE: I'm sure this code is written somewhere else also, but I can't seem
% to find it.
%
% AUTHOR: Matthew Jemielita, Oct. 21, 2013

function [] = findGutSliceParticle(param)

minS = 1;
maxS = param.expData.totalNumberScans;

bacDir = [param.dataSaveDirectory filesep 'singleBacCount'];

fprintf(1, 'Updating bacteria slice numbers');
for nS = minS:maxS
   cL = param.centerLineAll{nS};
   
   inputVar = load([bacDir filesep 'bacCount' num2str(nS) '.mat']);
   rProp = inputVar.rProp;
   
   pos = [rProp.CentroidOrig];
   pos = reshape(pos, 3, length(pos)/3);
   pos = pos(1:2,:);
   pos = pos';
   
   %Distance of all points to the center line
   
   clDist = dist(pos, cL');
   [minVal,ind] = min(clDist,[],2);
   
   
   for i=1:length(rProp)
       rProp(i).sliceNum = ind;
   
       ri = param.gutRegionsInd(nS,:);
       rProp(i).gutRegion = find(ind(i)>ri, 1, 'last');
   end

   
   %Save result
   save([bacDir filesep 'bacCount' num2str(nS) '.mat'], 'rProp');
   
   
   fprintf(1, '.');
end
fprintf(1, '\n');

end