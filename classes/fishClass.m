%fishClass: Class to store all analysis information about a particular fish

classdef fishClass
    properties
        saveLoc = '';
        totalNumScans = '';
        totalNumColor = '';
        
        scan = scanClass.empty(1,0);
        
        totPopRegCutoff;
        totPop;
    end
    
    methods
        
        function obj = fishClass(param)
           obj.saveLoc = param.dataSaveDirectory; 
           obj.totalNumScans = param.expData.totalNumberScans;
           obj.totalNumColor = length(param.color);
           
           obj = initScanArr(obj,param);
           
           obj.totPopRegCutoff = 4;
        end
        
        
        function obj = initScanArr(obj,param)
            
            %[sL, cL] = createSCList(param);
            
            obj.scan = scanClass(obj.totalNumScans, obj.totalNumColor);
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.scan(s,c) = scanClass(param, s,c);
                end
                
            end
        end
        
        function obj = getClumps(obj)
           
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.scan(s,c) = obj.scan(s,c).getClumps;
                end
                
            end
        end
        
        
        function obj = getTotPop(obj, varargin)
           switch nargin
               case 1
                   type = 'clump';
               case 2
                   type = varargin{1};
           end
           
           inputVar = load([obj.saveLoc filesep 'param.mat']);
           param = inputVar.param;
           
           switch type
               case 'clump'
                   sAll = zeros(obj.totalNumScans, obj.totalNumColor);
                   
                   for s = 1:obj.totalNumScans
                       for c = 1:obj.totalNumColor
                           
                           if(isempty(obj.scan(s,c).clumps.allData))
                               sAll(s,c) = 0;
                               continue;
                           end
                           totVol = [obj.scan(s,c).clumps.allData.volume];
                           
                           gutInd = [obj.scan(s,c).clumps.allData.gutLoc];
                           
                           gutInd = gutInd<param.gutRegionsInd(s,obj.totPopRegCutoff);
                           
                           totVol = sum(totVol(gutInd));
                           
                           sAll(s,c) = totVol;
                           
                       end
                       
                   end
                   
                   obj.totPop.clump = sAll;
                   
               case 'spot'
                   
               case 'coarse'
           
           end
                   
            
        end
        
    end
    
    
end
    
    