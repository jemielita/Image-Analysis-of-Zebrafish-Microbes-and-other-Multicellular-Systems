
%get1DLineSpotDetection: Construct a 1-D line distribution for analysis
%done using the spot detection code.
%
% USAGE lineDist = get1DLineSpotDetection(param, dataDir, saveLine)
%
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
%       numColor: number of colors to analyze-should be a better input than
%       this.
% OUTPUT lineDist (optional): line distribution code, with the same syntax
% as given in the documentation for saveLine above.
%        popTot (optional): sum of the line distribution down the length of
%        the gut.
% AUTHOR Matthew Jemielita, Sep 4, 2013.

function varargout = get1DLineSpotDetection(param, varargin)

           
classifierType = 'svm';
numColor = length(param.color);
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


for nS = minS:maxS
    
   bugArraySize = size(param.centerLineAll{nS},1);
   
   %Need to think about the path of our data through this analysis!!
   %rProp = cullBacteriaData(rProp);
   
   
   for i = 1:numColor
       
       nC = cList(i);
       classifierType = classifierTypeList{nC};
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

           
           %To deal with our manual removal of early time GFP spots.

           %if(nC==1)
            %   useRemovedBugList = true;
           %else 
           %    useRemovedBugList = false;
           %end
           

           useRemovedBugList = true;
           
           if(~strcmp(classifierType, 'none'))
               rProp = bacteriaCountFilter(rProp, nS, nC, param, useRemovedBugList, classifierType);
           else
               disp('Not using a classifier! Just the manually removed spots.');
           end
       else
           rProp = rPropAll{nS,nC};
       end
       if(isempty(rProp))
           lineDist{nS,nC} = [];
           popTot(nS, nC) =0;
           continue
       end
           
       
       numBac = [rProp.sliceNum];

       
       u = 1:bugArraySize;
      
       numEl = arrayfun(@(y)sum(numBac==y),u);
   
       lineDist{nS,nC} = numEl; 
       
       popTot(nS, nC) = sum(numEl);
   end
   
    

   
end

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



