% The goal of this function is to transform sets of images which depict
% complex, multicellular motility into velocity vector fields which are 
% representative of that motion. To do so, the function loops through 
% several directories to do the following:
%   - Allow the user to define a region of interest and define an axis of 
%   symmetry of a set of multipage tiff stacks
%   - Perform Particle Image Velocimetry (PIV) on the multipage tiff stacks
%   using PIVLab to output a velocity vector field
%   - Transform the velocity vector field into new coordinates defined by
%   the geometry of the region of interest and the axis of symmetry
%   - Analyze this new "primed" velocity vector field for amplitude, 
%   frequency, etc.
% The program assumes *.tif image files.
%
% Inputs:- mainExperimentDirectory (Optional): Directory containing the raw
%            image data. Input 0 if you don't want to use it. Prompts for
%            directory if one isn't given. Push cancel if you don't want to
%            use it.
%        - mainAnalysisDirectory (Optional):   Directory that will/does 
%            contain the analyzed data. Prompts for directory if one isn't 
%            given.
%
% Immediate to do: Create PIVVideoParams
%                  (X) Make function which will retrofit old data analysis
%                  Make remaining buttons work
%                  More user defined parameters for plots, PIV video, etc.
%                  Allow user to open this even without the exp dir
%                  Scroll bar for GUI!
%
% To do: Don't assume *.tif? If so, make button function
%        Super minor: change folder width if they get too squished together?
%        Save the parameters used for analysis in each fish subfolder
%        Output a .csv in addition to the current fishparams<date>.mat
%        load manually currated experiment data (e.g. times), plot data
%        Adjust the video/image buttons to autoscale
%        Make variable fields not accept letters
%        Change comments in analysis functions to match their function...

%% Main Function
function analyzeMotility( varargin )

%% Initialize variables

