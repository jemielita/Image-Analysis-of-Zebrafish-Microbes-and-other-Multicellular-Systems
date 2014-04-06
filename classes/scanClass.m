%Class to store all analysis about a particular scan and color

classdef scanClass
    properties
        scanNum = NaN;
        colorStr = '';
        colorNum = NaN;
        
        bkgEst = [];
        saveLoc = '';
        clumps = clumpSClass.empty(1,0);
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
        
        
        
        
        
    end
    
    
end