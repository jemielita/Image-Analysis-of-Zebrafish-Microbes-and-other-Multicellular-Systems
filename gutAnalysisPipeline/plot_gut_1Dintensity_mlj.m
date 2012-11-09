%Wrapper for plot_gut_1D to extract almost all information from the param
%and scanParam mat files

function plot_gut_1Dintensity_mlj(param, scanParam,timeInfo,bkgThresh,surfplotfilenamebase)

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

%Get mean and std dev. of gut background signal
for i=1:size(param.bkgIntenAll,1)
    for nC=1:size(param.bkgInten,2)
        if(isnan(param.bkgIntenAll(i,nC,1))&&i~=1&&~isnan(param.bkgIntenAll(i-1,nC,1)))
           param.bkgIntenAll(i,nC,1) = param.bkgIntenAll(i-1,nC,1);
           param.bkgIntenAll(i,nC,2) = param.bkgIntenAll(i-1,nC,2);          
        elseif(isnan(param.bkgIntenAll(i,nC,1))&&i~=size(param.bkgIntenAll,1)&&~isnan(param.bkgIntenAll(i+1,nC,1)))
            param.bkgIntenAll(i,nC,1) = param.bkgIntenAll(i+1,nC,1);
            param.bkgIntenAll(i,nC,2) = param.bkgIntenAll(i+1,nC,2);
        end
   
    meanVal = param.bkgInten(nC,1);
    gutBkg(nC,1) = param.bkgIntenAll(i,nC,1);
    gutBkg(nC,2) = param.bkgIntenAll(i,nC,2);
    
    %Threshold cutoff for both channels will be 1 std dev above background
    threshCutoff(i,nC) = ...
        find(abs(intensitybins-gutBkg(nC,1)-bkgThresh*gutBkg(nC,2))==min(abs(intensitybins-gutBkg(nC,1)-bkgThresh*gutBkg(nC,2))));
    end 
end
maxPlotPos = Inf; %For now-need to add code to mark the end of the gut

bacteriaVolume = 1;

%Get average total intensity for a bacteria in either channel. This will be
%used to set the relative intensity of the two different 

if(isfield(param, 'bacInten'))
    for nC=1:size(param.bacInten,2)
        temp = [];
        for i=1:size(param.bacInten,1)
            if(isfield(param.bacInten{i,nC}, 'sum'))
                temp = [temp [param.bacInten{i,nC}.sum]];
            end
        end  
        temp(temp==0) = [];
        bacInten(nC) = nanmean(temp);
    end
    greenRedIntensity = bacInten(1)/bacInten(2);   
else
    greenRedIntensity = 7;%Raghu measured this awhile back...probably not particularly accurate from sample to sample
end


%%% Figure out cutoff point to exclude stuff past the endpoint of the gut
%%% and stuff past the autofluorescent cells

endPosList = zeros(length(scanParam.scanList),1);
fluorPosList = zeros(length(scanParam.scanList),1);

for i=1:max(scanParam.scanList)
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