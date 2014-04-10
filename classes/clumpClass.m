classdef clumpClass < clumpSClass
   properties
       totalInten = NaN;
       volume = NaN;
       intenCutoff = NaN;
       zRange = [NaN NaN];
       sliceNum = NaN;
       gutRegion = NaN;
       cropRect = [NaN NaN NaN NaN];
       removeObj = false;
       
       IND = NaN;%should be private
       
       surfaceArea = NaN;
       
   end
   
   methods
       
       function obj = clumpClass(scanNum, colorNum, param,ind)
           obj = obj@clumpSClass(param, scanNum, colorNum);          
           obj.IND = ind;
       end
      
       function obj = save(obj)
           
           sl = [obj.saveLoc filesep obj.saveStr filesep 'clump_' obj.colorStr '_nS' num2str(obj.scanNum) ];
           if(~isdir(sl))
               mkdir(sl);
           end
           c = obj;
           save([sl filesep num2str(c.IND) '.mat'], 'c');
       end
       
       
       function obj = calcSurfaceArea(obj)
            
       end
           
           
       
%        function display(obj)
%           %Display the MIP of this particular bug
%           %figure; 
%           
%        end
      %Save class to file
      
   end
end % classdef