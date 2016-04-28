% Collection script for Fall 2015 data
%% Initialize variables

augustFolders = {'8_19_15','8_20_15','8_21_15'};
septemberFolders = {'9_16_15','9_17_15','9_18_15'};
novemberFolders = {'11_4_15','11_5_15','11_6_15'};
fishParams = cell( 1, 9 );

monthsFolders = [augustFolders,septemberFolders,novemberFolders];

%% Load all variables

mainFolderA=uigetdir('Where is the August directory located?');
mainFolderS=uigetdir('Where is the September directory located?');
mainFolderN=uigetdir('Where is the November directory located?');

mainFolders = {mainFolderA,mainFolderS,mainFolderN};

% Loop through months
for i=1:3
    
    % Loop through dpfs
    for j=1:3
        
        curFold = strcat(mainFolders{i},filesep,monthsFolders{3*(i-1)+j});
        
        % Obtain all fish folders to loop through
        fishFolders=dir(curFold);
        fishFolders(strncmp({fishFolders.name}, '.', 1)) = []; % Removes . and .. and hidden files
        fishFolders(~[fishFolders.isdir])=[]; % Removes any non-directories
        
        fishNums = [];
        wAmp = [];
        wFreq = [];
        wSpeed = [];
        wSigB = [];
        wPulse = [];
        sameBool = false;
        fileIndex = 1;
        
        % Go through each fish directory to collect data
        for k=1:size(fishFolders,1)
            
            % Get fish number
            fishNum = str2double(fishFolders(k).name(5:end));
            fishNums = [fishNums, fishNum]; %#ok
            
            % Get subfolders
            subFolder = dir(strcat(curFold,filesep,fishFolders(k).name));
            subFolder(strncmp({subFolder.name}, '.', 1)) = []; % Removes . and .. and hidden files
            subFolder(~[subFolder.isdir])=[]; % Removes any non-directories
            deepestFolder = strcat(curFold,filesep,fishFolders(k).name,filesep,subFolder(1).name,filesep,'DeconstructedImages',filesep,'Data');
            
            % Load the fishBool array, choose if multiple
            curData = dir(strcat(deepestFolder,filesep,'GutParameters*.mat'));
%             if( length(curData) > 1)
%                 disp('Multiple gut parameter files; Pick one by entering the number');
%                 for l=1:length(curData)
%                     fileNumStr=sprintf('%i) %s',l,curData(l).name);
%                     disp(fileNumStr);
%                 end
%                 fileIndex=input('Which number?: ');
%             end
             
            if( length(curData) > 1)
                if(~sameBool)
                    disp('Multiple GutParameters files; Pick one by entering the number');
                    for l=1:length(curData)
                        fileNumStr=sprintf('%i) %s',l,curData(l).name);
                        disp(fileNumStr);
                    end
                    fileIndex=input('Which number?: ');
                    fileName=curData(fileIndex).name;
                    % Do this for all?
                    userContChoice=menu('Choose the same for all fish?','Yes','No');
                    % If not, exit loop
                    if userContChoice==1
                        sameBool=true;
                    end
                end
            end
            load(strcat(deepestFolder,filesep,fileName)); % Should load, among others, fftPowerPeak, waveFrequency, waveSpeedSlope, sigB, and waveAverageWidth

            % Save variables
            wAmp = [wAmp, fftPowerPeak]; %#ok
            wFreq = [wFreq, waveFrequency]; %#ok
            wSpeed = [wSpeed, waveSpeedSlope]; %#ok
            wSigB = [wSigB, sigB]; %#ok
            wPulse = [wPulse, waveAverageWidth]; %#ok
            
        end
        
        % save params in cell
        fishParams(3*(i-1)+j) = {[fishNums; wAmp; wFreq; wSpeed; wSigB; wPulse]};
        
    end
    
end

save(strcat('Fall2015FishParams_',date),'fishParams');

%% Reframe data as one mat file
fall2015Data = struct('Title',{Fall2015Bools(1,:).titles},'FishParameters',fishParams,'FishType',{Fall2015Bools(3,:).bools},'BoolsNonNaN',{Fall2015Bools(1,:).bools},'BoolsNaN',{Fall2015Bools(2,:).bools});

%% Reframe fishParameters, loop through days
for i=1:size(fall2015Data,2)
    
    sizeOfCurFishParams = size(fall2015Data(i).BoolsNaN,2);
    curFishParams = nan(size(fall2015Data(i).FishParameters,1),sizeOfCurFishParams);
    curFishParams(1,:) = 1:sizeOfCurFishParams;
    
    % Loop through each fish
    for j=1:size(fall2015Data(i).FishParameters,2)
        
        curFishParams(:,fall2015Data(i).FishParameters(1,j)) = fall2015Data(i).FishParameters(:,j);
        
    end
    
    % Order parameters by fish number
    fall2015Data(i).FishParameters = curFishParams;
    
end

save(strcat('Fall2015Data_',date),'fall2015Data');