% Initialize directory variables
if( nargin ~= 2 )
    mainExperimentDirectory = uigetdir(pwd, 'Main experiment directory containing image data'); % Main directory containing the subfolders with the images you want to analyze
    mainAnalysisDirectory = uigetdir(pwd, 'Main directory to contain/currently containing analysis'); % Directory to contain/currently containing the analysis from the images (if folder name <analysisFolderName> isn't there, creates it)
else
    mainExperimentDirectory = varargin{1};
    mainAnalysisDirectory = varargin{2};
end
usingExperimentDirectory = strcmp(num2str(mainExperimentDirectory),'0');
imageFileType = '*.tif'; % Currently redundant (but still necessary), see analysisVariables{1}
currentAnalysesPerformedFileName = 'currentAnalysesPerformed.mat';
rawPIVOutputName = 'rawPIVOutputName'; % WARNING: Don't change this variable name
maskFileOutputName = 'maskVars'; % WARNING: Don't change this variable name
interpolationOutputName = 'processedPIVOutput'; % WARNING: Don't change this variable name
motilityParametersOutputName = 'motilityParameters'; % WARNING: Don't change this variable name
PIVOutputName = 'PIVAnimation'; % WARNING: Don't change this variable name
nAnalysisCheckboxTypes = 6;

% Initialize GUI variables
startGUI = [1, 1]; % X and Y location of the GUI corner (current units, default is pixels)
screensize = get(groot, 'Screensize'); % Obtain current computer display dimensions
widthGUI = screensize(3) - startGUI(1) - 100; % Define GUI width
heightGUI = screensize(4) - startGUI(2) - 146; % Define GUI height (146 is an empirical number representing my system tray's height)
GUISize = [startGUI(1), startGUI(2), widthGUI, heightGUI]; % Combine parameters for GUI location and dimensions
panelBufferSpacing = 10; % How much spacing is between each panel of logic in the GUI
panelLineWidth = 1;
panelBevelOffset = 2*panelLineWidth + 1;
panelTitleTextSize = 20;
panelTitleHeights = 28;
optionalScrollBarWidth = 100;
experimentVariablesPanelWidthFraction = 0.22; % This variable will multiply 'widthGUI' to determine how wide the variables section of the GUI is.
analysisPanelPosition = [panelBufferSpacing/widthGUI, panelBufferSpacing/heightGUI, experimentVariablesPanelWidthFraction - panelBufferSpacing/widthGUI, 1/2 - 2*panelBufferSpacing/heightGUI + panelTitleHeights/heightGUI];
analysisTitlePosition = [analysisPanelPosition(1)*widthGUI + panelBevelOffset, analysisPanelPosition(2)*heightGUI + analysisPanelPosition(4)*heightGUI - panelTitleHeights - panelBevelOffset + 2, analysisPanelPosition(3)*widthGUI - 2*panelBevelOffset + 2, panelTitleHeights];
variablesPanelPosition = [analysisPanelPosition(1), analysisPanelPosition(2) + analysisPanelPosition(4) + panelBufferSpacing/heightGUI, analysisPanelPosition(3), 1 - analysisPanelPosition(4) - 3*panelBufferSpacing/heightGUI];
variablesTitlePosition = [variablesPanelPosition(1)*widthGUI + panelBevelOffset, variablesPanelPosition(2)*heightGUI + variablesPanelPosition(4)*heightGUI - panelTitleHeights - panelBevelOffset + 2, variablesPanelPosition(3)*widthGUI - 2*panelBevelOffset + 2, panelTitleHeights];
processingPanelPosition = [analysisPanelPosition(1) + experimentVariablesPanelWidthFraction, analysisPanelPosition(2), (1 - experimentVariablesPanelWidthFraction) - 2*panelBufferSpacing/widthGUI, 1 - 2*panelBufferSpacing/heightGUI];
processingTitlePosition = [processingPanelPosition(1)*widthGUI + panelBevelOffset, processingPanelPosition(2)*heightGUI + processingPanelPosition(4)*heightGUI - panelTitleHeights - panelBevelOffset + 2, processingPanelPosition(3)*widthGUI - 2*panelBevelOffset + 2, panelTitleHeights];
optionalScrollBarPosition = [widthGUI - 2*panelBufferSpacing - optionalScrollBarWidth, processingTitlePosition(2) + 2*panelTitleHeights/3, optionalScrollBarWidth, 1];
widthSubGUI = processingPanelPosition(3)*widthGUI;
heightSubGUI = processingPanelPosition(4)*heightGUI - processingTitlePosition(4);

% Initialize GUI Colors variables
GUIBoxColor = [0.9, 0.925, 0.95];
panelColor = [0.9, 0.9, 0.9];
panelTitleColor = [0.25, 0.25, 0.3];
panelTitleTextColor = [1, 1, 1];

%% Determine experiment directory structures and which analyses, if any, are already done

% Graceful exit if user cancelled one or more directory requests
if(strcmp(num2str(mainExperimentDirectory),'0') || strcmp(num2str(mainAnalysisDirectory),'0'))
    disp('User did not select a directory: Program aborted.');
    return;
end

% Obtain all directory contents, total number of directories
[mainExperimentDirectoryContents, mainExperimentSubDirectoryContentsCell, mainExperimentDirectoryStructuresCorrect] = obtainDirectoryStructure(mainExperimentDirectory);
[mainAnalysisDirectoryContents, mainAnalysisSubDirectoryContentsCell, ~] = obtainDirectoryStructure(mainAnalysisDirectory);
nSubDirectories = size(mainExperimentDirectoryContents, 1);

% Verify that image directory structure is correct, abort if not
if(~mainExperimentDirectoryStructuresCorrect)
    disp('Directory structure incorrect: Program aborted. Hint: Main_Directory->Fish_Directory->Vid_Number_Directory->Tiffs');
    return;
end

% Determine if analysis directory already exists, and if not, make it (keep
% in mind that if it exists then it must have the same structure as the 
% image data directories)
determineIfAnalysisFoldersExistsElseCreateThem;

% Remove any subdirectories without tiffs from our list
verifyTiffsInMainDirectoryStructure;

% Open or create the main currentAnalysesPerformed.mat file
[currentAnalysisPerformed, analysisVariables] = openOrCreateCurrentAnalysesPerformedFile;
analysisToPerform = currentAnalysisPerformed;

%% Create GUI

% Initialize GUI
f = figure('Visible', 'off', 'Position', GUISize, 'Resize', 'off'); % Create figure
set(f, 'name', 'Motility Analysis GUI', 'numbertitle', 'off'); % Rename figure
a = axes; % Define figure axes
set(a, 'Position', [0, 0, 1, 1]); % Stretch the axes over the whole figure
set(a, 'Xlim', [0, widthGUI], 'YLim', [0, heightGUI]); % Switch off autoscaling
set(a, 'XTick', [], 'YTick', []); % Turn off tick marks

% Create background, panels
rectangle('Position', [0, 0, widthGUI, heightGUI], 'Curvature', 0, 'FaceColor', GUIBoxColor, 'Parent', a);
uipanel('Position', variablesPanelPosition, 'Parent', f, 'BackgroundColor', panelColor, 'BorderWidth', panelLineWidth);
uipanel('Position', analysisPanelPosition, 'Parent', f, 'BackgroundColor', panelColor, 'BorderWidth', panelLineWidth);
procPanelParent = uipanel('Position', processingPanelPosition, 'Parent', f, 'BackgroundColor', panelColor, 'BorderWidth', panelLineWidth);

% Create Labels
experimentVariablesTitle  = uicontrol('Parent',f,...
                          'Style','text',...
                          'String','Variables Panel',...
                          'backgroundcolor',panelTitleColor,...
                          'Position',variablesTitlePosition,... % The plus and minus single digits are because of the etched panel
                          'FontName','Gill Sans',...
                          'ForegroundColor',panelTitleTextColor,...
                          'FontSize',panelTitleTextSize); %#ok removes annoying orange warning squiggle under the variable

experimentAnalysisTitle   = uicontrol('Parent',f,...
                          'Style','text',...
                          'String','Analysis Panel',...
                          'backgroundcolor',panelTitleColor,...
                          'Position',analysisTitlePosition,... % The plus and minus single digits are because of the etched panel
                          'FontName','Gill Sans',...
                          'ForegroundColor',panelTitleTextColor,...
                          'FontSize',panelTitleTextSize); %#ok removes annoying orange warning squiggle under the variable

experimentProcessingTitle = uicontrol('Parent',f,...
                          'Style','text',...
                          'String','Image Processing Control Panel',...
                          'backgroundcolor',panelTitleColor,...
                          'Position',processingTitlePosition,... % The plus and minus single digits are because of the etched panel
                          'FontName','Gill Sans',...
                          'ForegroundColor',panelTitleTextColor,...
                          'FontSize',panelTitleTextSize); %#ok removes annoying orange warning squiggle under the variable

% Generate the layout and controls for all of the videos, output the
% boolean array representative of analysis to do/done, data to use, etc.
generateProcessingControlPanelListing;

% Generate the layout for all of experimental variables
generateVariablesPanelListing;

% Generate the layout for the analysis controls
generateAnalysisPanelListing;

% Display GUI
f.Visible = 'on';

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
        for i = 1:nSubDirectories
            
            % Obtain main directory structure
            mainSubDirectoryContents = dir(strcat(mainDirectory, filesep, mainDirectoryContents(i).name)); % Obtain all sub-directory contents
            mainSubDirectoryContents(~[mainSubDirectoryContents.isdir]) = []; % Remove non-directories
            mainSubDirectoryContents(strncmp({mainSubDirectoryContents.name}, '.', 1)) = []; % Removes . and .. and hidden files
            mainSubDirectoryContentsCell{i} = mainSubDirectoryContents;
            
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

% verifyTiffsInMainDirectoryStructure verifies that tiffs are in a 
% directory and removes any directory in which they are not
function verifyTiffsInMainDirectoryStructure
    
    % Make sure directories contain images of the form <imageFileType>, if
    % not, remove the directories from the list
    for i=1:nSubDirectories
        
        nSubSubDirectories = size(mainExperimentSubDirectoryContentsCell{i}, 1);
        directoriesToRemove = [];
        
        % Check for which directories to remove
        for j=1:nSubSubDirectories
            
            subSubDirectoryTiffs = dir(strcat(mainExperimentDirectory,filesep,mainExperimentDirectoryContents(i).name,filesep,mainExperimentSubDirectoryContentsCell{i}(j).name,filesep,imageFileType));
            
            % If directory does not contain tiffs, remove it from the list
            if(isempty(subSubDirectoryTiffs))
                
                % Record directories to remove
                directoriesToRemove = [directoriesToRemove, j]; %#ok since the number of directories should be "small"
                
                % Warn user
                directoryRemovalMessage = sprintf('Folder "%s->%s" contains no %s''s and will be ignored.\n', mainExperimentDirectoryContents(i).name, mainExperimentSubDirectoryContentsCell{i}(j).name, imageFileType);
                disp(directoryRemovalMessage);
                
            end
            
        end
        
        % Actually remove the directories without tiffs
        if(~isempty(directoriesToRemove))
            
            for j=1:size(directoriesToRemove, 2)
            
                mainExperimentSubDirectoryContentsCell{i}(end-j+1) = []; % Removal is done in reverse order as to not mess up numbering of other entries
            
            end
            
        end
        
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
        
        for i=1:nMainExperimentSubDirs
            
            if(~isequal({mainExperimentSubDirectoryContentsCell{i}.name},{mainAnalysisSubDirectoryContentsCell{i}.name}))
                
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
            for i=1:nMainExperimentSubDirs
                
                % Check if the ith directory exists, and if not, make it
                curDirectoryAlreadyExistsInt = exist(strcat(mainAnalysisDirectory,filesep,mainExperimentDirectoryContents(i).name),'dir');
                if(curDirectoryAlreadyExistsInt ~= 7)
                    mkdir(strcat(mainAnalysisDirectory,filesep,mainExperimentDirectoryContents(i).name));
                end
                
            end
            
        end
            
        % Match the contents of each subdirectory
        if( ~subDirectoryContentsSameBool )
            
            % Loop through the directories
            for i=1:nMainExperimentSubDirs
                
                % And check each jth subdirectory
                for j=1:size(mainExperimentSubDirectoryContentsCell{i},1)
                    % Check if the jth subdirectory exists, and if not, make it
                    curSubDirectoryAlreadyExistsInt = exist(strcat(mainAnalysisDirectory,filesep,mainExperimentDirectoryContents(i).name,filesep,mainExperimentSubDirectoryContentsCell{1,i}(j).name),'dir');
                    if(curSubDirectoryAlreadyExistsInt ~= 7)
                        mkdir(strcat(mainAnalysisDirectory,filesep,mainExperimentDirectoryContents(i).name,filesep,mainExperimentSubDirectoryContentsCell{1,i}(j).name));
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
        for i=1:nSubDirectories
            currentAnalysisPerformed(i).directory = mainExperimentDirectoryContents(i).name; %#ok since size of structure is small % WARNING: Do not change this variable name without changing the save strings below
            nSubSubDirectories = size(mainExperimentSubDirectoryContentsCell{1, i}, 1);
            currentAnalysisPerformed(i).bools = false(nSubSubDirectories, nAnalysisCheckboxTypes); %#ok since size of structure is small
            currentAnalysisPerformed(i).bools(:, nAnalysisCheckboxTypes) = true; %#ok since size of structure is small
            % Record the order of the bools
            for j=1:nSubSubDirectories
                currentAnalysisPerformedSubDirs(j).subDirectories = mainExperimentSubDirectoryContentsCell{1, i}(j).name; %#ok since size of structure is small
            end
            currentAnalysisPerformed(i).subDirectories = currentAnalysisPerformedSubDirs; %#ok since size of structure is small
        end
        
        % Save this file for future reference, update after any analysis
        analysisVariables = {'*.tif','32','5','0.1625','1'};
        save(strcat(mainAnalysisDirectory, filesep, currentAnalysesPerformedFileName),'currentAnalysisPerformed','analysisVariables'); % WARNING: If currentAnalysisPerformed name is changed, you'll have to manually change this string  IN MANY LOCATIONS!!!
        
    end
    
end

% generateGUIFolderListing builds the display for all the folders and the
% analyses that has been/will be performed. Color indicates if something
% has been done (red no, green yes), checkmark represents what the user
% wants to do.
function generateProcessingControlPanelListing
    
    % Initialize GUI variables
    loopIndex = 1;
    curLinearizedAnalysisIndex = 0;
    textSize = 15;
    textIconHeight = 18;
    textBufferSpacing = 5; % How much spacing is between each line of text
    checkBoxSpacing = 25;
    checkBoxWidth = 20;
    checkboxHeight = 20;
    subFolderWidth = 40;
    subSubFolderWidth = 80 - subFolderWidth - textBufferSpacing;
    nSubSubDirectories = 0;
    subDirTitleColor = [1, 0.6, 0.1];
    subDirTitleTextColor = [1, 1, 1];
    subSubDirTitleColor = [0.5, 0.9, 1];
    subSubDirTitleTextColor = [1, 1, 1];
    notAnalyzedCheckboxColor = [1, 0.8, 0.8];
    analyzedCheckboxColor = [0.8, 1, 0.8];
    playVideoButtonWidth = 55;
    openAnalysisButtonWidth = 80;
    playPIVVideoButtonWidth = 55;
    playPIVSoundButtonWidth = 60;
    loadVarsButtonWidth = 90;
    %g = uipanel('Parent',procPanel);
    
    % Initialize directory structure variables
    for i=1:nSubDirectories
        nSubSubDirectories = nSubSubDirectories + size(mainExperimentSubDirectoryContentsCell{1, i}, 1);
    end
    colWidth = 3*panelBufferSpacing + 4*textBufferSpacing + subFolderWidth + subSubFolderWidth + playVideoButtonWidth + openAnalysisButtonWidth + playPIVVideoButtonWidth + nAnalysisCheckboxTypes*checkBoxSpacing;
    maxRows = floor((heightSubGUI - textBufferSpacing - panelBufferSpacing - checkboxHeight - textIconHeight)/(panelBufferSpacing + textBufferSpacing + 2*textIconHeight));
    maxCols = floor(widthSubGUI/colWidth);
    neededCols = ceil(nSubSubDirectories/maxRows);
    
    if(neededCols > maxCols)
        buttonOverflow = true;
        nRows = maxRows;
        nCols = neededCols;
        shownCols = maxCols;
        unshownWidth = colWidth*(neededCols - shownCols);
    elseif(nSubSubDirectories/maxRows <= 1)
        buttonOverflow = false;
        nRows = nSubSubDirectories;
        nCols = 1;
        shownCols = 1;
        unshownWidth = 0;
    else
        buttonOverflow = false;
        nRows = maxRows;
        nCols = neededCols;
        shownCols = neededCols;
        unshownWidth = 0;
    end
    
    subProcPanelPosition = [0, 0, widthSubGUI + unshownWidth, processingPanelPosition(4)];
    subProcPanel = uipanel('Position', subProcPanelPosition, 'Parent', procPanelParent, 'BackgroundColor', panelColor, 'BorderWidth', panelLineWidth);
    
%    nCols = ceil(((textIconHeight + textBufferSpacing)*(nSubDirectories + 2*nSubSubDirectories) + textBufferSpacing)/(heightSubGUI - 2*textIconHeight - 3*textBufferSpacing)); % Minus 2 is for the header and the titles
%    nRows = ceil((nSubDirectories + 2*nSubSubDirectories)/nCols);
    checkBoxHandleArray = gobjects(nSubSubDirectories, nAnalysisCheckboxTypes);
    buttonHandleArray = gobjects(nSubSubDirectories, 6);
    
    % Enumerate each folder and which analyses have been performed/will be
    % performed
    for i=1:nSubDirectories
        
        % Determine how many sub folders are in the current directory
        curSubSubSize = size(mainExperimentSubDirectoryContentsCell{1,i},1);
        
        % Determine where to put the current subfolder label
        curRow = mod(loopIndex-1,nRows) + 1;
        curCol = ceil(loopIndex/nRows);
        
        % Create the current subfolder label
        
        curSubFolderX = panelBufferSpacing + (curCol - 1)*widthSubGUI/shownCols;
        curSubFolderY = heightSubGUI - 2*textIconHeight - 2*panelBufferSpacing - textBufferSpacing - checkboxHeight - (curRow - 1)*(panelBufferSpacing + 2*textIconHeight + textBufferSpacing);
        
        uicontrol('Parent',subProcPanel,...
            'Style','text',...
            'String',mainExperimentDirectoryContents(i).name,...
            'backgroundcolor',subDirTitleColor,...
            'Position',[curSubFolderX, curSubFolderY, subFolderWidth, textIconHeight],... % The plus and minus 1 are because of the etched panel
            'FontName','Gill Sans',...
            'ForegroundColor',subDirTitleTextColor,...
            'FontSize',textSize);
        
        % Determine which analyses to perform (inverse of already done)
        analysisToPerform(i).bools(:,1:end -1) = ~analysisToPerform(i).bools(:,1:end -1); % Flip everything except the 'Use' section, 1 used to mean done, so we flip it to 0 so we don't perform analysis on it, except the 'Use' bool
        
        % Loop through the current folders subdirectories
        for j=1:curSubSubSize
            
            curLinearizedAnalysisIndex = curLinearizedAnalysisIndex + 1;
            curRow = mod(loopIndex-1,nRows) + 1;
            curCol = ceil(loopIndex/nRows);
            curDividingPointStart = (curCol - 1)*widthSubGUI/shownCols;
            curDividingPointEnd = curCol*widthSubGUI/shownCols;
            curXStart = panelBufferSpacing + subFolderWidth + curDividingPointStart;
            curXEnd = curDividingPointEnd - panelBufferSpacing;
            curY = heightSubGUI - 2*textIconHeight - 2*panelBufferSpacing - textBufferSpacing - checkboxHeight - (curRow - 1)*(panelBufferSpacing + 2*textIconHeight + textBufferSpacing);
            curPosition = [curXStart, curY, subSubFolderWidth, textIconHeight];
            
            % Create the current subfolder label
            uicontrol('Parent',subProcPanel,...
                'Style','text',...
                'String',mainExperimentSubDirectoryContentsCell{i}(j).name,...
                'backgroundcolor',subSubDirTitleColor,...
                'Position',curPosition,...
                'FontName','Gill Sans',...
                'ForegroundColor',subSubDirTitleTextColor,...
                'FontSize',textSize);
            
            % Create play video button
            buttonHandleArray(loopIndex, 1) = uicontrol('Parent',subProcPanel,...
                'Style','pushbutton',...
                'String','Play Video',...
                'Position',[curPosition(1) + subSubFolderWidth + textBufferSpacing, curPosition(2), playVideoButtonWidth, textIconHeight],...
                'Callback',{@playVideoButton_Callback});
            set(buttonHandleArray(loopIndex, 1), 'Enable', 'off');
            
            % Create open images button
            buttonHandleArray(loopIndex, 2) = uicontrol('Parent',subProcPanel,...
                'Style','pushbutton',...
                'String','Analysis Images',...
                'Position',[curPosition(1) + subSubFolderWidth + playVideoButtonWidth + 2*textBufferSpacing, curPosition(2), openAnalysisButtonWidth, textIconHeight],...
                'Callback',{@openAnalysisImagesButton_Callback, i, j});
            if( currentAnalysisPerformed(i).bools(j, 4) )
                set(buttonHandleArray(loopIndex, 2), 'Enable', 'on');
            else
                set(buttonHandleArray(loopIndex, 2), 'Enable', 'off');
            end
            
            % Create open piv video button
            buttonHandleArray(loopIndex, 3) = uicontrol('Parent',subProcPanel,...
                'Style','pushbutton',...
                'String','Play PIV Video',...
                'Position',[curPosition(1) + subSubFolderWidth + playVideoButtonWidth + openAnalysisButtonWidth + 3*textBufferSpacing, curPosition(2), playPIVVideoButtonWidth, textIconHeight],...
                'Callback',{@playPIVVideoButton_Callback});
            if( currentAnalysisPerformed(i).bools(j, 5) )
                set(buttonHandleArray(loopIndex, 3), 'Enable', 'on');
            else
                set(buttonHandleArray(loopIndex, 3), 'Enable', 'off');
            end
            
            % Create play sound button
            buttonHandleArray(loopIndex, 4) = uicontrol('Parent',subProcPanel,...
                'Style','togglebutton',...
                'String','Play Sound',...
                'Position',[curPosition(1) + subSubFolderWidth + textBufferSpacing, curPosition(2) - (textIconHeight + textBufferSpacing), playPIVSoundButtonWidth, textIconHeight],...
                'Callback',{@playPIVSoundButton_Callback, i, j});
            if( currentAnalysisPerformed(i).bools(j, 4) )
                set(buttonHandleArray(loopIndex, 4), 'Enable', 'on');
            else
                set(buttonHandleArray(loopIndex, 4), 'Enable', 'off');
            end
            
            % Create load into workspace button
            buttonHandleArray(loopIndex, 5) = uicontrol('Parent',subProcPanel,...
                'Style','pushbutton',...
                'String','Vars->Workspace',...
                'Position',[curPosition(1) + subSubFolderWidth + 2*textBufferSpacing + playPIVSoundButtonWidth, curPosition(2) - (textIconHeight + textBufferSpacing), loadVarsButtonWidth, textIconHeight],...
                'Callback',{@loadVarsButton_Callback, i, j});
            if( currentAnalysisPerformed(i).bools(j, 4) )
                set(buttonHandleArray(loopIndex, 5), 'Enable', 'on');
            else
                set(buttonHandleArray(loopIndex, 5), 'Enable', 'off');
            end
            
            % Create all of the checkboxes
            for k=1:nAnalysisCheckboxTypes
                
                currentlyDone = ~analysisToPerform(i).bools(j, k);
                if( k ~= nAnalysisCheckboxTypes )
                    currentColor = currentlyDone*analyzedCheckboxColor + ~currentlyDone*notAnalyzedCheckboxColor; % Simple way of changing colors depending on whether or not analysis is done
                else
                    currentColor = ~currentlyDone*analyzedCheckboxColor + currentlyDone*notAnalyzedCheckboxColor; % Remember to flip the color of the 'Use' section
                end
                % Create the current subfolder label
                checkBoxHandleArray(curLinearizedAnalysisIndex, k) = uicontrol('Parent', subProcPanel,...
                    'Style', 'checkbox',...
                    'BackgroundColor', currentColor,...
                    'Position', [curXEnd - (nAnalysisCheckboxTypes - k + 1)*checkBoxSpacing - 4, curY, checkBoxWidth, checkboxHeight],...
                    'Value',~currentlyDone,...
                    'Callback', {@checkBox_Callback, curLinearizedAnalysisIndex, i, j, k});
                
            end
            
            % Since each subsubdir gets two rows, add another to the index
            loopIndex = loopIndex + 1;
            
        end
        
    end
    
    % Build the select all checkboxes
    for i=1:nAnalysisCheckboxTypes
        
        % Determine if it should be initially checked or not
        currentCheckedCheck = zeros(1, nSubDirectories);
        for j=1:nSubDirectories
            currentCheckedCheck(j) = min(analysisToPerform(j).bools(:, i));
        end
        
        % Create label for subfolder
        textSizeModified = -4;
        curLabelPosition = [widthSubGUI/shownCols - panelBufferSpacing - (nAnalysisCheckboxTypes - i + 1)*checkBoxSpacing - 4, heightSubGUI - textIconHeight - panelBufferSpacing, 0, checkboxHeight];
        
        switch i
            
            case 1
                % Create the current subfolder label
                curLabelWidth = [-15, 0, 25, 0];
                uicontrol('Parent',subProcPanel,...
                    'Style','text',...
                    'String','PIV',...
                    'backgroundcolor',panelColor,...
                    'Position',curLabelPosition + curLabelWidth,...
                    'FontName','Gill Sans',...
                    'FontSize',textSize + textSizeModified);
                
            case 2
                
                % Create the current subfolder label
                curLabelWidth = [-22, 0, 45, 0];
                uicontrol('Parent',subProcPanel,...
                    'Style','text',...
                    'String','Outline',...
                    'backgroundcolor',panelColor,...
                    'Position',curLabelPosition + curLabelWidth,...
                    'FontName','Gill Sans',...
                    'FontSize',textSize + textSizeModified);
                
            case 3
                % Create the current subfolder label
                curLabelWidth = [-12, 0, 35, 0];
                uicontrol('Parent',subProcPanel,...
                    'Style','text',...
                    'String','Interp',...
                    'backgroundcolor',panelColor,...
                    'Position',curLabelPosition + curLabelWidth,...
                    'FontName','Gill Sans',...
                    'FontSize',textSize + textSizeModified);
                
            case 4
                % Create the current subfolder label
                curLabelWidth = [-8, 0, 40, 0];
                uicontrol('Parent',subProcPanel,...
                    'Style','text',...
                    'String','Analyze',...
                    'backgroundcolor',panelColor,...
                    'Position',curLabelPosition + curLabelWidth,...
                    'FontName','Gill Sans',...
                    'FontSize',textSize + textSizeModified);
                
            case 5
                % Create the current subfolder label
                curLabelWidth = [0, 0, 32, 0];
                uicontrol('Parent',subProcPanel,...
                    'Style','text',...
                    'String','Video',...
                    'backgroundcolor',panelColor,...
                    'Position',curLabelPosition + curLabelWidth,...
                    'FontName','Gill Sans',...
                    'FontSize',textSize + textSizeModified);
                
            case 6
                % Create the current subfolder label
                curLabelWidth = [0, 0, 25, 0];
                uicontrol('Parent',subProcPanel,...
                    'Style','text',...
                    'String','Use',...
                    'backgroundcolor',panelColor,...
                    'Position',curLabelPosition + curLabelWidth,...
                    'FontName','Gill Sans',...
                    'FontSize',textSize + textSizeModified);
                
            otherwise
                % Create the current subfolder label
                curLabelWidth = [-15, 0, 45, 0];
                uicontrol('Parent',subProcPanel,...
                    'Style','text',...
                    'String','Unknown',...
                    'backgroundcolor',panelColor,...
                    'Position',curLabelPosition + curLabelWidth,...
                    'FontName','Gill Sans',...
                    'FontSize',textSize + textSizeModified);
                
        end
        
        % Create the current subfolder label (only checked if all entries
        % down the rows are checked)
        curCheckboxPosition = [curLabelPosition(1), curLabelPosition(2) - textBufferSpacing - textIconHeight, checkBoxWidth, checkboxHeight];
        selectAllHandle = uicontrol('Parent', subProcPanel,...
            'Style', 'checkbox',...
            'Position', curCheckboxPosition,...
            'backgroundcolor',panelColor,...
            'Value',min(currentCheckedCheck),...
            'Callback', {@selectAllCheckBox_Callback,i});
        
        if( i == nAnalysisCheckboxTypes )
            set(selectAllHandle, 'Enable', 'off');
        end
        
    end
    
    if(buttonOverflow)
        
        panelSlider = uicontrol('Parent', f,...
            'Style', 'slider',...
            'Position', optionalScrollBarPosition,...
            'backgroundcolor',panelColor,...
            'Value',0,...
            'Callback', {@panelSlider_Callback});
    end
        
    % Callback functions
    % Checkbox functionality
    function checkBox_Callback(~, ~, curLinArrayIndex, ii, jj, kk)
        
        % Change boolean value
        analysisToPerform(ii).bools(jj, kk) = ~analysisToPerform(ii).bools(jj, kk);
        
        % Update the color/file if we are toggling the 'Use' checkbox
        if(kk == nAnalysisCheckboxTypes)
            
            % Change the color of the checkbox
            curColor = analysisToPerform(ii).bools(jj, kk)*analyzedCheckboxColor + ~analysisToPerform(ii).bools(jj, kk)*notAnalyzedCheckboxColor;
            set(checkBoxHandleArray(curLinArrayIndex, kk), 'BackgroundColor', curColor);
            
            % Update the file
            currentAnalysisPerformed(ii).bools(jj, kk) = analysisToPerform(ii).bools(jj, kk);
            % Save this file for future reference, update after any analysis
            save(strcat(mainAnalysisDirectory, filesep, currentAnalysesPerformedFileName),'currentAnalysisPerformed'); % WARNING: If currentAnalysisPerformed name is changed, you'll have to manually change this string IN MANY LOCATIONS!!!
            
        end
        
    end
    
    % Select all checkbox functionality
    function selectAllCheckBox_Callback( hObject, ~, kk)
        
        % Check if boxes in row are mixed on and off
        uniqueEntries = [];
        for ii=1:nSubDirectories
            uniqueEntries = unique([unique(analysisToPerform(ii).bools(:, kk)); uniqueEntries]);
        end
        
        % If some are on and others off, turn all on, else toggle
        if(size(uniqueEntries, 1) > 1)
            
            % Turn analysis to perform on
            for aTPIndex=1:size(analysisToPerform, 2)
                analysisToPerform(aTPIndex).bools(:, kk) = true;
            end
            
            % Set current value
            set(hObject, 'Value', 1);
            
            % Set all checkboxes in column to true
            for ii=1:nSubSubDirectories
                set(checkBoxHandleArray(ii, kk), 'Value', 1)
            end
            
        else
            
            % Get the current value
            curBoolValue = get(hObject, 'Value');
            
            % Set analysisToPerform to opposite its current value
            for aTPIndex=1:size(analysisToPerform, 2)
                analysisToPerform(aTPIndex).bools(:, kk) = ~analysisToPerform(aTPIndex).bools(:, kk);
            end
            
            % Set all checkboxes in column to true
            for ii=1:nSubSubDirectories
                set(checkBoxHandleArray(ii, kk), 'Value', curBoolValue)
            end
            
        end
        
    end

    function playVideoButton_Callback(~, ~)
        msgbox('Currently Not Working');
    end

    function openAnalysisImagesButton_Callback(~, ~, ii, jj)
        
        % Define the current folder
        curDir = strcat(mainAnalysisDirectory, filesep, mainExperimentDirectoryContents(ii).name, filesep, mainExperimentSubDirectoryContentsCell{1, ii}(jj).name);
        
        % Load the figure
        openfig(strcat(curDir, filesep, 'Figures_Current.fig'));
        
    end

    function playPIVVideoButton_Callback(~, ~)
        msgbox('Currently Not Working');
    end
    
    function playPIVSoundButton_Callback(hObject, ~, ii, jj)
        
        % Get button state
        isToggleDown = get(hObject, 'Value');
        set(hObject, 'String', 'Loading...');
        pause(0.1);
        
        % Define the current folder
        curDir = strcat(mainAnalysisDirectory, filesep, mainExperimentDirectoryContents(ii).name, filesep, mainExperimentSubDirectoryContentsCell{1, ii}(jj).name);

        if(logical(isToggleDown))
            
            % Load data
            gutMeshVelsPCoordsStruct = load(strcat(curDir, filesep, 'processedPIVOutput_Current.mat'),'gutMeshVelsPCoords');
            gutMeshVelsPCoords = gutMeshVelsPCoordsStruct.gutMeshVelsPCoords;
            
            % Play sound if toggle was pressed down, stop if released
            totalTimeFraction = 1;
            fractionOfTimeStart = size(gutMeshVelsPCoords,4);
            markerNumStart = 1;
            markerNumEnd = size(gutMeshVelsPCoords,2);
            samplingRate = 44100;
            
            % Transform into sound with position mapped onto frequency
            theSound = playMotilityAsSound(gutMeshVelsPCoords, totalTimeFraction, fractionOfTimeStart, markerNumStart, markerNumEnd);
            
            % Set string
            set(hObject, 'String', 'Stop Sound');
            
            % Play the sound
            sound(theSound,samplingRate)
            
        else
            
            % Stop the sound
            clear sound
            
            % Set string
            set(hObject, 'String', 'Play Sound');
            
        end
        
    end
    
    function loadVarsButton_Callback(~, ~, ii, jj)
        
        % Define the current folder
        curDir = strcat(mainAnalysisDirectory, filesep, mainExperimentDirectoryContents(ii).name, filesep, mainExperimentSubDirectoryContentsCell{1, ii}(jj).name);
        
        % Load the variables into the workspace
        assignin('base', 'curDir', curDir);
        evalin('base', 'load(strcat(curDir, filesep, ''motilityParameters_Current.mat''))');
        evalin('base', 'load(strcat(curDir, filesep, ''processedPIVOutput_Current.mat''))');
        
    end
    
    function panelSlider_Callback(hObject, ~)
        
        curSliderPosition = get(hObject, 'Value');
        set(subProcPanel, 'Position', subProcPanelPosition + [-unshownWidth*curSliderPosition/widthSubGUI, 0, 0, 0]);
        
    end
        
end

function generateVariablesPanelListing
    
    % Initialize Variables
    textBufferSpacing = 4;
    textIconHeight = 18;
    inputIconHeight = 5;
    answerFieldDropDownWidth = 80;
    answerFieldEditWidth = 50;
    filetypeTextPosition = [panelBufferSpacing + panelBevelOffset + textBufferSpacing, heightGUI - panelBufferSpacing - panelBevelOffset - panelTitleHeights - textBufferSpacing - textIconHeight, widthGUI*experimentVariablesPanelWidthFraction - 3*textBufferSpacing - 2*panelBevelOffset - panelBufferSpacing - answerFieldDropDownWidth, textIconHeight];
    filetypeInputPosition = filetypeTextPosition + [filetypeTextPosition(3) + textBufferSpacing, 0, answerFieldDropDownWidth - filetypeTextPosition(3), 0];
    templateSizeTextPosition = filetypeTextPosition + [0, - textBufferSpacing - 2*textIconHeight, 0, textIconHeight];
    templateSizeInputPosition = templateSizeTextPosition + [templateSizeTextPosition(3) + textBufferSpacing + (filetypeInputPosition(3) - answerFieldEditWidth)/2, 0, answerFieldEditWidth - templateSizeTextPosition(3), inputIconHeight - textIconHeight];
    framerateTextPosition = templateSizeTextPosition + [0, - textBufferSpacing - 2*textIconHeight, 0, 0];
    framerateInputPosition = framerateTextPosition + [framerateTextPosition(3) + textBufferSpacing + (filetypeInputPosition(3) - answerFieldEditWidth)/2, 0, answerFieldEditWidth - framerateTextPosition(3), inputIconHeight - textIconHeight];
    scaleTextPosition = framerateTextPosition + [0, - textBufferSpacing - 2*textIconHeight, 0, 0];
    scaleInputPosition = scaleTextPosition + [scaleTextPosition(3) + textBufferSpacing + (filetypeInputPosition(3) - answerFieldEditWidth)/2, 0, answerFieldEditWidth - scaleTextPosition(3), inputIconHeight - textIconHeight];
    resReductionTextPosition = scaleTextPosition + [0, - textBufferSpacing - 3*textIconHeight, 0, textIconHeight];
    resReductionInputPosition = resReductionTextPosition + [resReductionTextPosition(3) + textBufferSpacing + (filetypeInputPosition(3) - answerFieldEditWidth)/2, 0, answerFieldEditWidth - resReductionTextPosition(3), inputIconHeight - textIconHeight];
    textSize = 13;
    textFGColor = [0, 0, 0];
    
    % Filetype text
    uicontrol('Parent',f,...
        'Style','text',...
        'String','Load which filetype?',...
        'BackgroundColor',panelColor,...
        'ForegroundColor',textFGColor,...
        'Position',filetypeTextPosition,...
        'HorizontalAlignment','left',...
        'FontName','Gill Sans',...
        'FontSize',textSize);
    uicontrol('Parent',f,...
        'Style','popupmenu',...
        'String',{'*.tif', '*.png'},...
        'BackgroundColor',panelColor,...
        'ForegroundColor',textFGColor,...
        'Position',filetypeInputPosition,...
        'Callback', {@filetype_Callback},...
        'Enable', 'off',...
        'FontName','Gill Sans',...
        'FontSize',textSize);
    
    % Template size text
    uicontrol('Parent',f,...
        'Style','text',...
        'String','Smallest template size for PIV tracking?',...
        'BackgroundColor',panelColor,...
        'ForegroundColor',textFGColor,...
        'Position',templateSizeTextPosition,...
        'HorizontalAlignment','left',...
        'FontName','Gill Sans',...
        'FontSize',textSize);
    uicontrol('Parent',f,...
        'Style','edit',...
        'String',analysisVariables{2},...
        'ForegroundColor',textFGColor,...
        'Position',templateSizeInputPosition,...
        'Callback', {@templateSize_Callback},...
        'FontName','Gill Sans',...
        'FontSize',textSize);
    
    % Framerate text
    uicontrol('Parent',f,...
        'Style','text',...
        'String','What is the framerate of the video (fps)?',...
        'BackgroundColor',panelColor,...
        'ForegroundColor',textFGColor,...
        'Position',framerateTextPosition,...
        'HorizontalAlignment','left',...
        'FontName','Gill Sans',...
        'FontSize',textSize);
    uicontrol('Parent',f,...
        'Style','edit',...
        'String',analysisVariables{3},...
        'ForegroundColor',textFGColor,...
        'Position',framerateInputPosition,...
        'Callback', {@framerate_Callback},...
        'FontName','Gill Sans',...
        'FontSize',textSize);
    
    % Scale text
    uicontrol('Parent',f,...
        'Style','text',...
        'String','What is the spatial scale of the images (um/pix)?',...
        'BackgroundColor',panelColor,...
        'ForegroundColor',textFGColor,...
        'Position',scaleTextPosition,...
        'HorizontalAlignment','left',...
        'FontName','Gill Sans',...
        'FontSize',textSize);
    uicontrol('Parent',f,...
        'Style','edit',...
        'String',analysisVariables{4},...
        'ForegroundColor',textFGColor,...
        'Position',scaleInputPosition,...
        'Callback', {@scale_Callback},...
        'FontName','Gill Sans',...
        'FontSize',textSize);
    
    % Resolution reduction text, input
    uicontrol('Parent',f,...
        'Style','text',...
        'String','What (linear) factor would you like to reduce your image size by (1=none)?',...
        'BackgroundColor',panelColor,...
        'ForegroundColor',textFGColor,...
        'Position',resReductionTextPosition,...
        'HorizontalAlignment','left',...
        'FontName','Gill Sans',...
        'FontSize',textSize);
    uicontrol('Parent',f,...
        'Style','edit',...
        'String',analysisVariables{5},...
        'ForegroundColor',textFGColor,...
        'Position',resReductionInputPosition,...
        'Callback', {@resReduction_Callback},...
        'FontName','Gill Sans',...
        'FontSize',textSize);
    
    function filetype_Callback(~, ~)
        
        msgbox('Currently not working');
        
    end
    
    function templateSize_Callback(hObject, ~)
        
        analysisVariables{2} = get(hObject,'String');
        
    end
    
    function framerate_Callback(hObject, ~)
        
        analysisVariables{3} = get(hObject,'String');
        
    end
    
    function scale_Callback(hObject, ~)
        
        analysisVariables{4} = get(hObject,'String');
        
    end
    
    function resReduction_Callback(hObject, ~)
        
        analysisVariables{5} = get(hObject,'String');
        
    end
    
end

function generateAnalysisPanelListing
    
    % Initialize Variables
    buttonWidth = 100;
    buttonHeight = 30;
    textBufferSpacing = 4;
    closeButtonPosition = [widthGUI*experimentVariablesPanelWidthFraction - panelBevelOffset - textBufferSpacing- buttonWidth, panelBufferSpacing + panelBevelOffset, buttonWidth, buttonHeight];
    analyzeButtonPosition = [panelBufferSpacing + panelBevelOffset + textBufferSpacing, panelBufferSpacing + panelBevelOffset, buttonWidth, buttonHeight];
    
    % Close button
    uicontrol('Parent',f,...
        'Style','pushbutton',...
        'String','Close Program',...
        'Position',closeButtonPosition,...
        'Callback',{@closeButton_Callback});
    
    % Analyze selection button
    uicontrol('Parent',f,...
        'Style','pushbutton',...
        'String','Analyze Selection',...
        'Position',analyzeButtonPosition,...
        'Callback',{@analyzeButton_Callback});
    
    function closeButton_Callback(~, ~)
        close all;
    end
    
    function analyzeButton_Callback(~, ~)
        % Close the program (it will open again with updated information)
        close all;
        
        % Perform PIV
        performPIV(mainExperimentDirectory, mainExperimentDirectoryContents, mainExperimentSubDirectoryContentsCell, mainAnalysisDirectory, analysisToPerform, analysisVariables, currentAnalysesPerformedFileName, rawPIVOutputName)
        
        % Obtain motility masks
        obtainMotilityMasks(mainExperimentDirectory, mainExperimentDirectoryContents, mainExperimentSubDirectoryContentsCell, mainAnalysisDirectory, analysisToPerform, analysisVariables, currentAnalysesPerformedFileName, maskFileOutputName)
        
        % Perform interpolation
        performMaskInterpolation(mainExperimentDirectory, mainExperimentDirectoryContents, mainExperimentSubDirectoryContentsCell, mainAnalysisDirectory, analysisToPerform, analysisVariables, currentAnalysesPerformedFileName, interpolationOutputName, rawPIVOutputName, maskFileOutputName)
        
        % Analyze Data
        performMotilityDataAnalysis(mainExperimentDirectoryContents, mainExperimentSubDirectoryContentsCell, mainAnalysisDirectory, analysisToPerform, analysisVariables, currentAnalysesPerformedFileName, motilityParametersOutputName, interpolationOutputName, GUISize)
        
        % Make PIV movie
        createAllChosenPIVMovies(mainExperimentDirectory, mainExperimentDirectoryContents, mainExperimentSubDirectoryContentsCell, mainAnalysisDirectory, analysisToPerform, analysisVariables, currentAnalysesPerformedFileName, PIVOutputName, PIVVideoParams);
        
        % Reopen this program
        analyzeMotility(mainExperimentDirectory, mainAnalysisDirectory);
        
    end
    
end

end