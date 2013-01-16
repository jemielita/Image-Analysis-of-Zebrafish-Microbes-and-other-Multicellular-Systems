%analyzeGutSingleRegion: analyze features of a certain region of the gut.
%The exact ordering of filtering and analysis is chosen by the user.
%
%USAGE regFeatures = analyzeGutSingleRegion(param, cutNum,analysisType,
%                    scanNum, colorList, centerLine, gutMask)
%
%INPUT param: experimental parameters
%      cutNum: which cut of the gut to analyze (from param.cutVal)
%      analysisType: structure with n entries where each entry is a
%      particular step in the analysis protocol
%      analysisType(i).name: name of the filtering or analysis we will do
%      this region of the gut
%      analysisType(i).param: cell array that contains all parameters
%      needed to do this filtering/analysis
%      analysisType(i).return = true or false: return this part of the
%      analysis. If not set then regFeatures{i} will be empty
%      scanNum: which scan number to analyze
%      colorList: cell array containing all colors to analyze. If colorList
%      = 'all', then all colors will be analyzed
%      centerLine: (optional) cell array containing the center line for
%      this particular cut region. If this is not an input it will be
%      calculated.
%      gutMask: (optional) cell array containing the gut mask for this
%      particular cut region. If this is not an input it will be
%      calculated.
%OUTPUT regFeatures: cell array with n entries that give the results of
%       each step of the analysis.
%    ex. analysisType.Name = 'lineDist'
%        analysisType.return = 'true'
%     regFeatures then contains the intensity curve as a function of the
%     length of the gut
%
%AUTHOR: Matthew Jemielita, August 3, 2012

function regFeatures = analyzeGutSingleRegion(param,cutNum,analysisType,...
    scanNum, colorList,varargin)

%% Loading in parameters for analyzing this scan
%Load in this region
imVar.color = colorList;
imVar.zNum = '';
imVar.scanNum = scanNum;

totNumSteps = length(analysisType);

regFeatures = cell(totNumSteps,length(colorList));

%Repeating analysis for each color.
%mlj: Should switch things up a bit to make it easier to do 2-color
%analysis on large data stacks. But this can wait for now.
for colorNum =1:length(colorList)
    clear imStack
    color = colorList{colorNum};
    %% Loading in image stack
    if(nargin ==5)
        [imStack, centerLine, gutMask] = constructRotRegion(cutNum, scanNum, color, param);
        totNumSteps = length(analysisType);
    elseif(nargin==7)
        imVar.color = color;
        imVar.zNum = '';
        imVar.scanNum = scanNum;
        fprintf(1, 'Loading image stack');
        imStack = load3dVolume(param, imVar, 'multiple', [cutNum, scanNum]);
        fprintf(1, '\n');
        centerLine = varargin{1};
        gutMask = varargin{2};
        
        %Gut mask will be a cell if we've done additional segmentation
        %before 
        if(iscell(gutMask))
            allMasks = sum(gutMask{colorNum},3);
        else
            allMask = sum(gutMask,3);
        end
        
        allMasks = allMasks==0;
        fprintf(1, 'Setting pixels outside the mask to NaN');
        for i=1:size(imStack,3)
            temp = imStack(:,:,i);
            temp(allMasks) = NaN;
            imStack(:,:,i) = temp;
            fprintf(1, '.');
        end
        clear temp
        fprintf(1, '\n');
        
    end
    
    %% Doing all the analysis steps
     if(size(imStack,1)~=size(gutMask,1) ||size(imStack,2)~=size(gutMask,2))
       disp('Image stack dimensions do not match gut mask dimensions!');
       
     end
     
     for stepNum = 1:totNumSteps
         if(iscell(gutMask))
             regFeatures{stepNum, colorNum} = ...
                 analysisStep(imStack, centerLine, gutMask{colorNum}, analysisType,regFeatures,...
                 stepNum, colorNum);
         else
             regFeatures{stepNum, colorNum} = ...
                 analysisStep(imStack, centerLine, gutMask, analysisType,regFeatures,...
                 stepNum, colorNum);
         end
         
     end
    
end

%% Discard entries in regFeatures
for stepNum = 1:totNumSteps
    for colorNum =1:length(colorList)
        
        if(analysisType(stepNum).return==false)
            regFeatures{stepNum,colorNum} = [];
        end
    end
end



clear imStack centerLine gutMask
end


%Large switch function that contains all the analysis functions that we've
%worked on so far
function thisRegFeatures = analysisStep(imStack, centerLine, gutMask,...
    analysisType, regFeatures, stepNum,colorNum)

switch analysisType(stepNum).name
    
    
    case 'radialProjection'
        %mlj: Need to build in support for preallocating arrays
        thisRegFeatures = radialProjection(imStack, centerLine, gutMask);
        
    case 'linearIntensity'
        binSize = analysisType(stepNum).binSize;
        thisRegFeatures = intensityCurve(imStack, gutMask,centerLine,binSize);
    
    case 'backgroundHistogram'
        %Identical code as the linear intensity code, but given a different
        %name to make it easier to distinguish from other code
        binSize = analysisType(stepNum).binSize;
        thisRegFeatures = intensityCurve(imStack, gutMask,centerLine,binSize);
    
    case 'linearIntensityBkgSub'
        bkgList = analysisType(stepNum).bkgList;
        thisRegFeatures = intensityBkgSubCurve(imStack, gutMask, centerLine, bkgList);
        
    case 'radialDistribution'
        %Find the point in this analysis chain where we calculate the
        %radial projections
        
        %Use previously calculated radial projections
        ind = analysisType(stepNum).param.father;
        if(~strcmp(analysisType(ind).name, 'radialProjection'))
            fprintf(2, 'radialDistribution error: Pointer to radial projections is incorrect!');
            error = 1;
            return
        else
            %mlj: (note) The speed of this code is basically the same if
            %cellfun, for loop, or parfor loop is  used. 
           thisRegFeatures = radDistAll(regFeatures{ind}, centerLine, ...
               analysisType(stepNum).param);
       
           
          
        end
        
    case 'test'
        thisRegFeatures = 1:length(centerLine);
    case 'projection'
        %Get a particular projection of this region.
        
end


%mlj: need to deal with saving the results appropriately.

end

function intenR = radDistPar(radIm, centerLine, analParam)

end

    function intenR = radDistAll(radIm, centerLine, analParam)
fprintf(1, '\n Calculating radial distribution...');
radBin = analParam.binSize;

ind = 1:length(radIm);

%Calculating the radial distribution for each of these regions.
intenR = arrayfun(@(x) radDist(radIm{x},  radBin), ind,...
    'UniformOutput', false);
fprintf(1, 'done!\n');
end