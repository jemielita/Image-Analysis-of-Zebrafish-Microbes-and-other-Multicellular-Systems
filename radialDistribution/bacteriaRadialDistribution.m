%bacteriaRadialDistribution: Calculate the distance of each bacteria from
%the approximate center of the gut. This analysis will use the spots found
%in the gut using our classifier. The center of the gut will be defined
%(since we don't have a good marker for the edge of the gut in this data)
%as the centroid of the cloud of red and green bugs in that particular
%wedge.
%
% NOTE: Currently this code filter the data in 'singleBacCount' further
% using the set up classifier-should probably be a flag for this at some
% point.
% USAGE radDist = bacteriaRadialDistribution(param, minS, maxS, windowSize)
%
% INPUT param: fish parameter file. The directory singleBacCount must exist
%        and the classifier set up for this particular fish.
%
%       minS, maxS: (optional. Default: scan length given by param)
%        maximum and minimum scan to calculate the radial
%        distribution for.
%       windowSize: (optional. Default = 3) Number of wedges before and
%       after current wedge to include in calculating the radial
%       distribution at that point in the gut. Currently not supported!
%       
% OUTPUT radDist: cell array of size (maxS-minS+1)x numColor that contains
% the distance of each bacteria the center of the gut.
%
% AUTHOR Matthew Jemielita, October 1, 2013

function radDist = bacteriaRadialDistribution(param, varargin)

%% Loading in variables
switch nargin
    case 1
        minS = 1;
        maxS = param.expData.totalNumberScans;
        
        windowSize = 10; %Each of our wedges has a width of 5 microns.
    case 4
        minS = varargin{1};
        maxS = varargin{2};
        windowSize = varargin{3};
    otherwise
        fprintf(2, 'Functions requires 1 or 4 inputs!\n');
        return;
end
fileDir = [param.dataSaveDirectory filesep 'singleBacCount'];
numColor = length(param.color);

radDist = cell(maxS-minS+1, numColor);

%% Going through each scan
fprintf(1, 'Finding radial distribution.');
for nS= minS:maxS
    fprintf(1, '.');
    inputVar = load([fileDir filesep 'bacCount' num2str(nS) '.mat']);
    rProp = inputVar.rProp;
    
    
    lineLength = size(param.centerLineAll{nS},1);
    
    
    
    for nC= 1:numColor
        %Filtering data further-probably shouldn't be done here.
        
        classifierType = 'svm';
        
        %To deal with our manual removal of early time GFP spots.
        if(nC==1)
            useRemovedBugList = true;
        else
            useRemovedBugList = false;
        end
        
        rProp{nC} = bacteriaCountFilter(rProp{nC}, nS, nC, param, useRemovedBugList, classifierType);
        
        
        
        
        radDist{nS, nC} =  cell(ceil(lineLength/windowSize) ,1);
        
        %First column: location of this bug down the length of the gut.
        bugInd = [rProp{nC}.sliceNum];
        
        nL = 1+windowSize;
        n = 1;
        while nL < lineLength
            minVal = max(nL-windowSize,0);
            maxVal = min(nL+windowSize, lineLength);
            
            ind = bugInd>=minVal & bugInd<=maxVal;
    
            pos = [rProp{nC}(ind).CentroidOrig];
            pos = reshape(pos, 3,length(pos)/3);
            pos = pos';
            
            if(~isempty(pos) &&size(pos,1)>1)
                centroid = mean(pos);
                
                %Get plan of the gut at this point
                cL= param.centerLineAll{nS}(minVal:maxVal,:);
                
                %Testing our algorithm
                figure; plot3(pos(:,1), pos(:,2), pos(:,3),'*');
                hold on
                plot3(cL(:,1), cL(:,2), ones(size(cL,1),1), 'Color', [0.8 0.2 0.4]);
                plot3(centroid(1), centroid(2), centroid(3), 'ok', 'MarkerSize', 10);
                bugDist = sqrt(sum((pos - repmat(centroid, [], size(pos,1))).^2, 2));
                bugDist =0.1625*bugDist; %microns per pixel
                radDist{nS,nC}{n} = bugDist;
            else
                radDist{nS, nC}{n} = [];
            end
           
            nL = nL+windowSize; n = n+1;
        end
        
    end
    
    
    
end
fprintf(1, '\n');

end