%findGutRegionMaskNumber: Find the mask numbers corresponding to different regions
%of the gut as marked by the user.
%
% USAGE: gutRegionsInd = findGutRegionMaskNumber(param, updateParam)
% INPUT: param: parameter file for this fish
%        updateParam: if true update the param file to include the field.
%        gutRegionsInd.
%        The field gutRegionsInd is a maxS x 5 structure containing for
%        each scan the index contains the 1

function varargout = findGutRegionMaskNumber(param, updateParam)

minS = 1;
maxS = param.expData.totalNumberScans;

%Check inputs
necessaryFields = ...
    {'beginGutPos','endBulbPos','autoFluorPos', 'autoFluorEndPos','endGutPos'};
for nF =1:length(necessaryFields)
   if(~isfield(param, necessaryFields{nF}))
       fprintf(2, ['Param must contain the field: ', necessaryFields{nF}, '!']);
       return;
   end
   
   if(ismember(0, param.(necessaryFields{nF})))
      fprintf(2, ['Field ', necessaryFields{nF} ' has not been fully updated yet!']);
      return;
   end

       
end


analysisParameters = load([param.dataSaveDirectory filesep 'analysisParam.mat']);
centerLineAll = analysisParameters.param.centerLineAll;

for nS = minS:maxS
    thisCL = centerLineAll{nS};
    
    for nF =1:length(necessaryFields)
        thisF = param.(necessaryFields{nF});
        thisF = thisF(nS,:);
        allDist = (thisCL(:,1)-thisF(1)).^2 + (thisCL(:,2)-thisF(2)).^2;
        [~,ind] =min(allDist);
        param.gutRegionsInd(nS,nF) = ind;
    end
end

%Outputing data and saving if necessary
if(nargout==1)
   varargout{1} = param.gutRegionsInd; 
end


if(updateParam==true)
   save([param.dataSaveDirectory filesep 'param.mat'],'param');
end

end