% Function which...
%
% To do: Change variables saved

function obtainMotilityMasks(mainExperimentDirectory, mainExperimentDirectoryContents, mainExperimentSubDirectoryContentsCell, mainAnalysisDirectory, analysisToPerform, analysisVariables, currentAnalysesPerformedFileName, maskFileOutputName)

%% Initialize variables
nDirectories = size(analysisToPerform, 2);
currentAnalysisFile = load(strcat(mainAnalysisDirectory, filesep, currentAnalysesPerformedFileName)); % WARNING: Do not change this variable name without changing the save string below
currentAnalysisPerformed = currentAnalysisFile.currentAnalysisPerformed; % WARNING: Don't change this variable name

%% Loop through all checked directories to obtain image masks
for i=1:nDirectories
    
    % Obtain the current directory size
    nSubDirectories = size(analysisToPerform(i).bools, 1);
    
    % Loop through all checked subdirectories to perform PIV
    for j=1:nSubDirectories
        
        % If we want to analyze it, do so, else skip
        if(analysisToPerform(i).bools(j,2) && analysisToPerform(i).bools(j,6))
            
            % ObtainCurrentDirectory
            curDir = strcat(mainExperimentDirectory, filesep, mainExperimentDirectoryContents(i).name, filesep, mainExperimentSubDirectoryContentsCell{1, i}(j).name);
            
            % Perform mask creation
            [gutOutline, gutOutlinePoly, gutMiddleTop, gutMiddleBottom, gutMiddlePolyTop, gutMiddlePolyBottom] = obtainMotilityMask(curDir, analysisVariables{1}, str2double(analysisVariables{5})); %#ok since it is saved WARNING: Don't change these variable names
            
            % Save rawPIVOutput_Current.mat, rawPIVOutput_<date>.mat
            save(strcat(mainAnalysisDirectory, filesep, mainExperimentDirectoryContents(i).name, filesep, mainExperimentSubDirectoryContentsCell{1, i}(j).name, filesep, maskFileOutputName, '_Current'), 'gutOutline', 'gutOutlinePoly', 'gutMiddleTop', 'gutMiddleBottom', 'gutMiddlePolyTop', 'gutMiddlePolyBottom');
            save(strcat(mainAnalysisDirectory, filesep, mainExperimentDirectoryContents(i).name, filesep, mainExperimentSubDirectoryContentsCell{1, i}(j).name, filesep, maskFileOutputName, '_', date), 'gutOutline', 'gutOutlinePoly', 'gutMiddleTop', 'gutMiddleBottom', 'gutMiddlePolyTop', 'gutMiddlePolyBottom');
            
            % Update currentAnalysisPerformed
            currentAnalysisPerformed(i).bools(j,2) = true;
            
            % Save currentAnalysisPerformed.mat
            save(strcat(mainAnalysisDirectory, filesep, currentAnalysesPerformedFileName),'currentAnalysisPerformed','analysisVariables'); % WARNING: If currentAnalysisPerformed name is changed, you'll have to manually change this string IN MANY LOCATIONS!!!
            
        end
    end
    
end

end