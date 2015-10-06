% Script which manually obtains amplitudes from gut motility data,
% subtracts off quiescent noise from final number

theFolder=uigetdir('Where is the analyzed gut data located?');
theFileName=dir(strcat(theFolder,filesep,'analyzedGutData*.mat'));
uiopen(strcat(theFolder,filesep,theFileName(1).name),true);

%% Find median wave amplitude

% Initialize variables
smoothSize=3;
totalTimeFraction=1; % Use 1 if all
%fractionOfTimeStart=size(gutMeshVelsPCoords,4); % Use size(gutMeshVelsPCoords,4) if all
fractionOfTimeStart=size(x); %*****
markerNumStart=1;
%markerNumEnd=size(gutMesh,2); % Use size(gutMesh,2) if all
%erx=int16(size(gutMeshVelsPCoords,4)/fractionOfTimeStart:(size(gutMeshVelsPCoords,4)/(fractionOfTimeStart)+size(gutMeshVelsPCoords,4)/totalTimeFraction-1));
%surfL=squeeze(-mean(gutMeshVelsPCoords(:,markerNumStart:markerNumEnd,1,erx),1));
%velVectMaxes=max(surfL,[],1);
velVectMaxes=x; %*****
notAGoodDataSet=true;
titleSpacer=31;

while notAGoodDataSet
    
    % Plot results to obtain parameters
    plot(velVectMaxes,'k-');hold on;
    smoothedVelVectMaxes=smooth(velVectMaxes,smoothSize);
    plot(smoothedVelVectMaxes,'b-');hold off;
    %title(texlabel(strcat('The folder is: ',theFolder)));
    [xes, ~]=ginput(4);
    %dlgAns=inputdlg({'How many maxima should I find?: ','Distance between waves?: ','Fish number?: '},strcat('The folder is: ',theFolder),[1, length(theFolder)+titleSpacer],{'10','80','1'});
    dlgAns=inputdlg({'How many maxima should I find?: ','Distance between waves?: ','Fish number?: '},'The folder is: ',[1, 40 + titleSpacer],{'10','80','1'});
    % close;
    
    roughHowManyWaves=str2double(dlgAns(1));
    localMaxesIndices=zeros(1,roughHowManyWaves);
    localMaxIndex=1;
    wavePeriodFrames=str2double(dlgAns(2));
    fishNum=str2double(dlgAns(3));
    [sortedMaxima,sortedMaximaIndices]=sort(smoothedVelVectMaxes,'descend'); % Sort velocities based on magnitude, also save the corresponding indices
    
    % Find maxima
    for i=1:length(sortedMaxima)
        inQ=sortedMaximaIndices(i); % Descend down list of maximum velocities indices
        thoseOutOfRangeMaybe=(abs(inQ-localMaxesIndices)>=wavePeriodFrames/2); % Compare with previously obtained list of maxima indices. Is the new index too close or is it out of range and thus acceptable?
        thoseNotEqualToThemselves=thoseOutOfRangeMaybe(abs(inQ-localMaxesIndices)~=inQ); % Be careful though: Any equal to themselves must be discarded (since it came from the zeros in our array)
        if isempty(thoseNotEqualToThemselves) % If empty, our list started off as empty! Populate it!
            localMaxesIndices(localMaxIndex)=sortedMaximaIndices(i);
            localMaxIndex=localMaxIndex+1;
        elseif min(thoseNotEqualToThemselves)==1 % If the list is cleared for all values (thus none can be 0, otherwise logical 0), this new value is a local maxima!
            localMaxesIndices(localMaxIndex)=sortedMaximaIndices(i);
            localMaxIndex=localMaxIndex+1;
        end
        if localMaxIndex>roughHowManyWaves % We only obtain the first (roughHowManyWaves) local maxima
            break;
        end
    end
    
    % Plot results to make sure
    plot(velVectMaxes,'k-');hold on;
    plot(smoothedVelVectMaxes,'b-');
    plot(localMaxesIndices,smoothedVelVectMaxes(localMaxesIndices),'ro');hold off;
    %title(texlabel(strcat('The folder is: ',theFolder)));
    
    wasItGoodData=menu('Do you like what you see?','Yes','No');
    
    if wasItGoodData==1
        notAGoodDataSet=false;
    end
    
end

% Obtain results
averageMaxVelocities=mean(smoothedVelVectMaxes(localMaxesIndices));
stdWaveAmps=std(smoothedVelVectMaxes(localMaxesIndices));
rmsWaveAmps=averageMaxVelocities/sqrt(2);
rmsQuiescentAmps=rms([smoothedVelVectMaxes(floor(xes(1)):ceil(xes(2)));smoothedVelVectMaxes(floor(xes(3)):ceil(xes(4)))]);
stdQuiescentAmps=std([smoothedVelVectMaxes(floor(xes(1)):ceil(xes(2)));smoothedVelVectMaxes(floor(xes(3)):ceil(xes(4)))]);