%clumpAllClass: Stores all the information about clumps relevant to all
%clumps for a particular fish.
%

classdef clumpAllClass < fishClass
    
    properties
        clump
        
    end
    
    
    methods
        
        function obj = clumpAllClass(param)
            obj = obj@fishClass(param);
           
        end
                  
        function obj = getScanClumps(obj)
            inputVar = load([obj.saveLoc filesep 'param.mat']);
            param = inputVar.param;
           % obj.clump = clumpSClass(obj.totalNumScans, obj.totalNumColor);
           obj.clump = clumpSClass.empty(100,2,0);
            for i=1:obj.totalNumScans
                for j=1:obj.totalNumColor
                    obj.clump(i,j) = clumpSClass(param,i,j);
                    %obj.clump(i,j).get;
                end
            end
            
            end
      
        
        
    end
    
    
end
    
    