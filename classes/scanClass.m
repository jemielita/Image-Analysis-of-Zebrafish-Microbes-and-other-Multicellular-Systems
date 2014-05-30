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
        
        %Center of mass position (in sliceNum) plus the region that
        %contains centerMassFound percent of the population (gives an
        %estimate of how 
        centerMass;
        centerMassBound = 0.5;
        
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
        
        function obj = getClumps(obj)
            inputVar = load([obj.saveLoc filesep 'param.mat']);
            param = inputVar.param;
            temp = clumpSClass(param,obj.scanNum, obj.colorNum, 'get');
            
            obj.clumps = temp;
        end
        
        function obj = calcMask(obj)
            inputVar = load([obj.saveLoc filesep 'param.mat']);
            param = inputVar.param;
            
            maskClass.getBkgEstMask(param, obj.scanNum, obj.colorNum);
            
            segMask = maskClass.getGraphCutMask(param, obj.scanNum, obj.colorNum);
        
            %Save a binary mask-...this should eventually be removed
            saveLoc = [obj.saveLoc filesep 'bkgEst' filesep 'fin_' num2str(obj.scanNum) '_' obj.colorStr '.mat'];
            
            save(saveLoc, 'segMask');
            
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
        
        
        
        function obj = calcIndivClumpMask(obj, cut)
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
        
        
        
    end
    
    
end