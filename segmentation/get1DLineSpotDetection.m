
%get1DLineSpotDetection: Construct a 1-D line distribution for analysis
%done using the spot detection code.
%
% USAGE lineDist = get1DLineSpotDetection(param, dataDir)
%       lineDist = get1DLineSpotDetection(param, dataDir, saveLine)
%       lineDist = get1DLineSpotDetection(param, dataDir, saveLine, colorList)
%       lineDist = get1DLineSpotDetection(param, dataDir, saveLine, colorList, )
% INPUT param: parameter file for this data
%
%       dataDir: (optional. default: param.dataSaveDirectory/singleBacCount)
%            directory containing individual scans taken. This
%            directory must contain .mat files with the following syntax:
%            "bacCount"+scanNum ".mat". The function loops through all scans given by
%            the number of scans as recorded in param.
%
%       saveLine: (optional, default=true) save the saved line to the file lineDist.mat
%       file in the dataDir directory. lineDist.mat has the following
%       syntax: lineDist{scanNum,colorNum}(linePos)-gives the number of
%       points found for a given scan, color and position down the line.
%
%       colorList: (Optional. default: all) List of which colors to analyze
%       (e.g. [1,2]). Should change syntax to take in wavelengths instead.
%
%       classifierTypeList (Optional. Default: 'svm'). Cell array containing
%       type of classifier to run on data for each color channel.
%       (Possible values: 'svm', 'none', 'manualSelection').

% OUTPUT lineDist (optional): line distribution code, with the same syntax
% as given in the documentation for saveLine above.
%        popTot (optional): sum of the line distribution down the length of
%        the gut.
% AUTHOR Matthew Jemielita, Sep 4, 2013.

function varargout = get1DLineSpotDetection(param, varargin)


[numColor, classifierTypeList,saveLine, dataDir, recalculate, rPropAll, cList, minS, maxS] = ...
    get1DLineSpotDetection_parameters(param, varargin);


for nS = minS:maxS
    
   bugArraySize = size(param.centerLineAll{nS},1);
   
   %Need to think about the path of our data through this analysis!!
   %rProp = cullBacteriaData(rProp);
   
   
   for thisColor = 1:numColor
       nC = cList(thisColor);
       
       classifierType = classifierTypeList{nC};
       
       
       %% Loading in bacteria population data
       if(recalculate ==true)
           fileDir = [dataDir filesep 'bacCount' num2str(nS) '.mat'];
           inputVar = load(fileDir);
           rProp = inputVar.rProp;
           
           if(iscell(rProp))
               if(length(rProp)>1)
                   rProp = rProp{nC};
               else
                   rProp = rProp{1};
               end
           end

           useRemovedBugList = true;       
           rProp = bacteriaCountFilter(rProp, nS, nC, param, useRemovedBugList, classifierType);
       
       else
           rProp = rPropAll{nS,nC};
       end
       
       if(isempty(rProp))
           lineDist{nS,nC} = zeros(1, bugArraySize);
           popTot(nS, nC) =0;
           continue
       end
           
       
       %% Unpacking bacteria population data
       numBac = [rProp.sliceNum];

       u = 1:bugArraySize;
      
       numEl = arrayfun(@(y)sum(numBac==y),u);
   
       lineDist{nS,nC} = numEl; 
       
       if(isempty(numEl))
           lineDist{nS,nC} = zeros(1, bugArraySize);
       end
       
       popTot(nS, nC) = sum(numEl);
   end
   
end

%% Outputs of function
if(saveLine==true)
    save([dataDir filesep 'lineDist.mat'], 'lineDist');
end


switch nargout
    case 0
        %Do nothing
    case 1
        varargout{1} = lineDist;
    case 2
        varargout{1} = lineDist;
        varargout{2} = popTot;
    otherwise
        frprintf(2, 'Functions takes 0 or 1 outputs!');
        return
end
       



end

function [numColor, classifierTypeList,saveLine, dataDir, recalculate, rPropAll, cList, minS, maxS] = ...
    get1DLineSpotDetection_parameters(param, varargin)
%% Collecting together all inputs
numColor = length(param.color);
cList = zeros(numColor,1);

for nC=1:numColor
    classifierTypeList{nC} = 'svm';
end

rPropAll = []; %Empty unless used.

switch nargin
    case 1
        saveLine = true;
        dataDir = [param.dataSaveDirectory filesep 'singleBacCount'];
        recalculate = true;
    case 2
        saveLine = true;
        rPropAll = varargin{1};
        recalculate = false;
    case 3
        %mlj: bad way to do this...
        recalculate = true;
        rPropAll = varargin{1};
        saveLine = varargin{2};
        %  dataDir = varargin{1};
        %case 3
        %    dataDir = varargin{1};
        %    saveLine = varargin{2};
    case 4
        recalculate = true;
        dataDir = [param.dataSaveDirectory filesep 'singleBacCount'];
        saveLine = varargin{2};
        cList = varargin{3};
        numColor = length(cList);
        
    case 5
        recalculate = true;
        dataDir = [param.dataSaveDirectory filesep 'singleBacCount'];
        saveLine = varargin{2};
        cList = varargin{3};
        numColor = length(cList);
        classifierTypeList = varargin{4};
        
    otherwise
        fprintf(2, 'Function requires 2 -4 inputs!');
        return
end

minS = 1;
maxS = param.expData.totalNumberScans;

end



