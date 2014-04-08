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
            
            segMask = maskClass.getGraphCutMask(param, obj.scanNum, obj.colorNum);
            
            saveLoc = [obj.saveLoc filesep 'bkgEst' filesep 'fin_' num2str(obj.scanNum) '_' param.color{obj.colorNum} '.mat'];
            save(saveLoc, 'segMask');
            
        end
        
        function obj = calcClump(obj)
            inputVar = load([obj.saveLoc filesep 'param.mat']);
            param = inputVar.param;
           
            clump3dSegThreshAll(param, obj.scanNum, obj.colorNum, true);
        end
        
        function obj = getTotPop(obj, regCutoff, type)
            
            switch type
                case 'clump'
                    if(isempty(obj.clumps.allData))
                        obj.totVol = 0;
                        obj.totInten = 0;
                        return;
                    end
                    obj.totVol = [obj.clumps.allData.volume];
                    obj.totInten = [obj.clumps.allData.totalInten];
                    
                    gutInd = [obj.clumps.allData.sliceNum];
                    
                    gutInd = gutInd<obj.gutRegionsInd(regCutoff);
                    
                    obj.totVol = sum(obj.totVol(gutInd));
                    obj.totInten = sum(obj.totInten(gutInd));
                    
                    
            end
            end
        
        
        
    end
    
    
end