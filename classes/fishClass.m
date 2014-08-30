%fishClass: Class to store all analysis information about a particular fish

classdef fishClass
    
    
    properties
        saveLoc = '';
        totPop = [];
        
        sL = [];
        sH = [];
        
        mL = [];
        mH = [];
        
        nL = [];
        nH = [];
        
        
        %For our analysis of clump and individuals distributions
        clumpCentroid = cell(2,1);
        indivCentroid = cell(2,1);
        clumpRegionList = cell(2,1);
        indivRegionList = cell(2,1);
        
        
        
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
        
        growthRateWindow = [];
        wSize = 3;
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
        
        
        function obj = calcMasks(obj)
            
            for s = 1:obj.totalNumScans
                for c = 1:obj.totalNumColor
                    obj.scan(s,c).calcMask();
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
                    obj.scan(s,c)  = obj.scan(s,c).clumps.calcCenterMass(obj.cut);
                    fprintf(1, '.');
                end
                
            end
            fprintf(1, '\n'); 
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
            
            sAll = zeros(obj.totalNumScans, obj.totalNumColor);
            
            for c = 1:obj.totalNumColor
                for s = 1:obj.totalNumScans
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
                pL = arrayfun(@(x)[obj.scan(x,nC).clumps.allData.totalInten]<obj.cut(nC), 1:obj.totalNumScans, ...
                    'UniformOutput', false);
                pH = arrayfun(@(x)[obj.scan(x,nC).clumps.allData.totalInten]>=obj.cut(nC), 1:obj.totalNumScans,...
                    'UniformOutput', false);
                
                temp = arrayfun(@(x)[obj.scan(x,nC).clumps.allData(pL{x}).totalInten], 1:obj.totalNumScans,...
                    'UniformOutput', false);
                obj.singleBacInten(nC) = mean(cell2mat(temp));
                
%                 %Total clump and individual intensity
%                 obj.sL(:,nC) = arrayfun(@(x) sum([obj.scan(x,nC).clumps.allData(pL{x}).totalInten]), 1:obj.totalNumScans);
%                 obj.sH(:,nC) = arrayfun(@(x) sum([obj.scan(x,nC).clumps.allData(pH{x}).totalInten]), 1:obj.totalNumScans);
%                
%                 obj.sL(:,nC) = obj.sL(:,nC)/obj.singleBacInten(nC);
%                 obj.sH(:,nC) = obj.sH(:,nC)/obj.singleBacInten(nC);
%                 
%                 %Mean clump and individual intensity
%                 obj.mL(:,nC) = arrayfun(@(x) mean([obj.scan(x,nC).clumps.allData(pL{x}).totalInten]), 1:obj.totalNumScans);
%                 obj.mH(:,nC) = arrayfun(@(x) mean([obj.scan(x,nC).clumps.allData(pH{x}).totalInten]), 1:obj.totalNumScans);
%                 
%                 obj.mL(:,nC) = obj.mL(:,nC)/obj.singleBacInten(nC);
%                 obj.mH(:,nC) = obj.mH(:,nC)/obj.singleBacInten(nC);
%                 
%                 %Total fraction of population in largest clump
%                 highPop = arrayfun(@(x)max([obj.scan(x,nC).clumps.allData.totalInten]), 1:obj.totalNumScans,...
%                     'UniformOutput', false);
%                 emptyEl = cellfun(@(x)isempty(x), highPop);
%                 highPop(emptyEl) = {0};
%                 highPop = cell2mat(highPop);
%                 highPop = highPop/obj.singleBacInten(nC);
%                 
%                 obj.highPopFrac(:,nC) = highPop'./(obj.sL(:,nC)+obj.sH(:,nC));
%                 
%                 %Total number of clumps and individuals
%                 obj.nL(:,nC) = cellfun(@(x) sum(x), pL);
%                 obj.nH(:,nC) = cellfun(@(x) sum(x), pH);
%                 
                
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
                   %measured by the
                   type = 'clump';
                   pop = obj.totPop.(type);
                   
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
                        
                    case 'width normalized indiv'
                        regList = obj.scan(nS, colorNum).clumps.indivRegionList;
                        if(isnan(regList))
                            continue;
                        else
                            gw = (obj.scan(nS,colorNum).gutWidth).^2;
                            regList(2,:) = regList(2,:)./(gw(regList(1,:)))';
                            
                            cen(nS,1) = obj.scan(nS,colorNum).clumps.indivCentroid(2,1);
                            cen(nS,2) = obj.scan(nS,colorNum).clumps.indivCentroid(2,2);
                        end
                    case 'width normalized clump'
                        regList = obj.scan(nS, colorNum).clumps.clumpRegionList;
                        if(isnan(regList))
                            continue;
                        else
                            gw = (obj.scan(nS,colorNum).gutWidth).^2;
                            regList(2,:) = regList(2,:)./(gw(regList(1,:)))';
                            cen(nS,1) = obj.scan(nS,colorNum).clumps.clumpCentroid(2,1);
                            cen(nS,2) = obj.scan(nS,colorNum).clumps.clumpCentroid(2,2);
                        end
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
                
                normVal = {'width normalized indiv', 'width normalized clump'};
                if(ismember(segType, normVal))
                    t = regList(2,:);
                else
                    t = log(regList(2,:)); 
                    t = regList(2,:);
                    t(t<0) = 0;
                end
                im(nS,regList(1,:)) = t;
                
            end
        end

        function plotPopulationHeatMap(obj, colorNum, segType)
            
           [im, cen] = obj.getPopulationHeatMap(colorNum, segType);
           %im(24,:) = 0;
           %cen(24,:) = nan;
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
        %   shadedErrorBar(cen(:,1), cen(:,3), cen(:,2), {},1, 'vertical')
        end
        
        function [obj, varargout] = fitLogisticCurve(obj, fitType)
            
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
            
            if(nargout==2)
               varargout{1} = Nth; 
            end
        end
        
        function makeMovie(obj, fileName)
            figure;
           
            for colorNum=1:obj.totalNumColor
           
                colorList = {'488nm', '568nm'};
                fileDir = [obj.saveLoc filesep 'movie' colorList{colorNum}];
                mkdir(fileDir);
                
                recalcProj = false;
                zNum = [];
                
                for nS = 1:obj.totalNumScans
                    inputVar = load([obj.scan(nS,colorNum).saveLoc filesep 'param.mat']);
                    paramIn = inputVar.param;
                    
                    scanNum = obj.scan(nS, colorNum).scanNum;
                    paramIn.dataSaveDirectory = paramIn.dataSaveDirectory;
                    im = selectProjection(paramIn, 'mip', 'true', scanNum,colorList{colorNum}, zNum,recalcProj);
                    imshow(im, [0 1000]);
                    
                    inputVar = load([obj.saveLoc filesep 'masks' filesep 'allRegMask_' num2str(nS) '_' obj.scan(nS,colorNum).colorStr '.mat']);
                    segMask = inputVar.segMask>0;
                    
                    maskFeat.Type = 'perim';
                    maskFeat.seSize = 5;
                    segmentationType.Selection = 'clump and indiv';
                    rgbIm = segmentRegionShowMask(segMask, maskFeat,segmentationType,gca);
                    hAlpha = alphamask(rgbIm, [1 0 0], 0.5, gca);
                    
                    print('-dpng', [fileDir filesep 'movie', sprintf('%03d', nS), '.png']);
                    
                    fprintf(1, '.');
                end
            end
            fprintf(1, '\n');
        end

end
end
    