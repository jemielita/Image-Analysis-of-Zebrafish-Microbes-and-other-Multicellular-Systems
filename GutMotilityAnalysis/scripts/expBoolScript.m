% This is a script which maintains several arrays of bools associated with various
% experimental parameters which, when combined, allow rapid plot making with
% only relevant and trustworthy data.
%
% There are currently 2-3 bools which are ANDed together to form the final bool. They are:
% - If there is no food in the gut (only guts without food are allowed)
% - If the fish failed analysis for some parameters (forms a new column in the final bool)
% - If the fish couldn't be tracked (only tracked fish are allowed)
%
% The final boolean array, allBools(i,j,k,l), has the following convention:
% - i is the ith fish number
% - j is the type of fish (1 = WTU, 2 = WTF, 3 = Ret)
% - k is the jth parameter (column 1 is the first two 2 bools ANDed, column 2 are all bools ANDed)
% - l is the experiment, in chronological order (e.g., 1 is August 5dpf, 3 is August 7dp, 4 is September 5dpf, etc)

%% Initialize variables
typeBoolCell = cell( 1, 9 );
noFoodBoolCell = cell( 1, 9 );
nanBoolCell = cell( 1, 9 );
trackedBoolCell = cell( 1, 9 );
useBoolCell = cell( 3, 9 ); % First index is bools ANDed without nanBool, second is all bools ANDed, third is the typeBool
augustFolders = {'8_19_15','8_20_15','8_21_15'};
septemberFolders = {'9_16_15','9_17_15','9_18_15'};
novemberFolders = {'11_4_15','11_5_15','11_6_15'};

boolTitles = {'WTU vs Ret 8_19_15','WTU vs Ret 8_20_15','WTU vs Ret 8_21_15',...
          'WTU vs WTF vs Ret 9_16_15','WTU vs WTF vs Ret 9_17_15',...
          'WTU vs WTF vs Ret 9_18_15','WTU vs WTF 11_4_15',...
          'WTU vs WTF 11_5_15','WTU vs WTF 11_6_15'};

boolTitles = [boolTitles;boolTitles;boolTitles];

%% Fish type bools from experiments

% Variable naming convention: First letter is month (A=August, etc), first 
% number is dpf.
% Indices are for r = type (WTU, WTF, Ret), c = fish number

% August
A5 = logical([[1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0];...
              [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];...
              [0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1]]);
A6 = logical([[0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1];...
              [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];...
              [1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0]]);
A7 = logical([[1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0];...
              [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];...
              [0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1]]);
  
% September
S5 = logical([[1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,0];...
              [0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0];...
              [0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0]]);
S6 = logical([[1,0,1,0,1,0,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0];... % You'll notice the order is off (F5 and F6), which is on purpose. See lab notebook
              [0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0];...
              [0,0,0,0,0,1,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]]);
S7 = logical([[1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,0,0,0];...
              [0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,1,0,1,0,0,0,0];...
              [0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0]]);
  
