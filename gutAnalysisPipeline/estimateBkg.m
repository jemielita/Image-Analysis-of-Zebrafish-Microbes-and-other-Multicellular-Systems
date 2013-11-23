%estimateBkg: the estimated background at all point along the gut and at
%every time point for all fish.
%
% USAGE bkgInten = estimateBkg(pAll,smoothWindow)
%
% INPUT pAll: cell array of param files for different fish to estimate
% background for
%       subDir: (optional, default: '') subdirectory containing background
%       data.
% OUTPUT bkgInten: bkgInten{p_i,nC}{nS} the mean background along the
%        entire length of the gut for scan nS, color nC, and time nT.
%
% AUTHOR: Matthew Jemielita, November 13, 2012


function bkgInten = estimateBkg(pAll, varargin)

totNumP = length(pAll);


switch nargin
    case 1
        subDir = '';
        colorList = 'all';
    case 2
        subDir = varargin{1};
        colorList = 'all';
    case 3
        subDir = varargin{1};
        colorList = varargin{2};
end

for nP = 1:length(pAll)
    param = pAll{nP};
    
    if(strcmp(colorList, 'all'))
        numColor = length(param.color);
    else
        numColor = length(colorList);
    end
    
    numScan = param.expData.totalNumberScans;
    

    if(isempty(subDir))
        fileDir = param.dataSaveDirectory;
    else
        fileDir = [param.dataSaveDirectory filesep subDir];
    end
    
    if(isdir(fileDir))
        cd(fileDir);
        
        for nC=1:numColor
            
           maxBkg = smoothBkgData(param,nC,false, 1, numScan, [50,100]);
          
           %Now calculate the mean pixel intensity below this cutoff
           
           for nS=1:numScan

               
               load(['Analysis_Scan', num2str(nS), '.mat']);
               allBkg = regFeatures{nC,1};
               
               minL = 1;
               maxL = size(allBkg,1);
               
               ind = 1:2:2000;
               for nL=minL:maxL
                   minVal = 3;
                   maxVal = maxBkg{nS}(1,nL);
                   maxVal = round(maxVal);
                   [~,maxInd] = min(abs(ind-maxVal));
                   thisInd = ind(minVal:maxInd);
                   
                   bkgInten{nP}{nC}{nS}(nL) = ...
                 sum(allBkg(nL,minVal:maxInd).*thisInd)./sum(allBkg(nL,minVal:maxInd));
               
               end
               
               %Remove all NaN and replace them with the value of a line
               %closest to it
               isVal = find(~isnan(bkgInten{nP}{nC}{nS}));
               for nL=minL:maxL
                  if(isnan(bkgInten{nP}{nC}{nS}(nL)))
                     [~,ind] = min(abs(isVal-nL));
                     bkgInten{nP}{nC}{nS}(nL) = bkgInten{nP}{nC}{nS}(ind);
                  end
               end
               
               %Find the minimum bkg intensity that's after the maximum
               %intensity in the first half of the gut-Set all of those pixel 
               %intensities to be equal to this minimum.
               %Exclude the last half of the gut in case we get a large
               %false signal from the vent.
               endPt = size(bkgInten{nP}{nC}{nS},2);
               
               [maxVal,maxInd] = max(bkgInten{nP}{nC}{nS}(1:floor(endPt/2)));
               [minVal, minInd] = min(bkgInten{nP}{nC}{nS}(maxInd:endPt));
               minInd = maxInd+minInd-1;
               bkgInten{nP}{nC}{nS}(minInd:endPt) = minVal;
               
               
           end
           
        end
        
    end
    
    
    
    
end


end