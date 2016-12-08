% Function which...
%
% To do:

function retrofitMotilityDataAnalysis(mainExperimentDirectory, mainExperimentDirectoryContents, mainExperimentSubDirectoryContentsCell, mainAnalysisDirectory, analysisToPerform, analysisVariables, currentAnalysesPerformedFileName, motilityParametersOutputName, rawPIVOutputName, interpolationOutputName, GUISize)

%% Initialize variables
nDirectories = size(analysisToPerform, 2);
currentAnalysisFile = load(strcat(mainAnalysisDirectory, filesep, currentAnalysesPerformedFileName)); % WARNING: Do not change this variable name without changing the save string below
currentAnalysisPerformed = currentAnalysisFile.currentAnalysisPerformed; % WARNING: Don't change this variable name

% Progress bar
progtitle = sprintf('Preparing to retrofit old analysis...');
progbar = waitbar(0, progtitle);  % will display progress

%% Loop through all checked directories to perform analysis on motility
for i=1:nDirectories
    
    % Progress bar update
    waitbar(i/nDirectories, progbar, ...
        sprintf('Retrofitting folder %d of %d', i, nDirectories));
    
    % Obtain the current directory size
    nSubDirectories = size(analysisToPerform(i).bools, 1);
    
    % Loop through all checked subdirectories
    for j=1:nSubDirectories
        
        % Obtain current experiment directory
        curExpDir = strcat(mainExperimentDirectory, filesep, mainExperimentDirectoryContents(i).name, filesep, mainExperimentSubDirectoryContentsCell{1, i}(j).name);
        
        %% Load in and copy raw PIV data
        % Load all the previous analyzedGutData*.mat names
        curDirFiles = dir(curExpDir, 'analyzedGutData*.mat');
        
        % If there are any, copy them
        if(~isempty(curDirFiles))
            
            % Save into rawPIVOutput_Current.mat, rawPIVOutput_<date>.mat
            for k=1:size(curDirFiles, 1)
                load(curDirFiles(k).name);
                dateStringToUse = curDirFiles(k).name(16:end-4);
                save(strcat(mainAnalysisDirectory, filesep, mainExperimentDirectoryContents(i).name, filesep, mainExperimentSubDirectoryContentsCell{1, i}(j).name, filesep, rawPIVOutputName, '_', dateStringToUse), 'p', 's', 'x', 'y', 'u', 'v', 'typevector', 'imageDirectory', 'filenames', 'u_filt', 'v_filt', 'typevector_filt');
            end
            save(strcat(mainAnalysisDirectory, filesep, mainExperimentDirectoryContents(i).name, filesep, mainExperimentSubDirectoryContentsCell{1, i}(j).name, filesep, rawPIVOutputName, '_Current'), 'p', 's', 'x', 'y', 'u', 'v', 'typevector', 'imageDirectory', 'filenames', 'u_filt', 'v_filt', 'typevector_filt');
            
            % Update currentAnalysisPerformed
            currentAnalysisPerformed(i).bools(j,1) = true;
            
            % Save currentAnalysisPerformed.mat
            save(strcat(mainAnalysisDirectory, filesep, currentAnalysesPerformedFileName),'currentAnalysisPerformed','analysisVariables'); % WARNING: If currentAnalysisPerformed name is changed, you'll have to manually change this string IN MANY LOCATIONS!!!
        end
        
        %% Load in and copy mask data
        
        %% Load in and copy processed data
        
        %% Load in and copy analysis data
        
    end
    
end

close(progbar);

end