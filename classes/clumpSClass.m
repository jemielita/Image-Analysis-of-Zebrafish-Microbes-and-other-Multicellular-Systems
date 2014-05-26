%Class to hold the information about all of the clumps in a particular scan

classdef clumpSClass
    
    properties
        saveStr = 'clump';
        numClumps = NaN;
        allData = [];
        saveLoc = '';
        
        scanNum = NaN;
        colorNum = NaN;
        colorStr
        
        allDataOrig = [];
        remInd = [];
        
        
        indivCentroid;
        indivRegionList;
        clumpCentroid;
        clumpRegionList;
            
            
    end
    
    
    methods
        
        function obj = clumpSClass(param, scanNum, colorNum,varargin)
            
               % obj = obj@scanClass(param, scanNum,colorNum);
               % obj = obj@clumpAllClass(param);
               
               obj.saveLoc = param.dataSaveDirectory;
               obj.scanNum = scanNum;
               obj.colorNum = colorNum;
               obj.colorStr = param.color{colorNum};
               
               if(nargin==4)
                   switch varargin{1}
                       case 'get'
                           obj = get(obj);
                   end
               end
        end
        function ind = findRemovedClump(obj, loc)
           %Update indices of clumps to remove 
           ind = obj.remInd;
           
           cen = [obj.allData.cropRect];
           cen = reshape(cen, 4, length(obj.allData));
           
           out = [cen(1,:) + (0.5*cen(3,:)) ; cen(2,:) + (0.5*(cen(4,:)))];
           
           d = cellfun(@(x)dist(x, out), loc, 'UniformOutput', false);
           i = cellfun(@(x)find(x==min(x)), d);
           
           newInd = [obj.allData(i).IND];
           
           ind = [ind, newInd];
           
           ind = unique(ind);
        end
        
        function obj = save(obj)
            
            sl = [c.saveLoc filesep c.saveStr ];
            if(~isdir(sl))
                mkdir(sl);
            end
            save([sl filesep 'clumpAll_ ' c.colorStr '_nS' num2str(c.scanNum) '.mat'], 'c');
        end
        
        function obj = get(obj)
           %Either get the clumps from this scan or calculate them
           fileDir = [obj.saveLoc filesep 'clump' filesep 'clumpAll_ ' obj.colorStr '_nS' num2str(obj.scanNum) '.mat'];
           f = exist(fileDir, 'dir');
           if(f==2)
               inputVar = load([obj.saveLoc filesep 'clump' filesep 'clumpAll_ ' obj.colorStr '_nS' num2str(obj.scanNum) '.mat']);
               obj.allData = inputVar.c;
               obj.numClumps = length(inputVar.c);
               return;
           end
           
           %Load clump data from individual files
           fileDir = [obj.saveLoc filesep 'clump' filesep 'clump_' obj.colorStr '_nS' num2str(obj.scanNum)];
           f = exist(fileDir, 'file');
           if(f==7)
               %Is directory
               obj.allData = loadClumps(obj,fileDir);
               obj.numClumps = length(obj.allData);
               return;
           end
          
           %Otherwise recalculate data and load
           obj.allData = loadClumps(obj, fileDir);
           obj.numClumps = length(obj.allData);
           
        end
        
        function allData = loadClumps(obj,fileDir)
            %Set total number of clumps
            b = dir(fileDir);
            d = arrayfun(@(x)regexp(b(x).name, '.mat'), 1:size(b,1), 'UniformOutput', false);
            e = cellfun(@(x)~isempty(x), d);
            
            b = b(e);
            obj.numClumps = length(b);
            
            if(obj.numClumps~=0)
                temp = cell2mat(arrayfun(@(x)load([fileDir filesep b(x).name], 'c'), 1:obj.numClumps, 'UniformOutput', false));
                allData = [temp.c];
            else
                allData = [];
            end
            
        end
        
        function obj = construct(obj)
            %Construct list of clumps in this particular scan
            inputVar = load([obj.saveLoc filesep 'param.mat']);
            param = inputVar.param;
            clump3dSegThreshAll(param, obj.scanNum, obj.colorNum, true);
             
        end
        
        %Display data from clump data
        function hist(obj,varargin)
            
            %Plot all data from a particular field
            
            switch nargin
                case 1
                nBin = 30;
                field = 'volume';
                case 2
                    nBin = 30;
                    field = varargin{1};
                case 3
                    field = varargin{1};
                    nBin = varargin{2};
            end
                
                
            figure;
            switch field
                case 'volume'
                    hist([obj.allData.volume], nBin);
                case 'totalInten'
                    hist([obj.allData.totalInten], nBin);
                case 'itnenCutoff'
                    hist([obj.allData.intenCutoff], nBin);                    
            end
            
            title(['Histogram for ' field]);
            ylabel('#');
            xlabel(field);
                    
                
        end
        
        function histLog(obj, varargin)
            
            %Plot all data from a particular field
            
            switch nargin
                case 1
                nBin = 30;
                field = 'volume';
                case 2
                    nBin = 30;
                    field = varargin{1};
                case 3
                    field = varargin{1};
                    nBin = varargin{2};
            end
                
                
            figure;
            switch field
                case 'volume'
                    hist(log([obj.allData.volume]), nBin);
                case 'totalInten'
                    hist(log([obj.allData.totalInten]), nBin);
                case 'intenCutoff'
                    hist(log([obj.allData.intenCutoff]), nBin);                    
            end
            
            title(['Histogram for ' field]);
            ylabel('#');
            xlabel(field);
            
        end
        
        function obj = cullClumps(obj, regCutoff)
            %Remove clumps from list based on what's been manually removed
            obj.allDataOrig = obj.allData;
            
            if(isempty(obj.allData))
                return
            end
                
            
            [~,ind] = ismember(obj.remInd,[obj.allData.IND]);
            
            ind(ind==0) = [];
            obj.allData(ind) = [];
           
            gutInd = [obj.allData.gutRegion];
            gutInd = gutInd<regCutoff;
            obj.allData = obj.allData(gutInd);       
            
            
        end
        
        function obj = restoreOrigClumps(obj)
           if(~isempty(obj.allDataOrig))
              obj.allData = obj.allDataOrig; 
           else
              fprintf(2, 'Data not culled in any way! Not doing anything.\n'); 
           end
        end
        
        
        function obj = calcCenterMass(obj,cut,regCutoff)
            if(isempty(obj.allData))
                obj.indivCentroid = nan(2,3);
                obj.indivRegionList = nan;
                
                obj.clumpCentroid = nan(2,3);
                obj.clumpRegionList = nan;
                
                return
                
            end
            cut = cut(obj.colorNum);
            %Load in segmentation mask
            fileName = [obj.saveLoc filesep 'masks' filesep 'clumpAndIndiv_nS' num2str(obj.scanNum) '_' obj.colorStr '.mat'];
            inputVar = load(fileName);
            segMask = inputVar.segMask;
            
            %Replace each one of these masks with the mean intensity of
            %each of the found spots.
            
            labelC = (segMask==2);
            labelI = (segMask==1);
            
            %Load in unrotated mask
            fileName = [obj.saveLoc filesep 'masks' filesep 'maskUnrotated_' num2str(obj.scanNum) '.mat'];
            inputVar = load(fileName);
            gutMask = inputVar.gutMask;
            intenMask = zeros(size(gutMask));
            logMask = zeros(size(gutMask));
            
            regCutoff = 4;
            
            %Calculate the center of mass of all clumps and individuals in
            %the gut.
            %stupid cludge because of mistakes in how clumps are
            %constructed.
            for i=1:length(obj.allData)
                
                val = obj.allData(i).totalInten>cut;
                if(isempty(val))
                    isClump(i) = 0;
                else
                    isClump(i) = val;
                end
                val = obj.allData(i).totalInten<=cut;
                if(isempty(val))
                    isIndiv(i) = 0;
                else
                    isIndiv(i) = val;
                end
                
                val = obj.allData(i).gutRegion<=regCutoff;
                if(isempty(val))
                    inGut(i) = 0;
                else
                    inGut(i) = val;
                end
            end
            isClump = logical(isClump.*inGut);
            isIndiv = logical(isIndiv.*inGut);
            
            clumpInd = [obj.allData(isClump).IND];
            indivInd = [obj.allData(isIndiv).IND];
            
            [obj.indivCentroid, obj.indivRegionList] = getCentroidInfo(indivInd, labelI);
            [obj.clumpCentroid, obj.clumpRegionList] = getCentroidInfo(clumpInd, labelC);
            
            function [centroid, regionList] = getCentroidInfo(ind,labelM)
                if(isempty(ind))
                   centroid = nan(2,3);
                   regionList = nan;
                   return;
                end 
                
                intenMask(:) = 0;
                logMask = repmat(labelM,1,1,size(gutMask,3));
                intenMask = gutMask.*(logMask>0);
                
