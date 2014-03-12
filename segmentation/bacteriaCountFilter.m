%bacteriaCountFilter: Filters bacteria counts in /singleBacCount/ using the
%variables in /singleBacCount/bacteriaClassifier.mat
%
% USAGE    rPropOut = bacteriaCountFilter(rProp, scanNum, colorNum, param)
%          rPropOut = bacteriaCountFilter(rProp, scanNum, colorNum, param, useRemovedBugList)
%          rPropOut = bacteriaCountFilter(rProp, scanNum, colorNum, param, useRemovedBugList, classifierType)
%          rPropOut = bacteriaCountFilter(rProp, scanNum, colorNum, param, useRemovedBugList, classifierType, distCutoff_combRegions)
%
% INPUT -rProp: structure containing information about each found spot.
%       -param: parameter file for this fish. Will be used to point towards
%       the location for the bacteria classifier variables.
%       -scanNum: scan to filter.
%       -colorNum: color to filter 1 = '488nm', 2 = '568nm'.
%       -useRemovedBugList: (optional. Default = false) before using a 
%       classifier to filter data remove ones that have beeen manually
%       removed. Classification error may be changed if object is
%       pre-filtered. If useRemovedBugList is an array then use this array
%       as the list of spots to remove.
%       -classifierType: (optional. Default = 'svn') Type of classifier to
%       use. Currently supported:
%           -'svn': support vector machine using a gaussian radial basis
%           function. Data trained somewhere else. MATLAB's svmclassify and
%           svmtrain are used.
%           -'linear': linear multi-variate classifer. MATLAB's classify is
%           used.
%          -'none': No classifier used. Can be useful when combined with
%          removed bug list.
%          -'none_plusAutoFluor': No classifier used, except for intensity
%          filter in the autofluorescent region of the gut.
%           
%       distCutoff_combRegions (default= false). If true filter out regions
%       based on proximity to each other.
% OUTPUT rPropOut: Filtered version of rProp.
%        index: (optional) The index in the original list of rProp of the found bacteria.
%             Useful for applying multiple layers of analysis.
%           index.Correct: correctly labelled bacteria
%           index.InCorrect: incorrectly labelled bacteria.
% AUTHOR Matthew Jemielita, Sep. 6, 2013

function [rPropOut, varargout] = bacteriaCountFilter(rProp, scanNum, colorNum, param, varargin)

switch nargin
    case 4
        useRemovedBugList = false;
        classifierType = 'svm';
        distCutoff_combRegions = false;
    case 5
        useRemovedBugList = varargin{1};
        classifierType = 'svm';
        distCutoff_combRegions = false;
    case 6
        useRemovedBugList = varargin{1};
        classifierType = varargin{2};
        distCutoff_combRegions = false;
    case 7
        useRemovedBugList = varargin{1};
        classifierType = varargin{2};
        distCutoff_combRegions = varargin{3};
        
end
    

if(~islogical(useRemovedBugList))
    keptSpots = useRemovedBugList;
    useRemovedBugList = true;
    
else
    
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
    
end



%Not really the correct place to do this, but find empty gut
%locations and set them to 6-a.k.a undefiniable at this point
for i=1:length(rProp)
    if(isempty(rProp(i).gutRegion))
        rProp(i).gutRegion = 6;
    end
end

%Not best place to put in index, but it'll do for now
for i=1:length(rProp)
    rProp(i).ind = i;
end

%Cull out bacterial spots.-should have better spot for playing
%around with these numbers.
% cullProp.radCutoff(1) = ''; %Cutoff in the horizontal direction
% cullProp.radCutoff(2) = '';


rProp = rProp(keptSpots);


%Run filters that don't need the use of any type of classifier

switch classifierType
    case 'none'
        
        colorThresh = [0,0];
        areaThresh = [3,3];
        
        rProp = rProp([rProp.Area]>areaThresh(colorNum));
        
        rProp = rProp([rProp.MeanIntensity]>colorThresh(colorNum));
        
        
        rPropOut = rProp;
        return
        
    case 'none_plusAutoFluor'
        colorThresh = [0,0];
        areaThresh = [3,3];
        
        rProp = rProp([rProp.Area]>areaThresh(colorNum));
        
        rProp = rProp([rProp.MeanIntensity]>colorThresh(colorNum));
        
        
        inAutoFluor = [rProp.gutRegion]==3;
        outsideAutoFluor = ~inAutoFluor;
        %Remove low intensity points in this region
        
        autoFluorMaxInten(colorNum) = 90;
        inAutoFluorRem = [rProp.MeanIntensity]<autoFluorMaxInten(colorNum);
        
        
        removedSpots = and(inAutoFluor,inAutoFluorRem);
        
        keptSpots = or(~removedSpots, outsideAutoFluor);
        
        rProp = rProp(keptSpots);
        
        rProp = rProp([rProp.Area]>areaThresh(colorNum));
        
        rProp = rProp([rProp.MeanIntensity]>colorThresh(colorNum));
        
        rPropOut = rProp;
        return;
