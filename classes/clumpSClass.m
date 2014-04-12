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
        
        remInd = [];
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
                case 'itnenCutoff'
                    hist(log([obj.allData.intenCutoff]), nBin);                    
            end
            
            title(['Histogram for ' field]);
            ylabel('#');
            xlabel(field);
            
        end
        
        function cullClumps(obj, filtData)
            %Remove clumps from list based
        end
    end
    
end