%                 gutInd = unique(gutMask(:));
%                 gutInd(gutInd==0) = [];
%                 %  uniqEl = unique(intenMask(:));
%                 intenL{1}(:,1) = arrayfun(@(x)sum(intenMask(intenMask(:)==x)), gutInd);
%                 intenL{1}(:,2) = gutInd;
%                 
                rp = regionprops(intenMask,'Area');
                allReg = unique(intenMask(:));
                allReg(allReg==0) = [];
                intenL{1}(:,1) = [rp(allReg).Area];
                intenL{1}(:,2) = allReg;
                
                
                %Get a distribution of intensities of spots
               %mlj: for now lets not do this-it's somewhat slow and tells
               %us something different than what we're interested in
%                 intenM = zeros(size(labelM));
%                 
%                 for i=1:length(ind)
%                     area = sum(labelM(:)==ind(i));
%                     
%                     meanInten = obj.allData(ind(i)).totalInten;
%                     intenM(labelM==ind(i)) = meanInten/area;
%                 end
%                
%                 
%                 %Now getting the total intensity in each box
%                 intenL{2} = zeros(length(ind),2);
%                 intenM = repmat(intenM, 1, 1, size(gutMask,3));
%                 logM = gutMask>0;
%                 intenL{2}(:,1) = arrayfun(@(x)sum(logM(gutMask==x).*intenM(gutMask==x)), ind);
%                 intenL{2}(:,2) = ind;
                
                %Now get information about the centroid, etc.
                for i=1:1
                    %Normalize itensity curve
                    intenL{i}(:,1) = intenL{i}(:,1)/sum(intenL{i}(:,1));
                    
                    %Turn into cdf
                    cdf = cumsum(intenL{i}(:,1));
                    valRange = intenL{i}(:,2);
                 %   cdf = cdf/sum(cdf);
                    %Interpolate curve
                    %interpRange = 1:0.01: max(intenL{i}(:,2));
                    
                   % cdf2 = interp1(intenL{i}(:,2), cdf, interpRange);
                    
                    
                    %Now find index closest to the center and to the range of
                    %the middle quartile
                    
                    [~,indM] = min(abs(cdf-0.5));
                    centroid(i,1) = valRange(indM);
                    
                    [~,indM] = min(abs(cdf-0.75));
                    centroid(i,2) = valRange(indM);
                    
                    [~,indM] = min(abs(cdf-0.25));
                    centroid(i,3) = valRange(indM);
                end
                regionList = allReg;
                
%                centroid{1} = sum(intenL{1}(1,:).*intenL{1}(2,:))./sum(itenL{1}(1,:));
                
 %               centroid{2} = sum(intenL{2}(1,:).*intenL{2}(2,:))./sum(itenL{2}(1,:));
                
                
            end
            
        end
        
    end
    
end