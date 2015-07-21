%fishClass: Class to store all analysis information about a particular fish

classdef fishClass
    
    
    properties
        saveLoc = '';
        saveName = 'fishAnalysis';
        
        totPop = [];
        
        sL = [];
        sH = [];
        
        mL = [];
        mH = [];
        
        nL = [];
        nH = [];
        grwth = [];
        
        %For our analysis of clump and individuals distributions
        clumpCentroid = cell(2,1);
        indivCentroid = cell(2,1);
        clumpRegionList = cell(2,1);
        indivRegionList = cell(2,1);
        
        %For calculating instantaneous growth rates
        growthRateWindow = [];
        wSize = 2;
        
        highPopFrac = [];
        
        totalNumScans = '';
        totalNumColor = '';
        
        scan = scanClass.empty(1,0);
        
        totPopRegCutoff = NaN;
        param = [];
        totPopType = {'clump', 'coarse', 'spot'};
        
        colorOverlap = [];
        
        
        gutWidth = [];
        cut = [];
        t = NaN;
        
        singleBacInten = [];
        
        fitParam = [];
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
                obj = initScanArr(obj,param,offset,true);
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
                    obj = initScanArr(obj,param{i},offset, false);
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
       
        function obj = initScanArr(obj,param,offset, reset)
            if(isempty(reset))
               reset = false; 
            end
            %See if we've already created the fish class, if so load in the
            %particulars for each scan
            if(exist([param.dataSaveDirectory filesep 'fishAnalysis.mat'], 'file')==2 &&reset ==false)
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
        
        function obj = calc(obj, field)
        %obj = calc(obj, field)
        %High level functions for running calculations on particular scans.
        %This function will only update field in obj.scan for the
        %appropriate field
            for s = 1:obj.totalNumScans
                fprintf(1, ['Scan: ' num2str(s)]);
                for c = 1:obj.totalNumColor
                    obj.scan(s,c) = obj.scan(s,c).(field);
                end
                
                obj.save()
            end
        
        end
       
        function obj = calcMasks(obj)
            
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.scan(s,c).calcMask();
                end
                
            end
        end
        
        function obj = filterMasks(obj)
            %Filter down result from calcMask.
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.scan(s,c).filterMask();
                    fprintf(1, '.');
                end
                
            end
            fprintf(1, '\n');
        end
        
        function obj = calcClumpCentroid(obj)
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.scan(s,c).clumps.calculateCentroid;
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
        
        
        function obj = calcGrowthRateWindow(obj)
            typeList = {'clump', 'indiv'};
            
            obj.growthRateWindow = arrayfun(@(x)growthRateFun(obj,x), 1:obj.totalNumColor);
            
            function growthRate =  growthRateFun(obj, cN)
                
                for nT = 1:length(typeList)
                    type = typeList{nT};
                    growthRate.(type) = nan(obj.totalNumScans,1);
                    for nS=1+obj.wSize:obj.totalNumScans-obj.wSize
                        x = obj.t;
                        
                        switch type
                            case 'clump'
                                y = obj.sH(:,cN);
                            case 'indiv'
                                y = obj.sL(:,cN);
                        end
                        y = log(y);
                        y = y(nS-obj.wSize:nS+obj.wSize);
                        x = x(nS-obj.wSize:nS+obj.wSize);
                        
                        
                        [growthRate.(type)(nS), ~,~,~] = fityeqbx(x', y);
                        
                        if(growthRate.(type)(nS)==-Inf)
                            growthRate.(type)(nS) = NaN;
                        end
                    end                
                end
            end
            
        end

        function updateClumpSliceNum(obj, param)
           %Update the clump slice number for each found clump
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.scan(s,c).clumps.updateAllSliceNum(param);
                end
                
            end 
        end
        
        function obj = calcColorOverlap(obj)
            obj.colorOverlap = calcMIPOverlap(obj);
        end
        
        function obj = calcIndivClumpMask(obj)
            fprintf(1, 'Calculating indiv/clump masks');
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.scan(s,c).calcIndivClumpMask(obj.cut(c));
                    fprintf(1, '.');
                end
                
            end
            fprintf(1, '\n');
            
           
        end
        
        function obj = calcSliceInten(obj)
            fprintf(1, 'Calculating along each cluster');
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.scan(s,c).clumps.getAllSliceInten;
                    fprintf(1, '.');
                end
                
            end
            fprintf(1, '\n');
            
        end
        
        function obj = calc1dProj(obj)
           fprintf(1, 'Calculating 1d projections');
           for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.scan(s,c) = obj.scan(s,c).calc1DProj(obj.singleBacInten(c));
                    fprintf(1, '.');
                end
                
            end
            fprintf(1, '\n');
             
        end
        function obj = getOutlines(obj)
            fprintf(1, 'Calculating indiv/clump masks');
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.scan(s,c) = obj.scan(s,c).getOutlines;
                    fprintf(1, '.');
                end
                
            end
            fprintf(1, '\n');
        end
        
        function obj.calcGutWidth(obj)
            fprintf(1, 'Calculating gutwidth');
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.gutWidth{s,c} = obj.scan(s,c).calcGutWidth(obj.cut(c));
                    fprintf(1, '.');
                end
                
            end
            fprintf(1, '\n');
        end
        
        function obj = calcCenterMass(obj)
            
            fprintf(1, 'Calculating object center of mass');
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    maxRegNum = obj.scan(s,c).gutRegionsInd(obj.totPopRegCutoff);
                    obj.scan(s,c).clumps = obj.scan(s,c).clumps.calcCenterMass(obj.cut, maxRegNum);
                    fprintf(1, '.');
                end
                
            end
            fprintf(1, '\n'); 
        end
        
        function obj = calcGutWidth(obj)
            
            fprintf(1, 'Calculating approximate gut width');
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.scan(s,c)  = obj.scan(s,c).calcGutWidth;
                    fprintf(1, '.');
                end
                
            end
            fprintf(1, '\n'); 
        end
        
        function obj = calcRegionalGrowth(obj)
           %Calculate regions in the gut that have high growth rates
           
           bugpos = cell(obj.totalNumScans,1);
           for ns= 1:obj.totalNumScans
               for nc =1:obj.totalNumColor
                   
               clmp = obj.scan(ns,nc).clumps.allData;
               
               
               bugpos{ns,nc} = zeros(...
                   obj.scan(ns,nc).gutRegionsInd(obj.totPopRegCutoff),1);
               for i=1:length(clmp)
                  val = clmp(i).sliceinten;
                  
                  %Remove zero elements, and element beyond range
                  ind = find(val(:,1)==0);
                  val(ind,:) = [];
                  ind = find(val(:,1)>obj.scan(ns,nc).gutRegionsInd(obj.totPopRegCutoff));
                  val(ind,:) = [];
                  
                  bugpos{ns,nc}(val(:,1)) = val(:,2)+bugpos{ns,nc}(val(:,1));
               end
               %Reshape this array so that everything is on a grid of the
               %same length (200)
               valnew = interp1(bugpos{ns,nc}, 1:length(bugpos{ns,nc})/200:length(bugpos{ns,nc}));
               bugpos{ns,nc} = valnew;
               
               end
           end
           
           %mlj Note: this code will have to be changed once I look at two
           %color data
           poporig = cell2mat(bugpos);
           
           %Temp, to avoid bug in code that has been fixed.
           %poporig = poporig(:,1:100);
           %Average over these windows in time and space to calculate the
           %region specific growth rate
           wdw.pos = 10; 
           wdw.t = 3; 
           
           %Averaging in space
           for i=1:size(poporig,2)/wdw.pos - 1
              pop(:,i) =  mean(poporig(:,(i-1)*wdw.pos+1:(i-1)*wdw.pos + wdw.pos),2);
           end
           
           %Calculating the growth rate-fixing in place the growth rate
           %window shown above
           for i=2:size(pop,1)-1
               
               for j=1:size(pop,2)
                   
                   [~,~,obj.grwth(i-1,j), ~]= fitline(0.33:0.33:1, pop(i-1:i+1,j));
               
               end
           end
           
            
        end
        
        
        function spotOverlapList = calcClumpSpotOverlap(obj)
            %Find all spots that are overlapping with found clusters. Save
            %this list of spots to singleBacCount/spotClumpOverlap.mat
            fprintf(1, 'Calculating spots overlapping with clumps\n');
            spotOverlapList = cell(obj.totalNumScans, obj.totalNumColor);
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    inputVar = load([obj.saveLoc filesep 'singleBacCount' filesep 'bacCount' num2str(s) '.mat']);
                    spot = inputVar.rProp{c};
                    ind = obj.scan(s,c).clumps.calcSpotClumpOverlap(spot);
                    spotOverlapList{s,c} = [spot(ind).ind];
                    fprintf(1, '.');
                end
                
            end
            fprintf(1, '\n');
            save( [obj.saveLoc filesep 'singleBacCount' filesep 'spotClumpOverlap.mat'],'spotOverlapList');
            
        end
        
        function obj = getClumps(obj)
           %Load in clump data into this instance.
           fprintf(1, 'Loading in clump data');
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.scan(s,c) = obj.scan(s,c).getClumps;
                    fprintf(1, '.');
                end
                
            end
            fprintf(1, 'done!\n');
        end
        
        function obj = combClumpIndiv(obj)
            
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    
                    obj.scan(s,c) = obj.scan(s,c).combClumpIndiv(obj.cut(c));
                    
                    fprintf(1, '.');
                end
                
                
            end
            fprintf(1, '\n');
        end
        
        function obj = getTotPop(obj, varargin)
            switch nargin
                case 1
                    type = 'clump';
                case 2
                    type = varargin{1};
            end
            
            sAll = zeros(obj.totalNumScans, obj.totalNumColor);
            
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.scan(s,c) = ...
                        obj.scan(s,c).getTotPop(obj.totPopRegCutoff, type, obj.cut(c), obj.singleBacInten(c));
                    sAll(s,c) = obj.scan(s,c).totInten;
                    
                    %Set all the appropriate fields in the total fish data
                    popField = {'sL', 'sH', 'mL', 'mH', 'nL', 'nH', 'highPopFrac'};
                    for i=1:length(popField)
                        if(isempty(obj.scan(s,c).(popField{i})))
                            obj.scan(s,c).(popField{i}) = 0;
                        end
                        obj.(popField{i})(s,c) = obj.scan(s,c).(popField{i});
                    end
                    
                    %Normalizing by individual bacterial intensity
                    sAll(s,c) = sAll(s,c)/obj.singleBacInten(c);
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
       
        function obj = getLogisticFit(obj)
            
        end
        
        function obj = getClumpData(obj)
            if(length(obj.cut)~=obj.totalNumColor)
                fprintf(2, 'Need to set object intensity cutoff first!\n');
                return
            end
            
            for nC=1:obj.totalNumColor
                hasClumps = arrayfun(@(x)~isempty([obj.scan(x,nC).clumps.allData]), 1:obj.totalNumScans);
              
                sList = 1:obj.totalNumScans; sList = sList(hasClumps);
                
                pL = arrayfun(@(x)[obj.scan(x,nC).clumps.allData.totalInten]<obj.cut(nC), sList, ...
                    'UniformOutput', false);
                pH = arrayfun(@(x)[obj.scan(x,nC).clumps.allData.totalInten]>=obj.cut(nC), sList,...
                    'UniformOutput', false);
                
                temp = arrayfun(@(x)[obj.scan(sList(x),nC).clumps.allData(pL{x}).totalInten], 1:length(sList),...
                    'UniformOutput', false);
                obj.singleBacInten(nC) = mean(cell2mat(temp));
                
                %Total clump and individual intensity
                obj.sL(sList,nC) = arrayfun(@(x) sum([obj.scan(sList(x),nC).clumps.allData(pL{x}).totalInten]), 1:length(sList));
                obj.sH(sList,nC) = arrayfun(@(x) sum([obj.scan(sList(x),nC).clumps.allData(pH{x}).totalInten]), 1:length(sList));
               
                obj.sL(sList,nC) = obj.sL(sList,nC)/obj.singleBacInten(nC);
                obj.sH(sList,nC) = obj.sH(sList,nC)/obj.singleBacInten(nC);
                
                %Mean clump and individual intensity
                obj.mL(sList,nC) = arrayfun(@(x) mean([obj.scan(sList(x),nC).clumps.allData(pL{x}).totalInten]), 1:length(sList));
                obj.mH(sList,nC) = arrayfun(@(x) mean([obj.scan(sList(x),nC).clumps.allData(pH{x}).totalInten]), 1:length(sList));
                
                obj.mL(sList,nC) = obj.mL(sList,nC)/obj.singleBacInten(nC);
                obj.mH(sList,nC) = obj.mH(sList,nC)/obj.singleBacInten(nC);
                
                %Total fraction of population in largest clump
                highPop = arrayfun(@(x)max([obj.scan(sList(x),nC).clumps.allData.totalInten]), 1:length(sList));
               
                highPop = highPop/obj.singleBacInten(nC);
                
                obj.highPopFrac(sList,nC) = highPop'./(obj.sL(sList,nC)+obj.sH(sList,nC));
                
                %Total number of clumps and individuals
                obj.nL(sList,nC) = cellfun(@(x) sum(x), pL);
                obj.nH(sList,nC) = cellfun(@(x) sum(x), pH);
                
                
            end
           
            
            
        end
        
        % Plotting functions for fish data
        
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
                   %measured by whether they are in clusters or individuals
                   type = 'clump';
                   pop = obj.totPop.(type);
                   
               case 'totAll'
                   %Plot the total population in either color channel
                   
                   for cList=1:obj.totalNumColor
                       pop = [obj.sL(:,cList)+obj.sH(:,cList), obj.sL(:,cList), obj.sH(:,cList)];
                   end
                   h = semilogy(obj.t,pop);
                   set(h(1), 'Color', [0 0 0]);
                   set(h(2), 'Color', [0.8 0.2 0.2]);
                   set(h(3), 'Color', [0.4 0.8 0.2]);
                   
                   arrayfun(@(x)set(h(x), 'LineWidth', 2), 1:length(h));
                   legend('Total population', 'individuals', 'clumps', 'Location', 'Northwest');
                   
                   l(1) = title(['Total population, color: ', num2str(cList)]);
                   l(2) = xlabel('Time: hours');
                   l(3) = ylabel('Population');
                   l(4) = gca;
                   arrayfun(@(x)set(x, 'FontSize', 24), l);
            
                   return
                   
                   
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
                   
                   l(1) = title(['Total population, color: ', num2str(cList)]);
                   l(2) = xlabel('Time: hours');
                   l(3) = ylabel('Population');
                   l(4) = gca;
                   arrayfun(@(x)set(x, 'FontSize', 24), l);
            
                   return
                   
               case 'loglog'
                   loadType = 'clump';
                   pop = obj.totPop.(loadType);
           end
           
           %Only get the colors that we want.
           pop = pop(:,cList);
           
           %Plotting the graph
           switch type
               case 'loglog'
                   h = loglog(obj.t, pop);
                   grid on;
               otherwise
                   h = semilogy(obj.t,pop);
           end
           %Setting colors
           if(length(cList)==1)
               set(h, 'Color', cM(cList,:));
           else
               arrayfun(@(x)set(h(x), 'Color', cM(cList(x),:)), cList);
           end
           set(gca, 'XLim', [min(obj.t), max(obj.t)]);
           
           %Tweaking figures
           set(h, 'LineWidth', 2);
           
           title(type);
           xlabel('Time: hours');
           ylabel('Population');
           
           print('-dpng', [obj.saveLoc filesep 'TotalPopulation.png']);

       
           
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
        
        function plotClumpFrac(obj, varargin)
            
            switch nargin
                case 1
                    single = obj.sL;
                    clump = obj.sH;
                    
                case 2
                    normalize = varargin{1};
                    if(strcmp(normalize, 'normalize'))
                        if(~isfield(obj.fitParam, 'K'))
                           fprintf(2, 'Need to fit logistic growth curve before normalizing!\n');
                           beep;
                           return
                        end
                        single = obj.sL./repmat(sum(obj.fitParam.K), length(obj.sL),2);
                        clump = obj.sH./repmat(sum(obj.fitParam.K),length(obj.sH),2);
                    else
                        single = obj.sL;
                        clump = obj.sH;
                    end
            end
            
            
            figure;
            cM(1,:) = [0.2 0.8 0.1];
            cM(2,:) = [0.8 0.2 0.1];
            
            hold on;
            
            h = semilogy(single, clump);
            
            set(h, 'LineWidth', 3)
            arrayfun(@(x)set(h(x), 'Color', cM(x,:)), 1:obj.totalNumColor);
            set(gca, 'YScale', 'log');
            set(gca, 'XScale', 'log');
            axis square;
            title('Fraction of population in clumps vs. Individuals');
            xlabel('Population size of individuals');
            ylabel('Population size in clumps');
            
        end
        
        function plotLargestClumpSize(obj)
            %Plot the fraction of the population in the largest clump

            figure;
            plot(obj.t, obj.highPopFrac);
            title('Fraction of population in largest clump')
            xlabel('Time (hours)');
            ylabel('Fraction of population');
            
        end
        
        function [im, cen] = getPopulationHeatMap(obj, colorNum, segType)
            imSize = 100;
            im = zeros(obj.totalNumScans,imSize);
            
            cen = zeros(obj.totalNumScans,3);
            for nS=1:obj.totalNumScans
                
                cen(nS,3) = nS;
                switch segType
                    case 'clump'
                        regList = obj.scan(nS, colorNum).clumps.clumpRegionList;
                        cen(nS,1) = obj.scan(nS,colorNum).clumps.clumpCentroid(2,1);
                        cen(nS,2) = obj.scan(nS,colorNum).clumps.clumpCentroid(2,2);
                        
                    case 'indiv'
                        regList = obj.scan(nS, colorNum).clumps.indivRegionList;
                        cen(nS,1) = obj.scan(nS,colorNum).clumps.indivCentroid(2,1);
                        cen(nS,2) = obj.scan(nS,colorNum).clumps.indivCentroid(2,2);
                        
                end
                if(isnan(regList))
                    continue
                end
                %Normalizing the region list
                regList(1,:) = regList(1,:)/obj.scan(nS,colorNum).gutRegionsInd(obj.totPopRegCutoff);
                regList(1,:) = round(imSize*regList(1,:));
                ind = regList(1,:)<=imSize;
                regList = regList(:,ind);
                
                
                cen(nS,1) = cen(nS,1)/obj.scan(nS,colorNum).gutRegionsInd(obj.totPopRegCutoff);
                cen(nS,1) = imSize*cen(nS,1);
                
                cen(nS,2) = cen(nS,2)/obj.scan(nS,colorNum).gutRegionsInd(obj.totPopRegCutoff);
                cen(nS,2) = imSize*cen(nS,2);
                %Normalizing the population
                regList(2,:) = regList(2,:)/obj.singleBacInten(colorNum);
                %Forcing all boxes to have at least 1 bacteria-somewhat
                %artifical, but useful for visualization purposes
                t = log(regList(2,:));
                t(t<0) = 0;
                im(nS,regList(1,:)) = t;
                
            end
        end

        function plotPopulationHeatMap(obj, colorNum, segType)
            
           [im, cen] = obj.getPopulationHeatMap(colorNum, segType);
           im = mat2gray(im);
           figure; imshow(im); hold on
           colormap('hot'); 
           
           hP = plot(cen(:,1),cen(:,3));
           set(hP, 'LineWidth', 3);
           set(hP, 'Color', [0.2 0.3 0.9]);
           set(gcf, 'Position', [708 573 612 360]);
           set(gca, 'Position', [0.1 0.1 0.75 0.8]);
           
           l(1) = xlabel('Distance down gut (normalized)');
           l(2) = ylabel(' \leftarrow Time (hours)');
           
           arrayfun(@(x)set(x, 'FontSize', 24), l);
           shadedErrorBar(cen(:,1), cen(:,3), cen(:,2), {},1, 'vertical')
        end
        
        function plot1dDistribution(obj, colorList)
            %Plot the 1d distribution of bacteria over time
            % colorList: List of 
            %
            
            %% Line-by-line plots
            f = obj;
            NtimePoints = f.totalNumScans-2;
            cData{1} = summer(ceil(2*NtimePoints));
            cData{2} = hot(ceil(2*NtimePoints));
            
            % Plot all green data, line-by-line
            figure();
            hold on
            clear hp
            
            for i = 1:length(colorList)
                nc = colorList(i);
                for j=1:NtimePoints
                    pop{nc} = f.scan(j,nc).lineDist;
                    %pop{2} = f.scan(j,2).lineDist;
                    
                    %Remove everything after the autofluorescent cells
                    pop{nc} = pop{nc}(1:f.scan(j,nc).gutRegionsInd(4));
                    
                    %Normalize the populations
                    %pop{nc} = pop{nc}/sum(pop{nc});
                    
                    %Smooth out population curves, so that early time vibrio don't look so
                    %noisy
                    %pop{nc} = smooth(pop{nc}, 'moving',3);
                    
                    x = 1:length(pop{nc});
                    x = 5*x;
                    t = obj.t(j)*ones(length(x),1);
                    
                    hp(j,i) = plot3(x, t, pop{nc}, 'Color', cData{nc}(NtimePoints,:));
                    %hp(j,2) = plot3(x, t, pop{2}, 'Color', cData_red(NtimePoints,:));
                    hp(j,length(colorList)+1) = plot3(x, t, zeros(length(pop{nc}),1), 'Color', [0.9 0.9 0.9]);
                end
            end
            
            %Set range appropriately
            m = arrayfun(@(x)get(x, 'ZData'), hp(:,1:length(colorList)), 'UniformOutput', false);
            m = cellfun(@(x)max(x), m);
            maxZ = max(m(:));
            set(gca, 'ZLim', [0 maxZ]);
            viewangle = [-10 70];  % alt, az
            set(gca, 'View', viewangle);
            set(gcf, 'Position', [183 97 1360 850]);
            l(1) = xlabel('Position (Anterior-Posterior) microns');
            l(2) = ylabel('Time (hours');
            l(3) = zlabel('Normalized Density');
            arrayfun(@(x)set(x, 'FontSize', 24), l);
            arrayfun(@(x)set(x, 'LineWidth', 3), hp);
            
            print('-dpng', [obj.saveLoc filesep 'PopulationCurve.png']);
        end
        
        function plotSpatialOverlap(obj)
             hold on;
           for ns=1:obj.totalNumScans
              for nc = 1:obj.totalNumColor
                  pop{nc} = obj.scan(ns,nc).lineDist;
                 % pop{nc} = pop{nc}/sum(pop{nc});
                  
                 %pop{nc} = smooth(pop{nc}, 'moving', 3);
                  
              end
              plot(pop{1}, pop{2},'o');
              
           end
        end
        function pop = getPopData(obj)
%             pop = cell(obj.totalNumScans,1);
%             for ns=1:obj.totalNumScans
%                 for nc = 1:obj.totalNumColor
%                     temp = obj.scan(ns,nc).lineDist;
%                     temp = smooth(temp, 'moving', 3);
%                     % pop{nc} = pop{nc}/sum(pop{nc});
%                     pop{ns}(nc,1:length(temp)) = temp;  
%                     fprintf(1, '.');
%                 end
%             end
            
            
            %Calculate radial distribution function
            for ns=1:obj.totalNumScans
                for nc = 1:obj.totalNumColor
                    pop{nc} = obj.scan(ns,nc).lineDist;
                end
                numEl = max([length(pop{nc}), length(pop{nc})]);
                pop{1} = pop{1}(1:numEl);
                pop{2} = pop{2}(1:numEl);
                
                
                %Correlation of each with itself
                n = 1:100;
                for nc=1:obj.totalNumColor
                    for n=1:100
                        for i=1:length(pop{nc})               
                            %Update the radial distribution function
                            
                            
                            if( (i-n>0) && (i+n)<=length(pop{nc}))
                                thispop(n,i) = 0.5*(pop{nc}(i-n) + pop{nc}(i+n));
                            elseif(i-n<1)
                                thispop(n,i) = pop{nc}(i+n);
                            elseif(i+n>length(pop{nc}))
                                thispop(n,i) = pop{nc}(i-n);
                            else
                                thispop(n,i) =0;
                            end
                            
                            %Rescale each of these numbers by the
                            %population in each bin-treating each as a
                            %stack of individual bugs.
                            thispop(:,i) = pop{nc}(i)*thispop(:,i);
                        end
                    end
                
                    %Rescale by 1/2*pi*distance to spot
                    thispop = repmat(1./(2*pi*(1:100)), size(thispop,2),1)'.*thispop;
                end
                
            end 
            
        end
        
        function [obj, Nth] = fitLogisticCurve(obj, fitType)
            
            fitField = {'r', 'K', 'N0', 't_lag', 'sigr', 'sigK', 'sigN0', 'sigt_lag'};
            
            for i=1:length(fitField)
               obj.fitParam.(fitField{i}) = zeros(obj.totalNumColor,1); 
            end
                
            Nth = cell(obj.totalNumColor,1);
            
            for nC=1:obj.totalNumColor
                
                switch fitType
                    case 'clump'
                        pop = obj.sH(:,nC);
                    case 'indiv'
                        pop = obj.sL(:,nC);
                    case 'all'
                        pop = obj.sL(:,nC)+obj.sH(:,nC);
                end
                
                adjustFitParam = false;
                fitParam = [];
                
                [halfboxsize, alt_fit, tolN, params0, LB, UB, lsqoptions, fitRange] =...
                    getFitParameters(adjustFitParam, fitParam);
                
                
                if(obj.totalNumColor>1)
                    alt_fit = obj.fitParam.(fitType).alt_fit{nC};
                    
                    minS= obj.fitParam.(fitType).minS{nC};
                    maxS = obj.fitParam.(fitType).maxS{nC};
                elseif(obj.totalNumColor==1)
                    alt_fit = obj.fitParam.(fitType).alt_fit;
                    
                    minS= obj.fitParam.(fitType).minS;
                    maxS = obj.fitParam.(fitType).maxS;
                end
                
                Nth{nC} = zeros(maxS-minS+1, 1);
                % fit, using fit_logistic_growth.m
                [r(nC), K(nC), N0(nC), t_lag(nC), sigr(nC), sigK(nC), sigN0(nC), sigt_lag(nC)] = ...
                    fit_logistic_growth(obj.t(minS:maxS),pop(minS:maxS,nC), alt_fit, halfboxsize, tolN, params0, LB, UB, lsqoptions);
                
                % Logistic fit curves, for each population
                Nth{nC} = logistic_N_t(obj.t(minS:maxS), r(nC), K(nC), N0(nC), t_lag(nC));
                
                colors{1}(1,:) = [0.2 0.7 0.4];
                
                colors{2}(1,:) = [0.8 0.2 0.4];
                
                figure;hold on
                %Plotting the result
                hLogPlot(nC) = semilogy(obj.t,pop(:,nC), 'o', 'color', 0.8*colors{nC}(1,:), 'markerfacecolor', colors{nC}(:));
                
                %Plot
                lineFit(nC) = semilogy(obj.t(minS:maxS), Nth{nC}, '-', 'color', 0.5*colors{nC}(:));
                set(gca, 'YScale', 'log');
                title(fitType)
                
            end
            
            obj.fitParam.(fitType).r = r;
            obj.fitParam.(fitType).K = K;
            obj.fitParam.(fitType).N0 = N0;
            obj.fitParam.(fitType).t_lag = t_lag;
            obj.fitParam.(fitType).sigr = sigr;
            obj.fitParam.(fitType).sigK = sigK;
            obj.fitParam.(fitType).sigN0 = sigN0;
            obj.fitParam.(fitType).sigt_lag = sigt_lag;
        end
        
        function makeMovie(obj, fileName, minS, maxS)
            %makeMovie(obj, fileName, minS, maxS): Make a move for selected
            %color range and for all colors.
            figure;
           
            minS = 1;
            maxS = obj.totalNumScans;

            for colorNum=1:obj.totalNumColor
           
                colorList = {'488nm', '568nm'};
               % colorList  = {'568nm'};
                if(iscell(obj.saveLoc))
                    sl = obj.saveLoc{1};
                else
                    sl = obj.saveLoc;
                end
                fileDir = [sl filesep 'movie' colorList{colorNum}];
                mkdir(fileDir);
                
                recalcProj = false;
                zNum = [];
                
                for nS = minS:maxS
                    
                    %For now let's just copy the original images into a
                    %different subfolder, that we'll let work a bit with
                    %imageJ
                    inputFile = [obj.saveLoc filesep 'FluoroScan_' num2str(nS) '_' colorList{colorNum} '.tiff'];
                    outputFile = [fileDir filesep 'FluoroScan_' colorList{colorNum} num2str(nS) '.tiff'];

                    copyfile(inputFile, outputFile);
%                     
%                     inputVar = load([obj.scan(nS,colorNum).saveLoc filesep 'param.mat']);
%                     paramIn = inputVar.param;
%                     
%                     scanNum = obj.scan(nS, colorNum).scanNum;
%                     im = selectProjection(paramIn, 'mip', 'true', scanNum,colorList{colorNum}, zNum,recalcProj);
%                    % imshow(im, [0 1000]);
%                     im(im>1000) = 1000;
%                     imwrite(uint16(im), [fileDir filesep 'movie', sprintf('%03d', nS), '.png']);
%                     %fileName = [obj.scan(nS,colorNum).saveLoc filesep 'masks' filesep 'clumpAndIndiv_nS' num2str(obj.scan(nS,colorNum).scanNum) '_' colorList{colorNum} '.mat'];
%                     fileName = [obj.scan(nS,colorNum).saveLoc filesep 'masks' filesep 'allRegMask_' num2str(obj.scan(nS,colorNum).scanNum) '_' colorList{colorNum} '.mat'];
%                     inputVar = load(fileName);
%                     segMask = inputVar.segMask;
%                     segMask = segMask>0;
%                     maskFeat.Type = 'perim';
%                     maskFeat.seSize = 5;
%                     segmentationType.Selection = 'clump and indiv';
%                     rgbIm = segmentRegionShowMask(segMask, maskFeat,segmentationType,gca);
%                    % hAlpha = alphamask(rgbIm, [1 0 0], 0.5, gca);
                   
%                    print('-dpng', [fileDir filesep 'movie', sprintf('%03d', nS), '.png']);
                    
                    fprintf(1, '.');
                end
            end
            fprintf(1, '\n');
        end
        
        function save(obj)
           f = obj;
           save([obj.saveLoc filesep obj.saveName], 'f', '-v7.3');
        end
        
        function calcAll(obj)
           %Function that runs the entire analysis pipeline
           inputVar = load([obj.saveLoc filesep 'param.mat']);
           param = inputVar.param;
           
           %%Create masks
           %Gut region masks
            maskFish.getGutRegionMaskAll(param);
<<<<<<< HEAD
           %Segmentation masks
            obj = calcMasks(obj);
            obj = obj.filterMasks;
            
=======
           
>>>>>>> 81976a93167904356c40fcfdeaa84b14888e1f87
           %% Find all spots
           s = spotFishClass(param);
           s.findSpots(param);
           s.resortFoundSpot(param);
           s  = s.createClassificationPipeline('all');
           for c =1:obj.totalNumColor
              s.spotClassifier{c} = spotClassifier;
              s.spotClassifier{c}.autoFluorMaxInten = 0;
           end
           s.saveInstance;

           %Segmentation masks
           obj = calcMasks(obj);
           
           
           %%Find clumps
           calcClumps(obj);
           
        end
    end

    methods(Static)
        function updateAllSliceNum(param)
           %Update all the parts of the analysis that got messed up b/c of
           %the param file center line not being appropriately resampled
           scanParam.stepSize = 5;
           param = resampleCenterLine(param, scanParam);
            
           param.gutRegionsInd = findGutRegionMaskNumber(param, true);
           
           spots = spotFishClass(param);
           
           spots.update('gutSlice',param);
           
        end
    end
end
    