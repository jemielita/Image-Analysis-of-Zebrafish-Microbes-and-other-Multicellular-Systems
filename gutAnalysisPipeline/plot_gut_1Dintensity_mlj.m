%Wrapper for plot_gut_1D to extract almost all information from the param
%and scanParam mat files

function plot_gut_1Dintensity_mlj(param, threshCutoff,scanParam,timeInfo,surfplotfilenamebase,greenRedIntensity)

if(isfield(scanParam, 'binSize'))
    intensitybins = scanParam.binSize;
else
    fprintf(1, 'Setting bin size to default');
    intensitybins = 100:100:4000;
end

if(isfield(scanParam, 'stepSize'))
    boxWidth = scanParam.stepSize;
else
    fprintf(1, 'Setting bin size to default 5 microns');
    boxWidth = 5;
end

timestep = param.expData.pauseTime/60;

maxPlotPos = Inf; %For now-need to add code to mark the end of the gut

bacteriaVolume = 1;

%Get average total intensity for a bacteria in either channel. This will be
%used to set the relative intensity of the two different 


%%% Figure out cutoff point to exclude stuff past the endpoint of the gut
%%% and stuff past the autofluorescent cells

endPosList = zeros(length(scanParam.scanList),1);
fluorPosList = zeros(length(scanParam.scanList),1);

for i=1:max(scanParam.scanList)
    
    if(~isfield(param, 'autoFluorPos'))
        endPosList(i) = length(param.centerLineAll{i});
        continue;
    end
    
    %Extend list of points at end of gut and at the begin. of the autofluor. necessary
    if(i>size(param.autoFluorPos,1));
        param.autoFluorPos(i,:) = param.autoFluorPos(i-1,:);
    end
    
    if(i>size(param.endGutPos,1));
        param.endGutPos(i,:) = param.endGutPos(i-1,:);
    end
    
    %If entry is zero find closest non-zero entry and replace this entry
    %with that
    if(sum(param.endGutPos(i,:))==0)
        ind = find(sum(param.endGutPos,2));
        [~,minInd] = min(abs(ind-i));
        param.endGutPos(i,:) = param.endGutPos(minInd,:);
    end
    if(sum(param.autoFluorPos(i,:))==0)
        ind = find(sum(param.autoFluorPos,2));
        [~,minInd] = min(abs(ind-i));
        param.autoFluorPos(i,:) = param.autoFluorPos(minInd,:);
    end
    
    endPos = param.centerLineAll{i}-repmat(param.endGutPos(i,:), length(param.centerLineAll{i}),1);
    endPos = sum(endPos.^2,2);
    [~,ind] = min(endPos);
    
    ind = length(param.centerLineAll{i});
    endPosList(i) = ind;
    
%     fluorPos = param.centerLineAll{i}-repmat(param.autoFluorPos(i,:), length(param.centerLineAll{i}),1);
%     fluorPos = sum(fluorPos.^2,2);
%     [~,ind] = min(fluorPos);
%     fluorPosList(i) = ind;
end
   
%Running the 1D plotting code
plot_gut_1Dintensity(timeInfo, threshCutoff, intensitybins, timestep, ...
    boxWidth, endPosList, greenRedIntensity, bacteriaVolume, ...
    surfplotfilenamebase,min(scanParam.scanList),max(scanParam.scanList), param.dataSaveDirectory)

end