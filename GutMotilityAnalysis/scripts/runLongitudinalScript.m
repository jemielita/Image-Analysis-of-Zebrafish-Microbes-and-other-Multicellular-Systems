% Script which runs the motilityParametersOverTime given just a directory:
%
% Requires dirB be defined

mainAnalysisDirectory = dirB;

% Obtain main directory structure
mainDirectoryContents = dir(mainAnalysisDirectory); % Obtain all main directory contents
mainDirectoryContents(~[mainDirectoryContents.isdir]) = []; % Remove non-directories
mainDirectoryContents(strncmp({mainDirectoryContents.name}, '.', 1)) = []; % Removes . and .. and hidden files
nSubDirectories = size(mainDirectoryContents, 1);
mainSubDirectoryContentsCell = cell(1, nSubDirectories);

for i = 1:nSubDirectories
    
    % Obtain main directory structure
    mainSubDirectoryContents = dir(strcat(mainAnalysisDirectory, filesep, mainDirectoryContents(i).name)); % Obtain all sub-directory contents
    mainSubDirectoryContents(~[mainSubDirectoryContents.isdir]) = []; % Remove non-directories
    mainSubDirectoryContents(strncmp({mainSubDirectoryContents.name}, '.', 1)) = []; % Removes . and .. and hidden files
    mainSubDirectoryContentsCell{i} = mainSubDirectoryContents;
    
    % Check for contents, exit and show error message if empty
    nSubSubDirectories = size(mainSubDirectoryContents, 1);
    if(nSubSubDirectories == 0)
        directoryStructuresCorrect = false;
    end
    
end

currentlyPerformedAnalysisFile = load(strcat(mainAnalysisDirectory, filesep, 'currentAnalysesPerformed.mat'));
analysisVariables = currentlyPerformedAnalysisFile.analysisVariables;
analysisToPerform = currentlyPerformedAnalysisFile.currentAnalysisPerformed;

motilityParametersOverTime(mainAnalysisDirectory, mainDirectoryContents, mainSubDirectoryContentsCell, analysisToPerform, analysisVariables);