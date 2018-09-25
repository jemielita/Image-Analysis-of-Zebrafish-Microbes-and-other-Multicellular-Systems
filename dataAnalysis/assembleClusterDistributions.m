% assembleClusterDistributions.m
%
% workflow: first run with a threshhold, look at results, manually remove
% more spots if neccesary, update fishAnalysis, run again without thresh.
function assembleClusterDistributions(maindir,lthresh,ids)

volume_conversion = .1625.*.1625;
spot_thresh_frac = .25;

load([maindir filesep 'pall.mat']);

try
    load([maindir filesep 'thresh_all.mat']);
catch
    disp(['thresh_all doesnt exist'])
    return
%     thresh_all = {};
%     for m = 1:numel(pall)
%         thresh_all{m} = 5000;
%     end
end



for n = 1:numel(ids)
    
    try
    
        volumes = [];
        intens = [];
        
        
        f = load([pall{ids(n)}.dataSaveDirectory filesep 'fishAnalysis.mat']); f = f.f;
        
        if isempty(f)
            f = fishClass(pall{ids(n)});
            
            if ~isempty(thresh_all);
                f.lManuallySetClumpIntenThresh = 1;
                f.colorInten = thresh_all{ids(n)};
            end
            
            f = f.getClumps; f.cut = [1e8 ]; f = f.combClumpIndiv; f = f.getClumpData; f = f.getTotPop; f = f.calc1dProj; f = f.getGlobalCentersOfMass; f.save;
            
        end
        
        
        
        
        
%         %% cull spots
%         
%         if lcull
%             spots = load([pall{ids(n)}.dataSaveDirectory filesep 'singleBacCount' filesep 'spotClassifier.mat']); spots = spots.spots;
%             
%             %spots = load([pall{n}.dataSaveDirectory filesep 'singleBacCount' filesep 'backup' filesep 'spotClassifier.mat']); spots = spots.spots;
%             
%             backupdir = [pall{ids(n)}.dataSaveDirectory filesep 'singleBacCount' filesep 'backup'];
%             
%             if exist(backupdir,'dir')
%                 clockinfo = clock;
%                 backupdir_name = ['backup' num2str(clockinfo)];
%             else
%                 backupdir_name = 'backup';
%             end
%             
%             spots.backup([],backupdir_name);
%                 
%             spots.cull('objmean',spot_cull_frac.*thresh_all{ids(n)});
%                      
%             f.calcClumpSpotOverlap;
%             
%             spots.classifySpots;
%             
%             f = f.getClumps; f.cut = [1e8 ]; f = f.combClumpIndiv; f = f.getClumpData; f = f.getTotPop; f = f.calc1dProj; f = f.getGlobalCentersOfMass; f.save;
%         
%         
%         end
            
        %% thresh
        % rather than delete spots from rProp, just add them to
        % removeBugInd.  Easier for interfacing with manually removed
        % spots.
        
        if lthresh
            spots = load([pall{ids(n)}.dataSaveDirectory filesep 'singleBacCount' filesep 'spotClassifier.mat']); spots = spots.spots;
                        
            backupdir = [pall{ids(n)}.dataSaveDirectory filesep 'singleBacCount' filesep 'backup'];
            
            if exist(backupdir,'dir')
                clockinfo = clock;
                backupdir_name = ['backup' num2str(clockinfo)];
            else
                backupdir_name = 'backup';
            end
            
            spots.backup([],backupdir_name);
            
            load([pall{ids(n)}.dataSaveDirectory filesep 'singleBacCount' filesep 'bacCount1.mat'])

            spots.removeBugInd{1} = [spots.removeBugInd{1} find([rProp{1}.objMean] < spot_thresh_frac.*thresh_all{ids(n)})];
        
            spots.saveInstance;
            
            f = f.getClumps; f.cut = [1e8 ]; f = f.combClumpIndiv; f = f.getClumpData; f = f.getTotPop; f = f.calc1dProj; f = f.getGlobalCentersOfMass; f.save;

        end
        
        %% assemble cluster properties
        
        % clump vols
        volumes = [volumes [f.scan(1).clumps.allData([f.scan(1).clumps.allData.IND]>0).volume]];
        
        % all intens
        intens = [intens, [f.scan(1).clumps.allData.totalInten]];   
        
        % spot vols
        load([pall{ids(n)}.dataSaveDirectory filesep 'singleBacCount' filesep 'bacCount1.mat'])
        
        spots = load([pall{ids(n)}.dataSaveDirectory filesep 'singleBacCount' filesep 'spotClassifier.mat']); spots = spots.spots;

        spot_vols = [rProp{1}.volume];
        spot_vols(spots.removeBugInd{1}) = [];
        
        volumes = [volumes spot_vols];
        
        volumes = volumes.*volume_conversion;
                
        
        numbers = intens./f.singleBacInten;
        numbers(numbers<1) = 1;
    

        save([pall{ids(n)}.dataSaveDirectory filesep 'clumps.mat'],'volumes','intens','numbers');
    
       
    
    catch
        disp(['error with ' num2str(ids(n))])
        
        continue
    end
    
end

end
    