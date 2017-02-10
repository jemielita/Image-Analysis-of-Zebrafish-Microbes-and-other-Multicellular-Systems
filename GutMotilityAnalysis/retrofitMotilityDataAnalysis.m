% Function which...
%
% To do:

function retrofitMotilityDataAnalysis(varargin)

%% Initialize directory variables
if( nargin ~= 2 )
    mainExperimentDirectory = uigetdir(pwd, 'Main experiment directory containing image data'); % Main directory containing the subfolders with the images you want to analyze
    mainAnalysisDirectory = uigetdir(pwd, 'Main directory to contain/currently containing analysis'); % Directory to contain/currently containing the analysis from the images (if folder name <analysisFolderName> isn't there, creates it)
else
    mainExperimentDirectory = varargin{1};
    mainAnalysisDirectory = varargin{2};
end

%% Initialize variables
% Obtain all directory contents, total number of directories
[mainExperimentDirectoryContents, mainExperimentSubDirectoryContentsCell, ~] = obtainDirectoryStructure(mainExperimentDirectory);
[mainAnalysisDirectoryContents, mainAnalysisSubDirectoryContentsCell, ~] = obtainDirectoryStructure(mainAnalysisDirectory);
nSubDirectories = size(mainExperimentDirectoryContents, 1);

% Determine if analysis directory already exists, and if not, make it (keep
% in mind that if it exists then it must have the same structure as the 
% image data directories)
determineIfAnalysisFoldersExistsElseCreateThem;

% Open or create the main currentAnalysesPerformed.mat file
[currentAnalysisPerformed, analysisVariables] = openOrCreateCurrentAnalysesPerformedFile; %#ok since analysisVariables are saved
analysisToPerform = currentAnalysisPerformed;

% Progress bar
progtitle = sprintf('Preparing to retrofit old analysis...');
progbar = waitbar(0, progtitle);  % will display progress

%% Loop through all subdirectories
for i=1:nSubDirectories
    
    % Progress bar update
    waitbar(i/nSubDirectories, progbar, ...
        sprintf('Retrofitting folder %d of %d', i, nSubDirectories));
    
    % Obtain the current directory size
    nSubSubDirectories = size(analysisToPerform(i).bools, 1);
    
    % Loop through all checked subdirectories
    for j=1:nSubSubDirectories
        
        % Obtain current experiment directory
        curExpDir = strcat(mainExperimentDirectory, filesep, mainExperimentDirectoryContents(i).name, filesep, mainExperimentSubDirectoryContentsCell{1, i}(j).name);
        curAnDir = strcat(mainAnalysisDirectory, filesep, mainExperimentDirectoryContents(i).name, filesep, mainExperimentSubDirectoryContentsCell{1, i}(j).name);
        
        %% Load in and copy raw PIV data
        % Identify all the previous PIVData*.mats
        curDirFiles = dir(strcat(curExpDir, filesep, 'DeconstructedImages', filesep, 'PIVData*.mat'));
        
        % If there are any, copy them
        if(~isempty(curDirFiles))
            
            % Save into rawPIVOutput_Current.mat, rawPIVOutput_<date>.mat
            for k=1:size(curDirFiles, 1)
                allTheJunk = load(strcat(curExpDir, filesep, 'DeconstructedImages', filesep, curDirFiles(k).name));
                p = allTheJunk.p; %#ok since I'm saving below
                s = allTheJunk.s; %#ok since I'm saving below
                x = allTheJunk.x; %#ok since I'm saving below
                y = allTheJunk.y; %#ok since I'm saving below
                u = allTheJunk.u; %#ok since I'm saving below
                v = allTheJunk.v; %#ok since I'm saving below
                typevector = allTheJunk.typevector; %#ok since I'm saving below
                filenames = allTheJunk.filenames; %#ok since I'm saving below
                u_filt = allTheJunk.u_filt; %#ok since I'm saving below
                v_filt = allTheJunk.v_filt; %#ok since I'm saving below
                typevector_filt = allTheJunk.typevector_filt; %#ok since I'm saving below
                dateStringToUse = curDirFiles(k).name(9:end-4);
                save(strcat(curAnDir, filesep, 'rawPIVOutputName_', dateStringToUse), 'p', 's', 'x', 'y', 'u', 'v', 'typevector', 'filenames', 'u_filt', 'v_filt', 'typevector_filt');
            end
            if(size(curDirFiles, 1) > 1)
                disp(strcat('Saving rawPIVOutputName', dateStringToUse, ' as current'));
            end
            save(strcat(curAnDir, filesep, 'rawPIVOutputName_Current'), 'p', 's', 'x', 'y', 'u', 'v', 'typevector', 'filenames', 'u_filt', 'v_filt', 'typevector_filt');
            
            % Update currentAnalysisPerformed
            currentAnalysisPerformed(i).bools(j,1) = true;
            
            % Save currentAnalysisPerformed.mat
            save(strcat(mainAnalysisDirectory, filesep, 'currentAnalysesPerformed.mat'),'currentAnalysisPerformed','analysisVariables'); % WARNING: If currentAnalysisPerformed name is changed, you'll have to manually change this string IN MANY LOCATIONS!!!
        end
        
        %% Load in and copy mask data
        % Identify all the previous maskVars_*.mats
        curDirFiles = dir(strcat(curExpDir, filesep, 'maskVars_*.mat'));
        
        % If there are any, copy them
        if(~isempty(curDirFiles))
            
            % Save into maskVars_Current.mat, maskVars_<date>.mat
            for k=1:size(curDirFiles, 1)
                allTheJunk = load(strcat(curExpDir, filesep, curDirFiles(k).name));
                gutOutline = allTheJunk.gutOutline; %#ok since I'm saving below
                gutOutlinePoly = allTheJunk.gutOutlinePoly; %#ok since I'm saving below
                gutMiddleTop = allTheJunk.gutMiddleTop; %#ok since I'm saving below
                gutMiddleBottom = allTheJunk.gutMiddleBottom; %#ok since I'm saving below
                gutMiddlePolyTop = allTheJunk.gutMiddlePolyTop; %#ok since I'm saving below
                gutMiddlePolyBottom = allTheJunk.gutMiddlePolyBottom; %#ok since I'm saving below
                dateStringToUse = curDirFiles(k).name(10:end-4);
                save(strcat(curAnDir, filesep, 'maskVars_', dateStringToUse), 'gutOutline', 'gutOutlinePoly', 'gutMiddleTop', 'gutMiddleBottom', 'gutMiddlePolyTop', 'gutMiddlePolyBottom');
            end
            save(strcat(curAnDir, filesep, 'maskVars_Current'), 'gutOutline', 'gutOutlinePoly', 'gutMiddleTop', 'gutMiddleBottom', 'gutMiddlePolyTop', 'gutMiddlePolyBottom');
            
            % Update currentAnalysisPerformed
            currentAnalysisPerformed(i).bools(j,2) = true;
            
            % Save currentAnalysisPerformed.mat
            save(strcat(mainAnalysisDirectory, filesep, 'currentAnalysesPerformed.mat'),'currentAnalysisPerformed','analysisVariables'); % WARNING: If currentAnalysisPerformed name is changed, you'll have to manually change this string IN MANY LOCATIONS!!!
        end
        
        %% Load in and copy processed data
        % Identify all the previous analyzedGutData*.mats
        curDirFiles = dir(strcat(curExpDir, filesep, 'analyzedGutData*.mat'));
        
        % If there are any, copy them
        if(~isempty(curDirFiles))
            
            % Save into processedPIVOutput_Current.mat, processedPIVOutput_<date>.mat
            for k=1:size(curDirFiles, 1)
                allTheJunk = load(strcat(curExpDir, filesep, curDirFiles(k).name));
                gutMesh = allTheJunk.gutMesh; %#ok since I'm saving below
                mSlopes = allTheJunk.mSlopes; %#ok since I'm saving below
                gutMeshVels = allTheJunk.gutMeshVels; %#ok since I'm saving below
                gutMeshVelsPCoords = allTheJunk.gutMeshVelsPCoords; %#ok since I'm saving below
                thetas = allTheJunk.thetas; %#ok since I'm saving below
                dateStringToUse = curDirFiles(k).name(16:end-4);
                save(strcat(curAnDir, filesep, 'processedPIVOutput_', dateStringToUse), 'gutMesh', 'mSlopes', 'gutMeshVels', 'gutMeshVelsPCoords', 'thetas');
            end
            save(strcat(curAnDir, filesep, 'processedPIVOutput_Current'), 'gutMesh', 'mSlopes', 'gutMeshVels', 'gutMeshVelsPCoords', 'thetas');
            
        end
        
        %% Load in and copy analysis data
        
        % I'm forcing the user to do this manually since they generate new
        % plots from the new method.
        
    end
    
end

close(progbar);

%% Auxiliary functions

% obtainDirectoryStructure returns directory structures given a directory
function [mainDirectoryContents, mainSubDirectoryContentsCell, directoryStructuresCorrect] = obtainDirectoryStructure(mainDirectory)

    % Initialize variables
    directoryStructuresCorrect = true;
    
    % Obtain main directory structure
    mainDirectoryContents = dir(mainDirectory); % Obtain all main directory contents
    mainDirectoryContents(~[mainDirectoryContents.isdir]) = []; % Remove non-directories
    mainDirectoryContents(strncmp({mainDirectoryContents.name}, '.', 1)) = []; % Removes . and .. and hidden files
    nSubDirectories = size(mainDirectoryContents, 1);
    mainSubDirectoryContentsCell = cell(1, nSubDirectories);
    
    % Loop through all sub-directory contents to obtain contents
    if(nSubDirectories > 0)
        for ii = 1:nSubDirectories
            
            % Obtain main directory structure
            mainSubDirectoryContents = dir(strcat(mainDirectory, filesep, mainDirectoryContents(ii).name)); % Obtain all sub-directory contents
            mainSubDirectoryContents(~[mainSubDirectoryContents.isdir]) = []; % Remove non-directories
            mainSubDirectoryContents(strncmp({mainSubDirectoryContents.name}, '.', 1)) = []; % Removes . and .. and hidden files
            mainSubDirectoryContentsCell{ii} = mainSubDirectoryContents;
            
            % Check for contents, exit and show error message if empty
            nSubSubDirectories = size(mainSubDirectoryContents, 1);
            if(nSubSubDirectories == 0)
                directoryStructuresCorrect = false;
            end
            
        end
    else
        % No directories, there is obviously a problem
        directoryStructuresCorrect = false;
    end
    
end

% determineIfAnalysisFoldersExistsElseCreateThem name should be obvious
function determineIfAnalysisFoldersExistsElseCreateThem

    % Initialize variables
    directoryAlreadyExists = true;
    
    % Check if the directories are equal
    directoryContentsSameBool = isequal(mainAnalysisDirectoryContents,mainExperimentDirectoryContents);
    
    % Check if the subdirectories are equal
    nMainExperimentSubDirs = size(mainExperimentSubDirectoryContentsCell, 2);
    nMainAnalysisSubDirs = size(mainAnalysisSubDirectoryContentsCell, 2);
    if( (nMainExperimentSubDirs == nMainAnalysisSubDirs)&&(size(mainAnalysisSubDirectoryContentsCell,2)>0) )
        
        for ii=1:nMainExperimentSubDirs
            
            if(~isequal({mainExperimentSubDirectoryContentsCell{ii}.name},{mainAnalysisSubDirectoryContentsCell{ii}.name}))
                
                subDirectoryContentsSameBool = false;
                directoryAlreadyExists = false;
                
            end
            
        end
        
    else
        subDirectoryContentsSameBool = false;
        directoryAlreadyExists = false;
    end
    
    % If analysis directory doesn't perfectly match, make them
    if(~directoryAlreadyExists)
        
        % Match the contents of each directory
        if(~directoryContentsSameBool)
            
            % Check the ith directory
            for ii=1:nMainExperimentSubDirs
                
                % Check if the ith directory exists, and if not, make it
                curDirectoryAlreadyExistsInt = exist(strcat(mainAnalysisDirectory,filesep,mainExperimentDirectoryContents(ii).name),'dir');
                if(curDirectoryAlreadyExistsInt ~= 7)
                    mkdir(strcat(mainAnalysisDirectory,filesep,mainExperimentDirectoryContents(ii).name));
                end
                
            end
            
        end
            
        % Match the contents of each subdirectory
        if( ~subDirectoryContentsSameBool )
            
            % Loop through the directories
            for ii=1:nMainExperimentSubDirs
                
                % And check each jth subdirectory
                for jj=1:size(mainExperimentSubDirectoryContentsCell{ii},1)
                    % Check if the jth subdirectory exists, and if not, make it
                    curSubDirectoryAlreadyExistsInt = exist(strcat(mainAnalysisDirectory,filesep,mainExperimentDirectoryContents(ii).name,filesep,mainExperimentSubDirectoryContentsCell{1,ii}(jj).name),'dir');
                    if(curSubDirectoryAlreadyExistsInt ~= 7)
                        mkdir(strcat(mainAnalysisDirectory,filesep,mainExperimentDirectoryContents(ii).name,filesep,mainExperimentSubDirectoryContentsCell{1,ii}(jj).name));
                    end
                    
                end
                
                
            end
            
        end
        
    end
    
end

% openOrCreateCurrentAnalysesPerformedFile loads the record of which
% analysis has been performed or, if this is done for the first time,
% creates the folder
function [currentAnalysisPerformed, analysisVariables] = openOrCreateCurrentAnalysesPerformedFile
    
    % Obtain file structure
    currentAnalysesPerformedFileName = 'currentAnalysesPerformed.mat';
    nAnalysisCheckboxTypes = 6;
    analysisFile = dir(strcat(mainAnalysisDirectory, filesep, currentAnalysesPerformedFileName));
    
    % If the structure is non-empty, load the file, otherwise make it
    if(~isempty(analysisFile))
        
        currentAnalysisFile = load(strcat(mainAnalysisDirectory, filesep, currentAnalysesPerformedFileName)); % WARNING: Do not change this variable name without changing the save string below
        currentAnalysisPerformed = currentAnalysisFile.currentAnalysisPerformed;
        analysisVariables = currentAnalysisFile.analysisVariables;
        
    else
        
        % Determine how the file should be organized: structure with
        % booleans for each subfolder representing which analysis is done
        nSubDirectories = size(mainExperimentDirectoryContents,1);
        for ii=1:nSubDirectories
            currentAnalysisPerformed(ii).directory = mainExperimentDirectoryContents(ii).name; %#ok since size of structure is small % WARNING: Do not change this variable name without changing the save strings below
            nSubSubDirectories = size(mainExperimentSubDirectoryContentsCell{1, ii}, 1);
            currentAnalysisPerformed(ii).bools = false(nSubSubDirectories, nAnalysisCheckboxTypes); %#ok since size of structure is small
            currentAnalysisPerformed(ii).bools(:, nAnalysisCheckboxTypes) = true; %#ok since size of structure is small
            % Record the order of the bools
            for jj=1:nSubSubDirectories
                currentAnalysisPerformedSubDirs(jj).subDirectories = mainExperimentSubDirectoryContentsCell{1, ii}(jj).name; %#ok since size of structure is small
            end
            currentAnalysisPerformed(ii).subDirectories = currentAnalysisPerformedSubDirs; %#ok since size of structure is small
        end
        
        % Save this file for future reference, update after any analysis
        analysisVariables = {'*.tif','-1','-1','-1','-1'};
        save(strcat(mainAnalysisDirectory, filesep, currentAnalysesPerformedFileName),'currentAnalysisPerformed','analysisVariables'); % WARNING: If currentAnalysisPerformed name is changed, you'll have to manually change this string  IN MANY LOCATIONS!!!
        
    end
    
end

end