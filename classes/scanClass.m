%Class to store all analysis about a particular scan and color

classdef scanClass
    properties
        scanNum = NaN;
        colorStr = '';
        colorNum = NaN;
        
        
        gutRegionsInd = NaN;
        saveLoc = '';
        clumps = clumpSClass.empty(1,0);
        totVol = NaN;
        totInten = NaN; 
        
        sL;
        sH;
        mL;
        mH;
        nL;
        nH;
        highPopFrac;
        totPop;
        
        gutWidth; 
        centerLine;
        gutOutline;
        %Center of mass position (in sliceNum) plus the region that
        %contains centerMassFound percent of the population (gives an
        %estimate of how 
        centerMass;
        centerMassBound = 0.5;
        
        %One dimensional line distribution for this bacterial population.
        lineDist = [];
        
        removedRegion = [];%Regions to manually remove from these scans (this will likely be regions by the vent).
        
        
    end
    
    methods
        function obj = scanClass(varargin)
            if(nargin>2)
                %obj = obj@fishClass(param);
                param = varargin{1};
                scanNum = varargin{2};
                colorNum = varargin{3};
                obj.scanNum = scanNum;
                obj.colorNum = colorNum;
                obj.colorStr = param.color{colorNum};
                obj.saveLoc = param.dataSaveDirectory;
                
                obj.gutRegionsInd = param.gutRegionsInd(scanNum,:);
            end
        end
        
        function [] = showIm(obj,varargin)
            figure; 
            
            inputVar = load([obj.saveLoc filesep 'param.mat']);
            param = inputVar.param;
            recalcProj = false;
            im = selectProjection(param, 'mip', 'true', obj.scanNum, obj.colorStr, '',recalcProj);
 
            if(nargin==1)
               im = imadjust(im); 
            end
            imshow(im,[]);
            
            if(nargin>1)
                switch varargin{1}
                    case 'contrast'
                        imcontrast;
                end
            end
            
            
            
        end
        
        function im = getIm(obj)
              
            inputVar = load([obj.saveLoc filesep 'param.mat']);
            param = inputVar.param;
            recalcProj = false;
            im = selectProjection(param, 'mip', 'true', obj.scanNum, obj.colorStr, '',recalcProj);
 
        end
        
        function [] = showBkgEst(obj)
            
        end
        
        function obj = getBkgEst(obj)
            
        end
       
        function spots = foundSpots(obj)
            
        end
        
        function spots = removedSpots(obj)
            
        end
        
        function mask = masks(obj)
            
        end
        
        function obj = getOutlines(obj)
            inputVar = load([obj.saveLoc filesep 'param.mat']);
            param = inputVar.param;
        
            obj.centerLine = param.centerLineAll{obj.scanNum};
            obj.gutOutline = param.regionExtent.polyAll{obj.scanNum};
            
        end
        
        function obj = getClumps(obj)
           
            inputVar = load([obj.saveLoc filesep 'param.mat']);
            param = inputVar.param;
            param.dataSaveDirectory = obj.saveLoc;
            temp = clumpSClass(param,obj.scanNum, obj.colorNum, 'get');
            
            %If remove indices are already set, don't set again, but
            %provide warning
            if(isempty(obj.clumps))
                obj.clumps = temp;
            else
                if(~isempty(obj.clumps.remInd) )
                    remInd = obj.clumps.remInd;
                    obj.clumps = temp;
                    obj.clumps.remInd = remInd;
                    fprintf(1, 'Removed indices kept from current version of fishclass.\n');
                else
                    obj.clumps = temp;
                end
                
            end
        end
        
        function obj = calcMask(obj)
            inputVar = load([obj.saveLoc filesep 'param.mat']);
            param = inputVar.param;
            
            if(~exist([obj.saveLoc filesep 'masks']))
                mkdir([obj.saveLoc filesep 'masks'])
            end
            if(exist([obj.saveLoc filesep 'masks' filesep 'mask.mat'])==2)
                inputVar = load([obj.saveLoc filesep 'masks' filesep 'mask.mat']);
                mask = inputVar.mask;
            else
                mask = maskFish;
            end
            %maskFish.getBkgEstMask(param, obj.scanNum, obj.colorNum);
            
            
            segMask = mask.getGraphCutMask(param, obj.scanNum, obj.colorNum);
        
            %Save a binary mask-...this should eventually be removed
            saveLoc = [obj.saveLoc filesep 'bkgEst' filesep 'fin_' num2str(obj.scanNum) '_' obj.colorStr '.mat'];
            
           % save(saveLoc, 'segMask');
            
            %Save the label matrix
            saveLoc = [obj.saveLoc filesep 'masks' filesep 'allRegMask_' num2str(obj.scanNum) '_' obj.colorStr '.mat'];
            segMask = bwlabel(segMask);
            save(saveLoc, 'segMask');        
        end
        
        function obj = createLabelMask(obj)
            %mlj: temporary helper function-can be deleted in the future.
            saveLoc = [obj.saveLoc filesep 'bkgEst' filesep 'fin_' num2str(obj.scanNum) '_' obj.colorStr '.mat'];
            inputVar = load(saveLoc);
            
            segMask= bwlabel(inputVar.segMask);
            saveLoc = [obj.saveLoc filesep 'masks' filesep 'allRegMask_' num2str(obj.scanNum) '_' obj.colorStr '.mat'];
            save(saveLoc, 'segMask');           
        end
        
        function obj = filterMask(obj)
            %Filter down the calculated cluster map produced by .calcMask
            %(graph cut approach)
            
            inputVar = load([obj.saveLoc filesep 'masks' filesep 'mask.mat']);
            mask = inputVar.mask;
            m = mask.filterMask(obj.scanNum, obj.colorStr);
            
            
        end
        
        function obj = calcIndivClumpMask(obj, cut)
%            obj = obj.createLabelMask;
            inputVar = load([obj.saveLoc filesep 'param.mat']);
            param = inputVar.param;
            
            segmentType.Selection = 'clump and indiv';
            param.dataSaveDirectory = obj.saveLoc;
            segMask = segmentGutMIP('', segmentType, obj.scanNum, obj.colorNum, param, obj ,cut);
            fileName = [obj.saveLoc filesep 'masks' filesep 'clumpAndIndiv_nS' num2str(obj.scanNum) '_' obj.colorStr '.mat'];
            save(fileName, 'segMask');
        end
        
        function obj = calcClump(obj)
            inputVar = load([obj.saveLoc filesep 'param.mat']);
            param = inputVar.param;
           
            clump3dSegThreshAll(param, obj.scanNum, obj.colorNum, true);
        end
        
        function obj = calcGutWidth(obj)
            obj.gutWidth = calcGutWidth(obj.centerLine, obj.gutOutline);
        end
        
        function obj = getTotPop(obj, regCutoff, type,cut, singleBacInten)
            
            switch type
                case 'clump'
                 
                    if(isempty(obj.clumps.allData))
                        obj.totVol = 0;
                        obj.totInten = 0;
                        return;
                    end
                    obj.totVol = [obj.clumps.allData.volume];
                    obj.totInten = [obj.clumps.allData.totalInten];
                    
                    %Only consider spots before the gut region cutoff
                    
                    gutInd = [obj.clumps.allData.sliceNum];
                    gutInd = gutInd<obj.gutRegionsInd(regCutoff);
                    obj.totVol = obj.totVol(gutInd);
                    obj.totInten = obj.totInten(gutInd);
                    
                    %Getting clumps above and below our single bacteria
                    %intensity cutoff
                    pL = obj.totInten<cut;
                    pH = obj.totInten>=cut;
                    
                    %Total clump and individual intensity
                    obj.sL = sum(obj.totInten(pL))/singleBacInten;
                    obj.sH = sum(obj.totInten(pH))/singleBacInten;
                    
                    %Total population
                    obj.totPop = obj.sL+obj.sH;
                  
                    %Mean clump and individual intensity
                    obj.mL = mean([obj.totInten(pL)])/singleBacInten;
                    obj.mH = mean([obj.totInten(pH)])/singleBacInten;
                    
                    %Total fraction of population in largest clump
                    highPop = max([obj.totInten]);
                    if(isempty(highPop))
                        highPop = 0;
                    end
                    highPop = highPop/singleBacInten;
                    
                    obj.highPopFrac = highPop'./sum(obj.sL+obj.sH);
                    
                    %Total number of clumps and individuals
                    obj.nL = sum(pL);
                    obj.nH = sum(pH);
                    
                    obj.totVol = sum(obj.totVol);
                    obj.totInten = sum(obj.totInten);
                    
        
            end
            
        end
        
        function obj = calc1DProj(obj, singleBacInten)
            %obj = calc1DProj(obj): Calculate the 1d line distribution for
            %this scan, by combining together the spots and clumps
            %analysis.
            %Make sure to get all the clump data before running and combine
            %together spots and clumps into a single data array
            
            obj.lineDist = zeros(obj.gutRegionsInd(5),1);
            
            ldall =  zeros(obj.gutRegionsInd(end),1);
            
            ldist = zeros(obj.gutRegionsInd(end),1);
            for i=1:length(obj.clumps.allData)
                
                c  = obj.clumps.allData(i).sliceinten;
                if(isempty(c))
                    %If it's empty its because this is actually an individual bacteria
                    loc = obj.clumps.allData(i).sliceNum;
                    
                    if(isnan(loc))
                        continue;
                        %This spot is a mistake
                    end
                    c(1,1) = loc;
                    c(1,2) = singleBacInten;
                    
                end
                c(:,2) = c(:,2)./singleBacInten;
                
                ind = find(c(:,1)==0);
                c(ind,:) = [];
                ind = find(c(:,1)>obj.gutRegionsInd(end));
                c(ind,:) = [];
                
                ldist(c(:,1)) = ldist(c(:,1))+c(:,2);
                
            end
            obj.lineDist = ldist;
            
%             
%             %% Load in all spots for this time point
%             spotClassifier = load([obj.saveLoc filesep 'singleBacCount' filesep 'spotClassifier.mat']);
%             spotClassifier = spotClassifier.spots;
%             
%             spots = spotClassifier.loadFinalSpot(obj.scanNum, obj.colorNum);
%             
%             sliceNum = [spots.sliceNum];
%             %Remove slice numbers not in range that we're using for our 1d
%             %projection (currently to the end of the vent).
%             sliceNum(~ismember(sliceNum, obj.gutRegionsInd(1):obj.gutRegionsInd(5))) = [];
%             
%             %Updating population data
%             for i=1:length(sliceNum)
%                 obj.lineDist(sliceNum(i)) = obj.lineDist(sliceNum(i))+1;
%             end
%             fprintf(1, '.');
%             %% Loading in clump data
%             
%             %Loading in clump mask
%             mask = load([obj.saveLoc filesep 'masks' filesep 'maskUnrotated_' num2str(obj.scanNum) '.mat']);
%            mask = mask.gutMask;
%            
%            cmask = load([obj.saveLoc filesep 'masks' filesep 'allRegMask_' num2str(obj.scanNum) '_' obj.colorStr '.mat']);
%            cmask = cmask.segMask;
%            
%            for i=1:length(obj.clumps.allData)
%                fprintf(1, '.');
%               ind = find(cmask==obj.clumps.allData(i).IND);
%               
%               %Find range for this clump
%               indm = [];
%               for j=1:size(mask,3)
%                   temp = mask(:,:,j);
%                   indm = [indm; unique(temp(ind))];       
%               end
%               
%               indm(indm==0) = [];
%               indm = unique(indm);
%               indm = sort(indm);
%         
%               %Get area in MIP represented for each slice
%               a = size(indm,1);
%               for j=1:size(mask,3)
%                   a = a+ arrayfun(@(x)sum(cmask(mask(:,:,j)==x)), indm);
%               end
%               
%               %Remove areas outside region we're interested in.
%               a(~ismember(indm,  obj.gutRegionsInd(1):obj.gutRegionsInd(5))) = [];
%               indm(~ismember(indm,  obj.gutRegionsInd(1):obj.gutRegionsInd(5))) = [];
%     
%               if(isempty(indm))
%                  %Clump falls outside our range of interest.
%                   continue
%                   
%               end
%               
%               %Assign to lineDist based on intensity
%               totPop = obj.clumps.allData(i).totalInten/singlebacinten;
%               
%             %  obj.lineDist(indm) = obj.lineDist(indm)+ (a/sum(a))*totPop;
%               obj.lineDist(indm) = obj.lineDist(indm) + (a/sum(a))*totPop;
%            end
%            
%            fprintf(1, '\n');
%            
        end
        
        function obj = combClumpIndiv(obj,cut)
            %Combine together clump and spot detected data...need to work a
            %little bit on the overall pipeline here.
            inputVar = load([obj.saveLoc filesep 'singleBacCount' filesep 'bacCount' num2str(obj.scanNum) '.mat']);
            rProp = inputVar.rProp{obj.colorNum};
            
            inputVar = load([obj.saveLoc filesep 'singleBacCount' filesep 'spotClassifier.mat']);
            spots = inputVar.spots;
            
            if(~isempty(rProp))
            rProp = spots.classifyThisSpot(rProp, obj.scanNum, obj.colorNum);
            end
            rProp = spotClass.keptManualSpots(rProp, spots.removeBugInd{obj.scanNum, obj.colorNum});
            
            newClump = rProp;
            
            %Intensity cutoff for individual bacteria
            
            %mlj: temporary
           % newClump([newClump.sliceNum]>=obj.gutRegionsInd(4)) = [];
            
            obj.totPop = length(newClump);
            
            ind = [newClump.totInten]<cut;
            
            %Cheater holder place for single bac intensity.
            obj.totInten = mean([newClump(ind).totInten]);
            
            %            if(~isfield(obj.clumps, 'allData'))
            %
            %                 return
            %             end
            inputVar = load([obj.saveLoc filesep 'param.mat']);
            param = inputVar.param;
            
            if(isempty(obj.clumps.allData))
                maxInd = 0;
                obj.clumps.allData = clumpClass(obj.scanNum, obj.colorNum,param, 0);
            else
                %Remove clumps that we've manually culled
                ind = ismember([obj.clumps.allData.IND],obj.clumps.remInd);
                obj.clumps.allData(ind) = [];
                maxInd = max([obj.clumps.allData.IND]);
            end

            numClumps = length(obj.clumps.allData);
            
            for i=1:length(newClump)
                obj.clumps.allData(numClumps+i) = clumpClass(obj.scanNum, obj.colorNum, param, maxInd+i) ;
                obj.clumps.allData(numClumps+i).totalInten = newClump(i).totInten;
                obj.clumps.allData(numClumps+i).sliceNum = newClump(i).sliceNum;
                obj.clumps.allData(numClumps+i).gutRegion = newClump(i).gutRegion;
                obj.clumps.allData(numClumps+i).centroid = newClump(i).CentroidOrig;
                obj.clumps.allData(numClumps+i).IND = 0; %We'll use this to indicate that this is a spot
            end
            
        end
        
        function obj = updateSliceNum(obj,param)
            obj.gutRegionsInd = param.gutRegionsInd(obj.scanNum,:);
        end
        
    end
    
    
end