% November
N5 = logical([[1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0];...
              [0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1];...
              [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]);
N6 = logical([[1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0];...
              [0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1];...
              [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]);
N7 = logical([[1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0];...
              [0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1];...
              [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]);

% Place these into an array that can be indexed 
typeBoolCell{1} = A5;
typeBoolCell{2} = A6;
typeBoolCell{3} = A7;
typeBoolCell{4} = S5;
typeBoolCell{5} = S6;
typeBoolCell{6} = S7;
typeBoolCell{7} = N5;
typeBoolCell{8} = N6;
typeBoolCell{9} = N7;

%% No food in Gut bools

% Variable naming convention: First letter is month (A=August, etc), first 
% number is dpf, last letter is the type of bool (NF = No food in gut)

% August
A5_NF = logical([1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]);
A6_NF = logical([1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]);
A7_NF = logical([1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]);

% September
S5_NF = logical([1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,0,1,0]);
S6_NF = logical([1,0,1,0,1,1,0,1,1,1,1,1,1,0,1,1,0,1,1,1,1,1,1,0,1,1,1,1,0,1,1,1,1,1,1]);
S7_NF = logical([1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,1]);

% November
N5_NF = logical([1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]);
N6_NF = logical([1,1,1,0,1,1,1,1,1,0,1,1,1,0,1,0,1,0,1,0,1,1]);
N7_NF = logical([1,1,1,1,1,1,1,1,1,1,1,0,1,0,1,1,1,0,1,1,1,1]); %Note: 10 drifts too far

% Place these into an array that can be indexed 
noFoodBoolCell{1} = A5_NF;
noFoodBoolCell{2} = A6_NF;
noFoodBoolCell{3} = A7_NF;
noFoodBoolCell{4} = S5_NF;
noFoodBoolCell{5} = S6_NF;
noFoodBoolCell{6} = S7_NF;
noFoodBoolCell{7} = N5_NF;
noFoodBoolCell{8} = N6_NF;
noFoodBoolCell{9} = N7_NF;

%% Load bools obtained from analysis and which have been tracked
% Warning: This section is opaque

nanBoolCell{1} = false(1,length(A5_NF));
nanBoolCell{2} = false(1,length(A6_NF));
nanBoolCell{3} = false(1,length(A7_NF));
nanBoolCell{4} = false(1,length(S5_NF));
nanBoolCell{5} = false(1,length(S6_NF));
nanBoolCell{6} = false(1,length(S7_NF));
nanBoolCell{7} = false(1,length(N5_NF));
nanBoolCell{8} = false(1,length(N6_NF));
nanBoolCell{9} = false(1,length(N7_NF));

trackedBoolCell{1} = false(1,length(A5_NF));
trackedBoolCell{2} = false(1,length(A6_NF));
trackedBoolCell{3} = false(1,length(A7_NF));
trackedBoolCell{4} = false(1,length(S5_NF));
trackedBoolCell{5} = false(1,length(S6_NF));
trackedBoolCell{6} = false(1,length(S7_NF));
trackedBoolCell{7} = false(1,length(N5_NF));
trackedBoolCell{8} = false(1,length(N6_NF));
trackedBoolCell{9} = false(1,length(N7_NF));

mainFolderA=uigetdir('Where is the August directory located?');
mainFolderS=uigetdir('Where is the September directory located?');
mainFolderN=uigetdir('Where is the November directory located?');

% Loop through dpfs
for i=1:3
    
    nextDir = {strcat(mainFolderA,filesep,augustFolders{i}),strcat(mainFolderS,filesep,septemberFolders{i}),strcat(mainFolderN,filesep,novemberFolders{i})};
    
    % Loop through months (index for chronological order is 3*(j-1)+i
    for j=1:3
        
        % Obtain all fish folders to loop through
        fishFolders=dir(nextDir{j});
        fishFolders(strncmp({fishFolders.name}, '.', 1)) = []; % Removes . and .. and hidden files
        fishFolders(~[fishFolders.isdir])=[]; % Removes any non-directories
        
        fishNums = [];
        
        % Obtain a list of the fish in the directory, in the same order as the saved bool
        for k=1:size(fishFolders,1)
            
            fishNum = str2double(fishFolders(k).name(5:end));
            trackedBoolCell{3*(j-1)+i}(fishNum) = true;
            fishNums = [fishNums, fishNum]; %#ok
            
        end
        
        % Load the fishBool array, choose if multiple
        curBoolArray = dir(strcat(nextDir{j},filesep,'fishBools*.mat'));
        fileIndex = 1;
        if( length(curBoolArray) > 1)
            disp('Multiple fishBool files; Pick one by entering the number');
            for k=1:length(curBoolArray)
                fileNumStr=sprintf('%i) %s',k,curBoolArray(k).name);
                disp(fileNumStr);
            end
            fileIndex=input('Which number?: ');
        end
        load(strcat(nextDir{j},filesep,curBoolArray(fileIndex).name)); % Should load variable useFishBools
        
        % Now we need to associate the index with the correct fish, get nan bool value
        for k=1:length(useFishBools)
            nanIndex = fishNums(k);
            nanBoolCell{3*(j-1)+i}(nanIndex) = useFishBools{k};
        end
        
    end
    
end

%% Create final bool for using a fish

for i=1:size(useBoolCell,2)
    useBoolCell{1,i} = noFoodBoolCell{i}&trackedBoolCell{i};
    useBoolCell{2,i} = noFoodBoolCell{i}&trackedBoolCell{i}&nanBoolCell{i};
    useBoolCell{3,i} = typeBoolCell{i};
end

Fall2015Bools = struct('titles', boolTitles, 'bools', useBoolCell);

saveDirectory=uigetdir(pwd,'Where would you like to save your bool arrays?'); %directory containing the images you want to analyze
save(strcat(saveDirectory,filesep,'Fall2015Bools_',date),'Fall2015Bools');