function [cluster_info] = assembleClusterInfoMatrix(param)


f = load([param.dataSaveDirectory filesep 'fishAnalysis.mat']); f = f.f;
    
if isempty(f)
    
    disp(['update fishAnalysis file with segmentation results'])
    return
    
end

cluster_info = cell(f.totalNumScans,f.totalNumColor);

for s = 1:f.totalNumScans
    
    for c = 1:f.totalNumColor
        
        counter = 0;
        this_cluster_info_matrix = [];

        num_clusters = numel([f.scan(s,c).clumps.allData.gutRegion] <= f.totPopRegCutoff);

        % loop over clumps and collect relevant info
        for n = 1:num_clusters
            
            this_inten = f.scan(s,c).clumps.allData(n).totalInten;
            
            this_volume = f.scan(s,c).clumps.allData(n).volume;
   
            this_zRange = f.scan(s,c).clumps.allData(n).zRange;
            
            this_centroid = f.scan(s,c).clumps.allData(n).centroid;
            
            this_cropRect = f.scan(s,c).clumps.allData(n).cropRect;
            
            this_isClump = f.scan(s,c).clumps.allData(n).IND > 0;
            
            counter = counter + 1;
            
            if ~this_isClump
                this_zRange(1) = this_centroid(3);
                this_centroid(3) = [];
            end
                
            % assemble info into row of matrix
            this_row = [counter, this_centroid, this_cropRect, this_zRange, this_isClump, this_inten, this_volume]; 
            
            this_cluster_info_matrix = [this_cluster_info_matrix; this_row];
            
        end
        
        cluster_info{s,c} = this_cluster_info_matrix;
        
    end
    
end
            


end