% assembleClusterDistributions.m
%
function assembleClusterDistributions(maindir,ids)

load([maindir filesep 'pall.mat']);


if ~exist('ids','var') || isempty(ids)
    ids = 1:numel(pall);
end
    
    
volume_conversion = .1625.*.1625;


for n = 1:numel(ids)
    
    try
    
        
        
        
        f = load([pall{ids(n)}.dataSaveDirectory filesep 'fishAnalysis.mat']); f = f.f;
        
        if isempty(f)
           
            disp(['update fishAnalysis file with segmentation results'])
            return
            
        end
        
        volumes = cell(f.totalNumScans,f.totalNumColor);
        intens = cell(f.totalNumScans,f.totalNumColor);
        numbers = cell(f.totalNumScans,f.totalNumColor);
        
       
        
        for c = 1:f.totalNumColor
            for s = 1:f.totalNumScans
                
                %% assemble cluster properties
                these_volumes = [];
                these_intens = [];
                 
                % clump vols
                these_volumes = [these_volumes [f.scan(s,c).clumps.allData([f.scan(s,c).clumps.allData.IND]>0).volume]];
                
                % all intens
                these_intens = [these_intens, [f.scan(s,c).clumps.allData([f.scan(s,c).clumps.allData.gutRegion] < f.totPopRegCutoff).totalInten]];
                
%                 % spot vols
%                 load([pall{ids(n)}.dataSaveDirectory filesep 'singleBacCount' filesep 'bacCount' num2str(s) '.mat'])
%                 
%                 spots = load([pall{ids(n)}.dataSaveDirectory filesep 'singleBacCount' filesep 'spotClassifier.mat']); spots = spots.spots;
%                 
%                 spot_vols = [rProp{c}.volume];
%                 spot_vols(spots.removeBugInd{s,c}) = [];
%                 
%                 these_volumes = [these_volumes spot_vols];
%                 
%                 these_volumes = these_volumes.*volume_conversion;
                
                
                these_numbers = these_intens./f.singleBacInten(c);
                these_numbers(these_numbers<1) = 1;
                
                numbers{s,c} = these_numbers;
                intens{s,c} = these_intens;
%                 volumes{s,c} = these_volumes;
                
            end
        end

        save([pall{ids(n)}.dataSaveDirectory filesep 'clumps.mat'],'volumes','intens','numbers');
    
       
    
    catch
        disp(['error with ' num2str(ids(n))])
        
        continue
    end
    
end

end
    