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
        
        function obj = calcCenterMass(obj,cut,maxRegNum)
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
            %Removing regions of the gut past where we're stopping our
            %analysis
            gutMask(gutMask(:)>maxRegNum) = 0;
            
            regMask = zeros(size(gutMask));
            logMask = zeros(size(gutMask));
            
            
            
            fileName = [obj.saveLoc filesep 'masks' filesep 'allRegMask_' num2str(obj.scanNum) '_' obj.colorStr '.mat'];
            inputVar = load(fileName);
            intenMask = inputVar.segMask;
            
            for j=1:length(obj.allData)
                regArea = sum(intenMask(:)==obj.allData(j).IND);
               intenMask(intenMask==obj.allData(j).IND) = obj.allData(j).totalInten/regArea;
            end
            intenMask = repmat(intenMask, 1,1,size(gutMask,3));
            
            regCutoff = 4;
            
            %Calculate the center of mass of all clumps and individuals in
            %the gut.
            %stupid cludge because of mistakes in how clumps are
            %constructed.
            for j=1:length(obj.allData)
                
                val = obj.allData(j).totalInten>cut;
                if(isempty(val))
                    isClump(j) = 0;
                else
                    isClump(j) = val;
                end
                val = obj.allData(j).totalInten<=cut;
                if(isempty(val))
                    isIndiv(j) = 0;
                else
                    isIndiv(j) = val;
                end
                
                val = obj.allData(j).gutRegion<=regCutoff;
                if(isempty(val))
                    inGut(j) = 0;
                else
                    inGut(j) = val;
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
                
                regMask(:) = 0;
                logMask = repmat(labelM,1,1,size(gutMask,3));
                regMask = gutMask.*(logMask>0);
                
%                 gutInd = unique(gutMask(:));
%                 gutInd(gutInd==0) = [];
%                 %  uniqEl = unique(intenMask(:));
%                 intenL{1}(:,1) = arrayfun(@(x)sum(intenMask(intenMask(:)==x)), gutInd);
%                 intenL{1}(:,2) = gutInd;
%                 
% figure; imshow(max(regMask,[],3));
% pause

                rp = regionprops(regMask,intenMask, 'Area', 'MeanIntensity');
                allReg = unique(regMask(:));
                allReg(allReg==0) = [];
                if(isempty(allReg))  
                    centroid = nan(2,3);
                    regionList = nan;
                    return
                end
                    
                intenL(:,1) = [rp(allReg).Area];
                intenL(:,2) = [rp(allReg).MeanIntensity].*[rp(allReg).Area];
                intenL(:,3) = allReg;
                regionList = [allReg'; intenL(:,1)'; intenL(:,2)'];
                
                %Now get information about the centroid, etc.
                for i=1:2
                    %Normalize itensity curve
                    intenL(:,i) = intenL(:,i)/sum(intenL(:,i));
                    
                    centroid(i,1) = sum(intenL(:,i).*intenL(:,3));
                    
                    centroid(i,2) = (1/sum(intenL(:,3)))*sum((intenL(:,i)-centroid(i,1)).^2);
                   
                end
                
            end
            
        end
        
        
        function calculateCentroid(obj)
               fileDir = [obj.saveLoc filesep 'clump' filesep 'clump_' obj.colorStr '_nS' num2str(obj.scanNum)];
               fprintf(1, 'Calculating 3d centroid of all clumps');
               
            for i = 1:obj.numClumps
                fileName = [fileDir filesep num2str(i) '.mat'];
                if(exist(fileName,'file')==0)
                    continue
                end
                
                inputVar = load(fileName);
                c = inputVar.c;
                c.saveLoc = obj.saveLoc;
               
                vol = c.loadVolume;
                c = c.calcCentroid(vol);
                
                save([fileDir filesep num2str(i) '.mat'], 'c');
                fprintf(1, '.');
            end
            fprintf(1, '\n');
           
        end
        
        function obj = calcCenterMass(obj,cut,maxRegNum)
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
            %Removing regions of the gut past where we're stopping our
            %analysis
            gutMask(gutMask(:)>maxRegNum) = 0;
            
            regMask = zeros(size(gutMask));
            logMask = zeros(size(gutMask));
            
            
            
            fileName = [obj.saveLoc filesep 'masks' filesep 'allRegMask_' num2str(obj.scanNum) '_' obj.colorStr '.mat'];
            inputVar = load(fileName);
            intenMask = inputVar.segMask;
            
            for j=1:length(obj.allData)
                regArea = sum(intenMask(:)==obj.allData(j).IND);
               intenMask(intenMask==obj.allData(j).IND) = obj.allData(j).totalInten/regArea;
            end
            intenMask = repmat(intenMask, 1,1,size(gutMask,3));
            
            regCutoff = 4;
            
            %Calculate the center of mass of all clumps and individuals in
            %the gut.
            %stupid cludge because of mistakes in how clumps are
            %constructed.
            for j=1:length(obj.allData)
                
                val = obj.allData(j).totalInten>cut;
                if(isempty(val))
                    isClump(j) = 0;
                else
                    isClump(j) = val;
                end
                val = obj.allData(j).totalInten<=cut;
                if(isempty(val))
                    isIndiv(j) = 0;
                else
                    isIndiv(j) = val;
                end
                
                val = obj.allData(j).gutRegion<=regCutoff;
                if(isempty(val))
                    inGut(j) = 0;
                else
                    inGut(j) = val;
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
                
                regMask(:) = 0;
                logMask = repmat(labelM,1,1,size(gutMask,3));
                regMask = gutMask.*(logMask>0);
                
%                 gutInd = unique(gutMask(:));
%                 gutInd(gutInd==0) = [];
%                 %  uniqEl = unique(intenMask(:));
%                 intenL{1}(:,1) = arrayfun(@(x)sum(intenMask(intenMask(:)==x)), gutInd);
%                 intenL{1}(:,2) = gutInd;
%                 
% figure; imshow(max(regMask,[],3));
% pause

                rp = regionprops(regMask,intenMask, 'Area', 'MeanIntensity');
                allReg = unique(regMask(:));
                allReg(allReg==0) = [];
                if(isempty(allReg))  
                    centroid = nan(2,3);
                    regionList = nan;
                    return
                end
                    
                intenL(:,1) = [rp(allReg).Area];
                intenL(:,2) = [rp(allReg).MeanIntensity].*[rp(allReg).Area];
                intenL(:,3) = allReg;
                regionList = [allReg'; intenL(:,2)'];
                
                %Now get information about the centroid, etc.
                centroid = zeros(2,2);
                for i=1:2
                    %Normalize intensity curve
                    intenL(:,i) = intenL(:,i)/sum(intenL(:,i));
                    
                    centroid(i,1) = sum(intenL(:,i).*intenL(:,3));
                    
                    centroid(i,2) = (1/sum(intenL(:,3)))*sum((intenL(:,i)-centroid(i,1)).^2);
                   
                end
                
            end
            
        end
        
    end
    
end