%fishClass: Class to store all analysis information about a particular fish

classdef fishClass
    properties
        saveLoc = '';
        totalNumScans = '';
        totalNumColor = '';
        
        scan = scanClass.empty(1,0);
        
        totPopRegCutoff = NaN;
        totPop;
        param = [];
        totPopType = {'clump', 'coarse', 'spot'};
        
        t = NaN;
    end
    
    methods
        
        function obj = fishClass(param)
            
            %Check if the input is a cell array-if it is then load in two
            %entries for number of scans etc.
            if(~iscell(param))
                obj.saveLoc = param.dataSaveDirectory;
                obj.totalNumScans = param.expData.totalNumberScans;
                obj.totalNumColor = length(param.color);
                
                offset = 0;
                obj = initScanArr(obj,param,offset);
                obj.param{1} = param;
                
            end
            
            if(iscell(param))
                %By fiat we'll always save the results of fish analysis to
                %a location in the first take folder.
                obj.saveLoc{1} = param{1}.dataSaveDirectory;
                %Colors in first and second take better have the same
                %number, otherwise we shoulnd't be combining them.
                obj.totalNumColor = length(param{1}.color);
                obj.totalNumScans = 0;
                offset = 0;
                for i=1:length(param)
                    obj.totalNumScans = obj.totalNumScans+param{i}.expData.totalNumberScans;
                    obj = initScanArr(obj,param{i},offset);
                    offset = param{i}.expData.totalNumberScans;
                    obj.param{i} = param{i};
                    
                end
                
            end
            
           obj.totPopRegCutoff = 4;
           
           obj.totPop = struct;
           
           %Assuming, for now, that there is no time delay between takes
           %and that the pause time doesn't change over time (works for
           %now)
           obj.t = (obj.param{1}.expData.pauseTime/60)*(1:obj.totalNumScans);
           
           for i=1:length(obj.totPopType)
               obj.totPop = setfield(obj.totPop, obj.totPopType{i}, NaN);
           end
        end
        
       
        function obj = initScanArr(obj,param,offset)
            
            %See if we've already created the fish class, if so load in the
            %particulars for each scan
            if(exist([param.dataSaveDirectory filesep 'fishAnalysis.mat'], 'file')==2)
               inputVar = load([param.dataSaveDirectory filesep 'fishAnalysis.mat']);
               inF = inputVar.f;
               
               for s = 1:param.expData.totalNumberScans
                    for c = 1:obj.totalNumColor
                        obj.scan(s+offset,c) = inF.scan(s,c);
                    end
                    
                end
               
            else
                
                for s = 1:param.expData.totalNumberScans
                    for c = 1:obj.totalNumColor
                        obj.scan(s+offset,c) = scanClass(param, s,c,offset);
                    end
                    
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
        
        function obj = calcMasks(obj)
           
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.scan(s,c).calcMask();
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
            
            sAll = zeros(obj.totalNumScans, obj.totalNumColor);
            
            for c = 1:obj.totalNumColor
                for s = 1:obj.totalNumScans
                    obj.scan(s,c) = obj.scan(s,c).getTotPop(obj.totPopRegCutoff, type);
                   sAll(s,c) = obj.scan(s,c).totInten;
                end
            end
            
            obj.totPop.(type) = sAll;
            
        end
        
            
        function obj = removeCulledClumps(obj)
            
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.scan(s,c).clumps = obj.scan(s,c).clumps.cullClumps(obj.totPopRegCutoff);
                end
                
            end
        end
       
        
        function obj = calcClumps(obj)
            
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.scan(s,c).calcClump;
                end
                
            end
            
        end
        
        
        function plotTotPop(obj, type, varargin)
            figure;
            cM(1,:) = [0.2 0.8 0.1];
            cM(2,:) = [0.8 0.2 0.1];
           
            if(nargin>2)
                colorNum = varargin{1};
                h = semilogy(obj.t,obj.totPop.(type)(:,colorNum));
                set(h, 'Color', cM(colorNum,:));
                %Set colors appropriately
                
            else
                h = semilogy(obj.t,obj.totPop.(type));
                arrayfun(@(x)set(h(x), 'Color', cM(x,:)), 1:obj.totalNumColor);
                %Set colors appropriately
            end
            title(type);
            xlabel('Time: hours');
            ylabel('Population');
            
        end
        
        
    end
    
    
end
    
    