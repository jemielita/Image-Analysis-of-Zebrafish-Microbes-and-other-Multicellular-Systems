%bacteriaCountFilter: Filters bacteria counts in /singleBacCount/ using the
%variables in /singleBacCount/bacteriaClassifier.mat
%
% USAGE rPropOut = bacteriaCountFilter(rProp, scanNum, colorNum, param)
%
% INPUT rProp: structure containing information about each found spot.
%       param: parameter file for this fish. Will be used to point towards
%       the location for the bacteria classifier variables.
%
% OUTPUT rPropOut: Filtered version of rProp.
%
% AUTHOR Matthew Jemielita, Sep. 6, 2013

function rPropOut = bacteriaCountFilter(rProp, scanNum, colorNum, param)

%Load in filtering parameters
inputVar = load([param.dataSaveDirectory filesep 'singleBacCount' filesep 'bacteriaClassifier.mat']);

autoFluorMaxInten = inputVar.autoFluorMaxInten;
cullProp = inputVar.cullProp;
trainingListLocation = inputVar.trainingListLocation;


useRemovedBugList = false;
if(useRemovedBugList==true)
    
    %Load in list of removed bugs, if we manually removed some.
    remBugsSaveDir = [param.dataSaveDirectory filesep 'singleBacCount' filesep 'removedBugs.mat'];
    if(exist(remBugsSaveDir, 'file')==2)
        removeBugInd = load(remBugsSaveDir);
        removeBugInd = removeBugInd.removeBugInd;
        removeBugInd = removeBugInd{scanNum, colorNum};
    else
        removeBugInd = [];
    end
    keptSpots = setdiff(1:length(rProp), removeBugInd);
else
    keptSpots = 1:length(rProp);
end

%Not really the correct place to do this, but find empty gut
%locations and set them to 6-a.k.a undefiniable at this point
for i=1:length(rProp)
    if(isempty(rProp(i).gutRegion))
        rProp(i).gutRegion = 6;
    end
end

%Cull out bacterial spots.-should have better spot for playing
%around with these numbers.
% cullProp.radCutoff(1) = ''; %Cutoff in the horizontal direction
% cullProp.radCutoff(2) = '';
%rProp = rProp(keptSpots);

%In the display apply a harsher threshold for the spots found in
%the autofluorescent region.
if(isfield(rProp, 'gutRegion'))
    inAutoFluor = [rProp.gutRegion]==3;
    outsideAutoFluor = ~inAutoFluor;
    %Remove low intensity points in this region
    
    inAutoFluorRem = [rProp.MeanIntensity]>autoFluorMaxInten(colorNum);
    inAutoFluor = and(inAutoFluor,inAutoFluorRem);
    
    keptSpots = intersect(keptSpots, find(or(outsideAutoFluor, inAutoFluor)==1));
    
    % rProp = rProp(keptSpots);
    %xyz = xyz(:, keptSpots);
end

%Remove spots that are past the autofluorescent region
insideGut = find([rProp.gutRegion]<=3);
keptSpots = intersect(keptSpots, insideGut);

%Remove spots that we've filtered to this point
rProp = rProp(keptSpots);

%Not best place to put in index, but it'll do for now
for i=1:length(rProp)
    rProp(i).ind = i;
end


inputVar = load(trainingListLocation{colorNum});
trainingList = inputVar.allData;

rProp = bacteriaLinearClassifier(rProp, trainingList);

% switch colorNum
%     case 1
%         cullProp.radCutoff = [1 3 ];
%         cullProp.minRadius = 1;
%         cullProp.minInten = 50;
%         cullProp.minArea = 4;
%         %rProp2 = cullFoundBacteria(rProp, '', cullProp, '', '');
%         
%         b = load(training);
%         trainingList = b.allData;
%         
%         rProp = bacteriaLinearClassifier(rProp, trainingList);
%     case 2
%         cullProp.radCutoff = [5 2 ];
%         cullProp.minRadius = 2;
%         cullProp.minInten = 34;
%         cullProp.minArea = 5;
%         
%         %Use a classifier to reduce down the identified spots
%         b = load(['D:\HM21_Aeromonas_July3_EarlyTimeInoculation\fish2\gutOutline\cullProp' filesep 'rProp.mat']);
%         trainingList = b.allData;
%         rProp = bacteriaLinearClassifier(rProp, trainingList);
%         %rProp = cullFoundBacteria(rProp, '', cullProp, '', '');
% end

rPropOut = rProp;


end