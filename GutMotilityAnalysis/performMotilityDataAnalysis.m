% Function which...
%
% To do:

function performMotilityDataAnalysis(mainExperimentDirectoryContents, mainExperimentSubDirectoryContentsCell, mainAnalysisDirectory, analysisToPerform, analysisVariables, currentAnalysesPerformedFileName, motilityParametersOutputName, interpolationOutputName, GUISize)

%% Initialize variables
nDirectories = size(analysisToPerform, 2);
currentAnalysisFile = load(strcat(mainAnalysisDirectory, filesep, currentAnalysesPerformedFileName)); % WARNING: Do not change this variable name without changing the save string below
currentAnalysisPerformed = currentAnalysisFile.currentAnalysisPerformed; % WARNING: Don't change this variable name

% Progress bar
progtitle = sprintf('Preparing for analysis...');
progbar = waitbar(0, progtitle);  % will display progress

%% Loop through all checked directories to perform analysis on motility
for i=1:nDirectories
    
    % Progress bar update
    waitbar(i/nDirectories, progbar, ...
        sprintf('Performing analysis for folder %d of %d', i, nDirectories));
    
    % Obtain the current directory size
    nSubDirectories = size(analysisToPerform(i).bools, 1);
    
    % Loop through all checked subdirectories to perform PIV
    for j=1:nSubDirectories
        
        % If we want to analyze it, do so, else skip
        if(analysisToPerform(i).bools(j,4) && analysisToPerform(i).bools(j,6))
            
            % ObtainCurrentDirectory
            curDir = strcat(mainAnalysisDirectory, filesep, mainExperimentDirectoryContents(i).name, filesep, mainExperimentSubDirectoryContentsCell{1, i}(j).name);
            
            % Perform mask creation
            [fftPowerPeak, fftPeakFreq, fftRPowerPeakSTD, fftRPowerPeakMin, fftRPowerPeakMax, waveFrequency, waveSpeedSlope, BByFPS, sigB, waveFitRSquared, xCorrMaxima, analyzedDeltaMarkers, waveAverageWidth] = obtainMotilityParameters(curDir, analysisVariables, interpolationOutputName, GUISize); %#ok since it is saved WARNING: Don't change these variable names
            
            % Save rawPIVOutput_Current.mat, rawPIVOutput_<date>.mat
            save(strcat(mainAnalysisDirectory, filesep, mainExperimentDirectoryContents(i).name, filesep, mainExperimentSubDirectoryContentsCell{1, i}(j).name, filesep, motilityParametersOutputName, '_Current'), 'fftPowerPeak', 'fftPeakFreq', 'fftRPowerPeakSTD', 'fftRPowerPeakMin', 'fftRPowerPeakMax', 'waveFrequency', 'waveSpeedSlope', 'BByFPS', 'sigB', 'waveFitRSquared', 'xCorrMaxima', 'analyzedDeltaMarkers', 'waveAverageWidth');
            save(strcat(mainAnalysisDirectory, filesep, mainExperimentDirectoryContents(i).name, filesep, mainExperimentSubDirectoryContentsCell{1, i}(j).name, filesep, motilityParametersOutputName, '_', date), 'fftPowerPeak', 'fftPeakFreq', 'fftRPowerPeakSTD', 'fftRPowerPeakMin', 'fftRPowerPeakMax', 'waveFrequency', 'waveSpeedSlope', 'BByFPS', 'sigB', 'waveFitRSquared', 'xCorrMaxima', 'analyzedDeltaMarkers', 'waveAverageWidth');
            
            % Update currentAnalysisPerformed
            currentAnalysisPerformed(i).bools(j,4) = true;
            
            % Save currentAnalysisPerformed.mat
            save(strcat(mainAnalysisDirectory, filesep, currentAnalysesPerformedFileName),'currentAnalysisPerformed','analysisVariables'); % WARNING: If currentAnalysisPerformed name is changed, you'll have to manually change this string IN MANY LOCATIONS!!!
            
        end
    end
    
end

close(progbar);

end