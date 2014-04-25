%graphicsHandle: Contains all the relevant information about different
%user added graphics to multipleRegionCrop.m


classdef graphicsHandle

 properties
     numScan = NaN;
     numColor = NaN;
     saveLoc = '';
     imHandle = [];
     g = [];
     
   end
   
   methods
       
       function obj = graphicsHandle(param,numScan, numColor,imHandle)
          obj.numScan = numScan;
          obj.numColor = numColor;
          obj.saveLoc = param.dataSaveDirectory;
          obj.imHandle = imHandle;
          
          obj.g = struct();
          
       end
       
       function obj = newHandleList(obj, fieldName, gType, newVal,outputLoc)
           
           len = length(obj.g);
           if(len==1)
               i = len;
           else
               i = len+1;
           end
           
           obj.g(i).name = fieldName;
           obj.g(i).type = gType;
           
           %Indicates whether we will force the code to have new values for
           %every scan and color
           obj.g(i).newVal = newVal;
           
           obj.g(i).val = cell(obj.numScan, obj.numColor);
           %Setting all entries to cell arrays
           for j=1:obj.numScan
               for k=1:obj.numColor
                   obj.g(i).val{i,j} = cell(1,1);
               end
           end
           
           obj.g(i).type = gType;
           
           obj.g(i).handle = cell(obj.numScan, obj.numColor);
           obj.g(i).visible = 'on';
           
           %Where to save the manipulations we're doing.
           obj.g(i).outputLoc = outputLoc;
       end
       
       function obj = newObject(obj, fieldname, scanNum, colorNum, outputLoc)
           fl = {obj.g.name};
           ind = cellfun(@(x)strcmp(x, fieldname)==1,fl);
           
           switch obj.g(ind).type
               case 'point'
                   h =impoint(obj.imHandle);
                   
           end
           
           obj.g(ind).handle{scanNum,colorNum} = ...
               [obj.g(ind).handle{scanNum, colorNum}, h];
           
       end
                       
       
       function obj = saveG(obj, scanNumPrev, colorNum)
           
           for i=1:length(obj.g)
               %For every specific type of graphics that we're updating and every
               %handle update the saved data
               if(~isfield(obj.g(i), 'visible'))
                   continue
               end
               
               if(strcmp(obj.g(i).visible, 'on'))
                   obj(i).g = obj.saveThisG(obj(i).g, scanNumPrev, colorNum);
               end
               
           end
       end
       
       function gH = newThisG(obj,gH, scanNum, scanNumPrev,colorNum)
           
           v = gH.val{scanNum, colorNum};
           
           for i=1:length(v)
               if(isempty(v{i}))
                   if(gH.newVal == false)
                       
                   end
                   
               else
                   
                   h = gH.handle{scanNum, colorNum}(i);
                   hApi = iptgetapi(h);
                   hApi.setPosition(v{i});
                   set(h, 'Visible', 'on');
               end
               
           end
           
       end
       
       function obj = newG(obj, scanNum, scanNumPrev, colorNum)
          for i=1:length(obj)
              if(~isfield(obj.g(i), 'visible'))
                   continue
              end
               
              
              if(strcmp(obj.g(i).visible, 'on'))
                   obj(i).g = obj.newThisG( obj(i).g, scanNum, scanNumPrev,colorNum);
               end
              
          end
       end
       
       
       function gH = saveThisG(~,gH, scanNumPrev, colorNum)
           
               v = arrayfun(@(x)iptgetapi(x), gH.handle{scanNumPrev,colorNum},'UniformOutput', false);
               
               for i=1:length(v)
                   vApi =iptgetapi(v{i});
               
                   gH.val{scanNumPrev, colorNum}{i} = vApi.getPosition();
                   
                   switch gH.newVal
                       case 1
                           set(v{i}, 'Visible', 'off');
                           
                       case 0
                           set(v{i}, 'Visible', 'on');
                   end
               end
              
           
       end
       
       
       function [f, param] = updateField(obj, f, param, scanNum, colorNum)
           
           %Assign the values of the user made graphics objects to the
           %appropriate field in fishClass or param.
           
           
           for i=1:length(obj.g)
               
               if(~isfield(obj.g(i), 'visible'))
                   continue
               end
               
              switch obj.g(i).name
                  case 'clumpRemove'
                      disp('Updating stuff to remove');
                      pos = obj.g(i).val{scanNum, colorNum};
                      if(isempty(pos))
                          break
                          
                      elseif(isempty(pos{1}))
                          break;
                      else
                          f.scan(scanNum, colorNum).clumps.remInd = ...
                              [f.scan(scanNum, colorNum).clumps.remInd...
                              f.scan(scanNum, colorNum).clumps.findRemovedClump(pos)];
                          
                          f.scan(scanNum, colorNum).clumps.remInd = ...
                              unique([f.scan(scanNum, colorNum).clumps.remInd]);
                      end                      
                      
              end
               
           end
           
           
       end
       
       
       
   end
end % classdef