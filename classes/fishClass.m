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
        
        sL = [];
        sH = [];
        
        mL = [];
        mH = [];
        
        nL = [];
        nH = [];
        
        cut = [];
        t = NaN;
        
        singleBacInten = [];
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
        
        function plotTotPop(obj, varargin)
            figure;
            cM(1,:) = [0.2 0.8 0.1];
            cM(2,:) = [0.8 0.2 0.1];
           if(nargin==1)
               type = 'tot';
           else
              type = varargin{1}; 
           end
           
           
           if(nargin>2)
              cList = varargin{2}; 
           else
               cList = 1:obj.totalNumColor;
           end
           
           
           %Find which type of plot to make
           switch type
               case 'tot'
                   %Confusing syntax-load in the total population data as
                   %measured by the
                   type = 'clump';
                   pop = obj.totPop.(type);
                   pop = pop./(repmat(obj.singleBacInten,size(pop,1),1));
                   
               case 'clump'
                   pop = obj.sH;
                   
               case 'indiv'
                   pop = obj.sL;
                   
               case 'all'
                   pop = [obj.sL(:,cList)+obj.sH(:,cList), obj.sL(:,cList), obj.sH(:,cList)];
                   h = semilogy(obj.t,pop);
                   set(h(1), 'Color', [0 0 0]);
                   set(h(2), 'Color', [0.8 0.2 0.2]);
                   set(h(3), 'Color', [0.4 0.8 0.2]);
                   
                   arrayfun(@(x)set(h(x), 'LineWidth', 2), 1:length(h));
                   legend('Total population', 'individuals', 'clumps', 'Location', 'Northwest');
                   
                   title(['Total population, color: ', num2str(cList)]);
                   xlabel('Time: hours');
                   ylabel('Population');
                   return
           end
           %Only get the colors that we want.
           pop = pop(:,cList);
           
           %Plotting the graph
           h = semilogy(obj.t,pop);
           
           %Setting colors
           if(length(cList)==1)
               set(h, 'Color', cM(cList,:));
           else
               arrayfun(@(x)set(h(x), 'Color', cM(cList(x),:)), cList);
           end
           
           %Tweaking figures
           set(h, 'LineWidth', 2);
           
           title(type);
           xlabel('Time: hours');
           ylabel('Population');
           
        end
        
        
        function plotTotNumClumps(obj)
            figure; 
            
            if(nargin==1)
                cList = 1:obj.totalNumColor;
            else
                cList = varargin{1};
            end
            
            
            h =  plot(obj.t, obj.nH(:,cList));
            cM(1,:) = [0.2 0.8 0.1];
            cM(2,:) = [0.8 0.2 0.1];
            
            set(gca, 'YScale', 'log');
            
            %Setting colors
           if(length(cList)==1)
               set(h, 'Color', cM(cList,:));
           else
               arrayfun(@(x)set(h(x), 'Color', cM(cList(x),:)), cList);
           end
           
           %Tweaking figures
           set(h, 'LineWidth', 2);
           title('Total number of clumps');
            ylabel('# of clumps');
            xlabel('Time (hours)');
        end
        
        function plotMeanClumpSize(obj)
            figure;
            
            if(nargin==1)
                cList = 1:obj.totalNumColor;
            else
                cList = varargin{1};
            end
            
            
            h =  plot(obj.t, obj.mH(:,cList));
            cM(1,:) = [0.2 0.8 0.1];
            cM(2,:) = [0.8 0.2 0.1];
            
            set(gca, 'YScale', 'log');
            
            %Setting colors
            if(length(cList)==1)
                set(h, 'Color', cM(cList,:));
            else
                arrayfun(@(x)set(h(x), 'Color', cM(cList(x),:)), cList);
            end
            
            %Tweaking figures
            set(h, 'LineWidth', 2);
            title('Mean Clump size');
            ylabel('Clump size (# of bacteria)');
            xlabel('Time (hours)');
            
        end
        
        %Functions for dealing with clumps of objects
        
        function obj = getClumpData(obj)
            if(length(obj.cut)~=obj.totalNumColor)
                fprintf(2, 'Need to set object intensity cutoff first!\n');
                return
            end
            
            for nC=1:obj.totalNumColor
                pL = arrayfun(@(x)[obj.scan(x,nC).clumps.allData.totalInten]<obj.cut(nC), 1:obj.totalNumScans, 'UniformOutput', false);
                pH = arrayfun(@(x)[obj.scan(x,nC).clumps.allData.totalInten]>=obj.cut(nC), 1:obj.totalNumScans, 'UniformOutput', false);
                
                temp = arrayfun(@(x)[obj.scan(x,nC).clumps.allData(pL{x}).totalInten], 1:obj.totalNumScans,...
                    'UniformOutput', false);
                obj.singleBacInten(nC) = mean(cell2mat(temp));
                
                %Total clump and individual intensity
                obj.sL(:,nC) = arrayfun(@(x) sum([obj.scan(x,nC).clumps.allData(pL{x}).totalInten]), 1:obj.totalNumScans);
                obj.sH(:,nC) = arrayfun(@(x) sum([obj.scan(x,nC).clumps.allData(pH{x}).totalInten]), 1:obj.totalNumScans);
               
                obj.sL(:,nC) = obj.sL(:,nC)/obj.singleBacInten(nC);
                obj.sH(:,nC) = obj.sH(:,nC)/obj.singleBacInten(nC);
                
                %Mean clump and individual intensity
                obj.mL(:,nC) = arrayfun(@(x) mean([obj.scan(x,nC).clumps.allData(pL{x}).totalInten]), 1:obj.totalNumScans);
                obj.mH(:,nC) = arrayfun(@(x) mean([obj.scan(x,nC).clumps.allData(pH{x}).totalInten]), 1:obj.totalNumScans);
                
                obj.mL(:,nC) = obj.mL(:,nC)/obj.singleBacInten(nC);
                obj.mH(:,nC) = obj.mH(:,nC)/obj.singleBacInten(nC);
                
                
                
                %Total number of clumps and individuals
                obj.nL(:,nC) = cellfun(@(x) sum(x), pL);
                obj.nH(:,nC) = cellfun(@(x) sum(x), pH);
                
                
            end
            
        end
        
        function plotClumpFrac(obj)
            figure;
            cM(1,:) = [0.2 0.8 0.1];
            cM(2,:) = [0.8 0.2 0.1];
            
            hold on;
            
            h = semilogy(obj.sL, obj.sH);
            
            set(h, 'LineWidth', 3)
            arrayfun(@(x)set(h(x), 'Color', cM(x,:)), 1:obj.totalNumColor);
            set(gca, 'YScale', 'log');
            set(gca, 'XScale', 'log');
            axis square;
            title('Fraction of population in clumps vs. Individuals');
            xlabel('Population size of individuals');
            ylabel('Population size in clumps');
            
        end
        
    end
    
    
end
    
    