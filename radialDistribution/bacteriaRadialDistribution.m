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
% the distance of each bacteria to the center of the gut.
%       
%        radDistGutRegion: cell array of size (maxS-minS+1)x numColor that contains
%        the region in the gut of each found bacteria
% AUTHOR Matthew Jemielita, October 1, 2013

function [radDist, radDistGutRegion, convHull, regArea] = bacteriaRadialDistribution(param, varargin)

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
    
    
    %First load in data and find centroid of combined red, green channels.
    %Then go through data to find the distance of each point to this
    %centroid in the appropriate plane.
    for nC=1:numColor
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
    end
    
    nL = 1+windowSize;
    n = 1;
    while nL < lineLength
        minVal = max(nL-windowSize,0);
        maxVal = min(nL+windowSize, lineLength);
        posAll = [];
        for nC=1:numColor
            %First column: location of this bug down the length of the gut.
            bugInd = [rProp{nC}.sliceNum];
            ind = bugInd>=minVal & bugInd<=maxVal;
            
            pos = [rProp{nC}(ind).CentroidOrig];
            pos = reshape(pos, 3,length(pos)/3);
            pos = pos';
            posAll = [posAll; pos];
        end

        centroid(n,:) = mean(posAll);
        nL = nL+windowSize; n = n+1;
    end

    
    for nC= 1:numColor
        
        
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
                %centroid = mean(pos);
                
                %Get plane of the gut at this point
                cL = param.centerLineAll{nS}(minVal:maxVal,:);
                %Only keep the first and last point-this will be the line
                %through the gut at this point.
                cL = [cL(1,:); cL(end,:)];
                
                %Testing this code with a simple example
               % cL = [0,1; 4,0];
               
%                 if(cL(1,1)-cL(end,1) >0)
%                     cL2(1,:) = cL(end,:);
%                     cL2(2,:) = cL(1,:);
%                     cL = cL2;                    
%                 end
                %centroid = mean(pos);
                
                %centroid = [2,3,5];
                %pos = rand(10,3);
                %pos = pos+repmat(centroid,size(pos,1),1);
                
                %Get angle of center line
                theta = atan((cL(1,1)-cL(end,1))/(cL(1,2)-cL(end,2)));
                
                %Get unit vector with that angle
                planePerp = [cos(theta), sin(theta); -sin(theta), cos(theta)]*[0;1];
                planePerp = [planePerp; 0];
                planePerp = planePerp' + centroid(n,:);
                
                vecNew = planePerp;
                planePerp = planePerp-centroid(n,:);
                
%                 %pos = [2.4,2.88,5.88];
%                 vecCent = cL(end,:)-cL(1,:);
%                 vecCentroid = centroid(1:2)-cL(1,:);
%                 
%                 vecNew = cL(1,:) + dot(vecCent, vecCentroid)*(1/norm(vecCent)^2)*vecCent;
%                 
%                 
%                 %vecNew = cL(end,:)-vecNew;
%                 vecNew = [vecNew, centroid(3)];
%                 %vecNew = (1/norm(vecNew))*vecNew;
%                 %vecNew = vecNew + centroid;
%                 
%                 planePerp = vecNew;
%                 
%                 
%                 planePerp = planePerp-centroid;
%                 
%                 v1 = [cL(end,:)-vecNew(1:2), centroid(3)];
%                 v2 = centroid -vecNew;
%                 v3 = cross(v1, v2);
%                 v3 = vecNew + v3/norm(v3);  
%                 
%                 %Find the vector perpendicular to centroid/center line
%                 %plane, with origin at centroid
%                 vp1 = centroid-v3;
%                 vp2 = centroid - vecNew;
%                 vp3 = cross(vp1, vp2);
%                 
%                 
%                 vp1 = v3-centroid;
%                 vp2 = v3-vecNew;
%                 vp3 = cross(vp1,vp2);
%                 
%                 planePerp = (1/norm(vp3))*vp3 + centroid;
               % planePerp = (1/norm(planePerp))*planePerp;
                
                %Finding projection of all points onto this plane by
                %removing the part parallel to the vector perpendicular to
                %the plane
                posP = zeros(size(pos));
                for i=1:size(pos,1)
                    v = pos(i,:)-centroid(n,:);
                    vPar = dot(v, planePerp)*(1/norm(planePerp)^2)*planePerp;
                    vPerp = v - vPar;
                    posP(i,:) = centroid(n,:) + vPerp;
                end
                %Testing our algorithm
                plotData = false;
                if(plotData==true)
                    figure;
                    plot3(cL(:,1), cL(:,2), centroid(n,3)*ones(size(cL,1),1), 'Color', [0.8 0.2 0.4]);
                    hold on
                    plot3(centroid(n,1), centroid(n,2), centroid(n,3), 'ok', 'MarkerSize', 10);
                    
                    plot3(vecNew(1), vecNew(2), vecNew(3), 'or', 'MarkerSize', 10);
                    % plot3(v3(1), v3(2), v3(3), 'og', 'MarkerSize', 10);
                    %plot3(planePerp(1), planePerp(2), planePerp(3), 'ob', 'MarkerSize', 10);
                    
                    plot3(pos(:,1), pos(:,2), pos(:,3),'*');
                    plot3(posP(:,1), posP(:,2), posP(:,3), 'ok', 'MarkerSize', 2);
                end
                
                bugDist = sqrt(sum((posP - repmat(centroid(n,:), [], size(posP,1))).^2, 2));
                bugDist =0.1625*bugDist; %microns per pixel
                radDist{nS,nC}{n} = bugDist;
                radDistGutRegion{nS,nC}{n} = [rProp{nC}(ind).gutRegion];
            else
                radDist{nS, nC}{n} = [];
                
                radDistGutRegion{nS,nC}{n} = [];
            end
           
            nL = nL+windowSize; n = n+1;
        end
        
    end
    
    
    
end
fprintf(1, '\n');

convHull = [];
regArea = [];
end