%        removedSpots = inAutoFluor;
        
        
        %keptSpots = find(or(outsideAutoFluor, inAutoFluor)==1);
        
        rProp = rProp(and(outsideAutoFluor,~removedSpots));
        sum(removedSpots);
       % rProp = rProp(logical(removedSpots));
        rPropOut = rProp;
        
        return
    case 'manualSelection'
        %Use the manually selected found spots from the list in
        %singleBacCount
        inputVar = load([param.dataSaveDirectory filesep 'singleBacCount' filesep 'removedBugs.mat']);
        keepBugInd = inputVar.keepBugInd;
        ind = keepBugInd{scanNum, colorNum};
        rPropOut = rProp(ind);
        return
    otherwise
        %continue with analysis
end




%Load in filtering parameters
inputVar = load([param.dataSaveDirectory filesep 'singleBacCount' filesep 'bacteriaClassifier.mat']);

autoFluorMaxInten = inputVar.autoFluorMaxInten;
cullProp = inputVar.cullProp;
trainingListLocation = inputVar.trainingListLocation;
classifierType = inputVar.classifierType;
classifierType = classifierType{colorNum};

if(isfield(inputVar, 'scanCutoff'))
   scanCutoff = inputVar.scanCutoff; 
else
    scanCutoff =[];
end
    


%In the display apply a harsher threshold for the spots found in
%the autofluorescent region.
if(isfield(rProp, 'gutRegion'))
    inAutoFluor = [rProp.gutRegion]==3;
    outsideAutoFluor = ~inAutoFluor;
    %Remove low intensity points in this region
    
    %mlj: Commenting out this line for now
   % autoFluorMaxInten(colorNum) = 50;
    inAutoFluorRem = [rProp.MeanIntensity]>autoFluorMaxInten(colorNum);
    inAutoFluor = and(inAutoFluor,inAutoFluorRem);
    
    
    
    keptSpots = intersect(keptSpots, find(or(outsideAutoFluor, inAutoFluor)==1));
    
    % rProp = rProp(keptSpots);
    %xyz = xyz(:, keptSpots);
    
    
end

%Remove spots that are past the autofluorescent region
%insideGut = find([rProp.gutRegion]<=3);
%keptSpots = intersect(keptSpots, insideGut);

%Remove spots that we've filtered to this point
rProp = rProp(keptSpots);

if(strcmp(classifierType, 'none'))
%     
%     colorThresh = [0,0];
%     areaThresh = [3,3];
% if(~isempty(rProp))
%     rPropOut = rProp([rProp.Area]>areaThresh(colorNum));
%     
%     rPropOut = rPropOut([rPropOut.MeanIntensity]>colorThresh(colorNum));
%     rPropOut = rProp;
% else
    rPropOut = rProp;


    return
end


%Check to make sure the list is non-empty, otherwise break here.
if(length(rProp)<1)
    rPropOut = rProp;
    return
end

switch classifierType
    
    case 'linear'

        inputVar = load(trainingListLocation{colorNum});
        trainingList = inputVar.allData;
        
        rPropOut = bacteriaLinearClassifier(rProp, trainingList);
        
    case 'svm'
        
        inputVar = load(trainingListLocation{colorNum});
        if(~isempty(scanCutoff) && isfield(inputVar, 'svmStructMulti'))
            
            whichRow = find(scanNum>= scanCutoff(:,1), 1, 'last');
            whichClassifier = scanCutoff(whichRow,2);
            svmStruct = inputVar.svmStructMulti{whichClassifier};
        else
            svmStruct = inputVar.svmStruct;
        end
        
        if(iscell(svmStruct))
           if(length(svmStruct)>1)
               svmStruct = svmStruct{colorNum};
           else
               svmStruct = svmStruct{1};
           end
        end
        
        rPropOut = bacteriaSVMClassifier(rProp, svmStruct);
        
    case 'none'
    %    rPropOut = rProp;
       
    case 'manualSelection'
        %This analysis type is run above.
        
end


if(distCutoff_combRegions ==true)
    %Filter based on proximity to adjacent spots
    radCutoff = (1/0.1625)*[0.5, 3];
    rPropOut = combineRegions(rPropOut, radCutoff);
end

index.Correct = [rPropOut.ind];
index.Incorrect = setdiff(keptSpots, [rPropOut.ind]);



if(nargout==2)
    
    varargout{1} = index;
end

end