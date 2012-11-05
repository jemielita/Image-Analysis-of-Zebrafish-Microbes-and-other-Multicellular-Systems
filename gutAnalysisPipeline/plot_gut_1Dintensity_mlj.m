%Wrapper for plot_gut_1D to extract almost all information from the param
%and scanParam mat files

function plot_gut_1Dintensity_mlj(param, scanParam,timeInfo)

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
for nC=1:size(param.bkgInten,2)
    meanVal = param.bkgInten(:,nC,1);
    meanVal(meanVal==0) = [];
    gutBkg(nC,1) = mean(meanVal);
    stdVal = param.bkgInten(:,nC,2);
    stdVal(stdVal==0) = [];
    gutBkg(nC,2) = std(stdVal);
    
    %Threshold cutoff for both channels will be 1 std dev above background
    threshCutoff(nC) = ...
        find(abs(intensitybins-gutBkg(nC,1)-gutBkg(nC,2))==min(abs(intensitybins-gutBkg(nC,1)-gutBkg(nC,2))));
    
end

maxPlotPos = Inf; %For now-need to add code to mark the end of the gut

bacteriaVolume = 1;

surfplotfilenamebase = '';

%Get average total intensity for a bacteria in either channel. This will be
%used to set the relative intensity of the two different 

if(isfield(param, 'bacInten'))
    for nC=1:size(param.bkgInten,2)
        bacInten(nC) = mean(param.bacInten{:,nC}.sum);
    end
    greenRedIntensity = bacInten(1)/bacInten(2);   
else
    greenRedIntensity = 7;%Raghu measured this awhile back...probably not particularly accurate from sample to sample
end

%Running the 1D plotting code
plot_gut_1Dintensity(timeInfo, threshCutoff, intensitybins, timestep, ...
    boxWidth, maxPlotPos, greenRedIntensity, bacteriaVolume, surfplotfilenamebase)

end