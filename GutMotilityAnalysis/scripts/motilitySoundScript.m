% Converts motility into sound
% Assumes gutMesh, gutMeshVelsPCoords exist

totalTimeFraction=1; % Use 1 if all
fractionOfTimeStart=size(gutMeshVelsPCoords,4); % Use size(gutMeshVelsPCoords,4) if all
markerNumStart=1;
sinDensity = 100;
markerNumEnd=size(gutMesh,2); % Use size(gutMesh,2) if all
translateMarkerNumToMicron=0.1625*round(mean(diff(squeeze(gutMesh(1,:,1,1))))); %Units of Micron/Marker
abscissaValues=(markerNumStart-1)*translateMarkerNumToMicron:(markerNumEnd-1)*translateMarkerNumToMicron;
ordinateValues= int16((size(gutMeshVelsPCoords,4)/fractionOfTimeStart):(size(gutMeshVelsPCoords,4)/(fractionOfTimeStart)+size(gutMeshVelsPCoords,4)/totalTimeFraction-1));
surfaceValues=squeeze(-mean(gutMeshVelsPCoords(:,markerNumStart:markerNumEnd,1,ordinateValues),1));
theSound = zeros(1,sinDensity*size(surfaceValues, 2));

for i=1:size(surfaceValues, 2)
    for j=1:size(surfaceValues, 1)
        sinSound = sin(linspace(0, 3.141592*j/4, sinDensity));
        theSound((sinDensity*(i-1) + 1):sinDensity*i) = theSound((sinDensity*(i-1) + 1):sinDensity*i) + sinSound*surfaceValues(j,i);
    end
end

sound(theSound,44100)
theSoundDensity100SoundOver4 = theSound;