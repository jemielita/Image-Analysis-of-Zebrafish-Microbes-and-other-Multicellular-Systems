function [cluster_info_out] = merge2colorClusterInfo(cluster_info)

%% fixed params
% change these if structure of cluster info matrix changes
centroid_inds = [2:3];
crop_rect_inds = [4:7];
z_range_inds = [8:9];
is_clump_ind = [10];
inten_inds = [11];
vol_inds = [12];


%% main function
num_time_points = size(cluster_info,1);
cluster_info_out = cell(num_time_points,1);

for t = 1:num_time_points
    
    num_green_clusters = size(cluster_info{t,1},1);
    num_red_clusters = size(cluster_info{t,2},1);
    
    counter = 0;
    tmp_this_out_cluster_arr = [];
    
    for ng = 1:num_green_clusters
        
        % is this cluster a clump?
        l_green_cluster_is_clump = cluster_info{t,1}(ng,is_clump_ind);
        
        overlap_ids = [];
        overlap_centroid = [];
        overlap_crop_rect = [];
        overlap_zRange = [];
        overlap_vol = [];
        overlap_inten = [];
        overlap_is_clump = [];
        
        this_green_crop_rect = cluster_info{t,1}(ng,crop_rect_inds);
        this_green_zRange = cluster_info{t,1}(ng,z_range_inds);
        this_green_centroid = cluster_info{t,1}(ng,centroid_inds);
        this_green_inten = cluster_info{t,1}(ng,inten_inds);
        this_green_volume = cluster_info{t,1}(ng,vol_inds);
        
        % loop through red clusters
        for nr = 1:num_red_clusters
            
            % is this red cluster a clump?
            l_red_cluster_is_clump = cluster_info{t,2}(nr,is_clump_ind);
            
            if l_green_cluster_is_clump
                
                
                if l_red_cluster_is_clump
                    
                    % for clump-clump comparisons, just look for overlapping
                    % crop_rects
                    
                    this_red_crop_rect = cluster_info{t,2}(nr,crop_rect_inds);
                    this_red_zRange = cluster_info{t,2}(nr,z_range_inds);
                    
                    %%%%%%%%%%%%%%% check corrrectness of x vs y %%%%%%%%%%%%%%
                    ly = this_green_crop_rect(2) >= this_red_crop_rect(2) & this_green_crop_rect(2) <= this_red_crop_rect(2) + this_red_crop_rect(4);
                    lx = this_green_crop_rect(1) >= this_red_crop_rect(1) & this_green_crop_rect(1) <= this_red_crop_rect(1) + this_red_crop_rect(3);
                    lz = this_green_zRange(1) >= this_red_zRange(1) & this_green_zRange(1) <= this_red_zRange(2);
                    
                    l_overlap = lx & ly & lz;
                    
                    if l_overlap
                        
                        ooverlap_ids = [overlap_ids; nr];
                        overlap_centroid = [overlap_centroid; cluster_info{t,2}(nr,centroid_inds)];
                        overlap_crop_rect = [overlap_crop_rect; this_red_crop_rect];
                        overlap_zRange = [overlap_zRange; this_red_zRange];
                        overlap_vol = [overlap_vol; cluster_info{t,2}(nr,vol_inds)];
                        overlap_inten = [overlap_inten; cluster_info{t,2}(nr,inten_inds)];
                        overlap_is_clump = [overlap_is_clump; cluster_info{t,2}(nr,is_clump_ind)];
                        
                    end
                    
                else
                    % for clump-spot comparison, just check if spot centroid is
                    % within clump
                    
                    this_red_centroid = cluster_info{t,2}(nr,centroid_inds);
                    this_red_zRange = cluster_info{t,2}(nr,z_range_inds);
                    
                    lx = this_red_centroid(1) >= this_green_crop_rect(1) & this_red_centroid(1) <= this_green_crop_rect(1) + this_green_crop_rect(3);
                    ly = this_red_centroid(2) >= this_green_crop_rect(2) & this_red_centroid(2) <= this_green_crop_rect(2) + this_green_crop_rect(4);
                    lz = this_red_zRange(1) >= this_green_zRange(1) & this_red_zRange(1) <= this_green_zRange(2);
                    
                    l_overlap = lx & ly & lz;
                    
                    if l_overlap
                        overlap_ids = [overlap_ids; nr];
                        overlap_centroid = [overlap_centroid; cluster_info{t,2}(nr,centroid_inds)];
                        overlap_crop_rect = [overlap_crop_rect; this_red_crop_rect];
                        overlap_zRange = [overlap_zRange; this_red_zRange];
                        overlap_vol = [overlap_vol; cluster_info{t,2}(nr,vol_inds)];
                        overlap_inten = [overlap_inten; cluster_info{t,2}(nr,inten_inds)];
                        overlap_is_clump = [overlap_is_clump; cluster_info{t,2}(nr,is_clump_ind)];
                        
                        
                    end
                    
                    
                end
                
                
            else
                
                if l_red_cluster_is_clump
                    % for clump-spot comparison, just check if spot centroid is
                    % within clump
                    
                    this_red_crop_rect = cluster_info{t,2}(nr,crop_rect_inds);
                    this_red_zRange = cluster_info{t,2}(nr,z_range_inds);
                    
                    
                    lx = this_green_centroid(1) >= this_red_crop_rect(1) & this_green_centroid(1) <= this_red_crop_rect(1) + this_red_crop_rect(3);
                    ly = this_green_centroid(2) >= this_red_crop_rect(2) & this_green_centroid(2) <= this_red_crop_rect(2) + this_red_crop_rect(4);
                    lz = this_green_zRange(1) >= this_red_zRange(1) & this_green_zRange(1) <= this_green_zRange(2);
                    
                    l_overlap = lx & ly & lz;
                    
                    if l_overlap
                        overlap_ids = [overlap_ids; nr];
                        overlap_centroid = [overlap_centroid; cluster_info{t,2}(nr,centroid_inds)];
                        overlap_crop_rect = [overlap_crop_rect; this_red_crop_rect];
                        overlap_zRange = [overlap_zRange; this_red_zRange];
                        overlap_vol = [overlap_vol; cluster_info{t,2}(nr,vol_inds)];
                        overlap_inten = [overlap_inten; cluster_info{t,2}(nr,inten_inds)];
                        overlap_is_clump = [overlap_is_clump; cluster_info{t,2}(nr,is_clump_ind)];
                    end
                    
                else
                    
                    % spot-spot overlaps, do nothing for now
                    
                end
                
                
            end
            
            
        end
        
        %% assemble super cluster
        %overlap_centroid = [this_green_centroid; overlap_centroid];
        overlap_crop_rect= [this_green_crop_rect; overlap_crop_rect];
        overlap_zRange = [this_green_zRange; overlap_zRange];
        %overlap_inten = [this_green_inten; overlap_inten];
        overlap_is_clump = [l_green_cluster_is_clump; overlap_is_clump];
        
        out_red_inten = sum(overlap_inten(2:end));
        out_red_vol = sum(overlap_vol(2:end));
        out_isClump = sum(overlap_is_clump) > 0;
        
        % out crop rect
        right_rects = overlap_crop_rect(:,1) + overlap_crop_rect(:,3);
        out_crop_rect_3 = unique(overlap_crop_rect(right_rects==nanmax(right_rects),3));
        bottom_rects = overlap_crop_rect(:,2) + overlap_crop_rect(:,4);
        out_crop_rect_4 = unique(overlap_crop_rect(right_rects==nanmax(right_rects),4));
        
        if isempty(out_crop_rect_3)
            out_crop_rect_3 = NaN;
        end
        
        if isempty(out_crop_rect_4)
            out_crop_rect_4 = NaN;
        end
        
        out_crop_rect = [nanmin(overlap_crop_rect(:,1)), nanmin(overlap_crop_rect(:,2)), out_crop_rect_3, out_crop_rect_4];
        
        % out centroid
        out_red_centroid = sum(overlap_centroid.*repmat(overlap_inten,1,2),1)./sum(overlap_inten);
        
        if isempty(out_red_centroid)
            out_red_centroid = [NaN, NaN];
        end
        
        % out zrange, must now be a clump since we're ignoring spot-spot
        % overlap
        out_zRange = [nanmin(overlap_zRange(:,1)), nanmax(overlap_zRange(:,2))];
        
        counter = counter + 1;
        
        this_out_row = [counter, this_green_centroid, out_red_centroid, out_crop_rect, out_zRange, out_isClump, this_green_inten, out_red_inten, this_green_volume, out_red_vol];
        
        tmp_this_out_cluster_arr = [tmp_this_out_cluster_arr; this_out_row];
        
        
              
    end
    
    %% need to do final check to see if green clumps are now connected through red clumps
    
    this_out_cluster_arr = [];
    
    centroid_inds = [2:5];
    crop_rect_inds = [6:9];
    z_range_inds = [10:11];
    is_clump_ind = [12];
    inten_inds = [13,14];
    vol_inds = [15,16];
    
    counter = 0;
    
    for n = 1:size(tmp_this_out_cluster_arr,1)
        
        % is this cluster a clump?
        l_n_cluster_is_clump = tmp_this_out_cluster_arr(n,is_clump_ind);
        
        overlap_ids = [];
        overlap_centroid = [];
        overlap_crop_rect = [];
        overlap_zRange = [];
        overlap_vol = [];
        overlap_inten = [];
        overlap_is_clump = [];
        
        this_n_crop_rect = tmp_this_out_cluster_arr(n,crop_rect_inds);
        this_n_zRange = tmp_this_out_cluster_arr(n,z_range_inds);
        this_n_centroid = tmp_this_out_cluster_arr(n,centroid_inds);
        this_n_inten = tmp_this_out_cluster_arr(n,inten_inds);
        this_n_volume = tmp_this_out_cluster_arr(n,vol_inds);
        
        % loop through m clusters
        for m = 1:(n-1)
            
            % is this m cluster a clump?
            l_m_cluster_is_clump = tmp_this_out_cluster_arr(m,is_clump_ind);
            
            if l_n_cluster_is_clump
                
                
                if l_m_cluster_is_clump
                    
                    % for clump-clump comparisons, just look for overlapping
                    % crop_rects
                    
                    this_m_crop_rect = tmp_this_out_cluster_arr(m,crop_rect_inds);
                    this_m_zRange = tmp_this_out_cluster_arr(m,z_range_inds);
                    
                    %%%%%%%%%%%%%%% check corrrectness of x vs y %%%%%%%%%%%%%%
                    ly = this_n_crop_rect(2) >= this_m_crop_rect(2) & this_n_crop_rect(2) <= this_m_crop_rect(2) + this_m_crop_rect(4);
                    lx = this_n_crop_rect(1) >= this_m_crop_rect(1) & this_n_crop_rect(1) <= this_m_crop_rect(1) + this_m_crop_rect(3);
                    lz = this_n_zRange(1) >= this_m_zRange(1) & this_n_zRange(1) <= this_m_zRange(2);
                    
                    l_overlap = lx & ly & lz;
                    
                    if l_overlap
                        
                        ooverlap_ids = [overlap_ids; m];
                        overlap_centroid = [overlap_centroid; tmp_this_out_cluster_arr(m,centroid_inds)];
                        overlap_crop_rect = [overlap_crop_rect; this_m_crop_rect];
                        overlap_zRange = [overlap_zRange; this_m_zRange];
                        overlap_vol = [overlap_vol; tmp_this_out_cluster_arr(m,vol_inds)];
                        overlap_inten = [overlap_inten; tmp_this_out_cluster_arr(m,inten_inds)];
                        overlap_is_clump = [overlap_is_clump; tmp_this_out_cluster_arr(m,is_clump_ind)];
                        
                    end
                    
                else
                    % for clump-spot comparison, just check if spot centroid is
                    % within clump
                    
                    this_m_centroid = tmp_this_out_cluster_arr(m,centroid_inds);
                    this_m_zRange = tmp_this_out_cluster_arr(m,z_range_inds);
                    
                    lx = (this_m_centroid(1) >= this_n_crop_rect(1) & this_m_centroid(1) <= this_n_crop_rect(1) + this_n_crop_rect(3)) ...
                        | (this_m_centroid(3) >= this_n_crop_rect(1) & this_m_centroid(3) <= this_n_crop_rect(1) + this_n_crop_rect(3));
                    
                    ly = (this_m_centroid(2) >= this_n_crop_rect(2) & this_m_centroid(2) <= this_n_crop_rect(2) + this_n_crop_rect(4)) ...
                        | (this_m_centroid(4) >= this_n_crop_rect(2) & this_m_centroid(4) <= this_n_crop_rect(2) + this_n_crop_rect(4));
                    
                    lz = this_m_zRange(1) >= this_n_zRange(1) & this_m_zRange(1) <= this_n_zRange(2);
                    
                    l_overlap = lx & ly & lz;
                    
                    if l_overlap
                        overlap_ids = [overlap_ids; m];
                        overlap_centroid = [overlap_centroid; tmp_this_out_cluster_arr(m,centroid_inds)];
                        overlap_crop_rect = [overlap_crop_rect; this_m_crop_rect];
                        overlap_zRange = [overlap_zRange; this_m_zRange];
                        overlap_vol = [overlap_vol; tmp_this_out_cluster_arr(m,vol_inds)];
                        overlap_inten = [overlap_inten; tmp_this_out_cluster_arr(m,inten_inds)];
                        overlap_is_clump = [overlap_is_clump; tmp_this_out_cluster_arr(m,is_clump_ind)];
                        
                        
                    end
                    
                    
                end
                
                
            else
                
                if l_m_cluster_is_clump
                    % for clump-spot comparison, just check if spot centroid is
                    % within clump
                    
                    this_m_crop_rect = tmp_this_out_cluster_arr(m,crop_rect_inds);
                    this_m_zRange = tmp_this_out_cluster_arr(m,z_range_inds);
                    
                    
                    lx = (this_n_centroid(1) >= this_m_crop_rect(1) & this_n_centroid(1) <= this_m_crop_rect(1) + this_m_crop_rect(3)) ...
                        | (this_n_centroid(3) >= this_m_crop_rect(1) & this_n_centroid(3) <= this_m_crop_rect(1) + this_m_crop_rect(3));
                    
                    ly = (this_n_centroid(2) >= this_m_crop_rect(2) & this_n_centroid(2) <= this_m_crop_rect(2) + this_m_crop_rect(4)) ...
                        | (this_n_centroid(4) >= this_m_crop_rect(2) & this_n_centroid(4) <= this_m_crop_rect(2) + this_m_crop_rect(4));
                    
                    lz = this_n_zRange(1) >= this_m_zRange(1) & this_n_zRange(1) <= this_n_zRange(2);
                    
                    l_overlap = lx & ly & lz;
                    
                    if l_overlap
                        overlap_ids = [overlap_ids; m];
                        overlap_centroid = [overlap_centroid; tmp_this_out_cluster_arr(m,centroid_inds)];
                        overlap_crop_rect = [overlap_crop_rect; this_m_crop_rect];
                        overlap_zRange = [overlap_zRange; this_m_zRange];
                        overlap_vol = [overlap_vol; tmp_this_out_cluster_arr(m,vol_inds)];
                        overlap_inten = [overlap_inten; tmp_this_out_cluster_arr(m,inten_inds)];
                        overlap_is_clump = [overlap_is_clump; tmp_this_out_cluster_arr(m,is_clump_ind)];
                    end
                    
                else
                    
                    % spot-spot overlaps, do nothing for now
                    
                end
                
                
            end
            
            
        end
        
        %% assemble super cluster
        overlap_centroid = [this_n_centroid; overlap_centroid];
        overlap_crop_rect= [this_n_crop_rect; overlap_crop_rect];
        overlap_zRange = [this_n_zRange; overlap_zRange];
        overlap_inten = [this_n_inten; overlap_inten];
        overlap_is_clump = [l_n_cluster_is_clump; overlap_is_clump];
        overlap_vol = [this_n_volume; overlap_vol];
        
        out_green_inten = sum(overlap_inten(:,1));
        out_red_inten = sum(overlap_inten(:,2));
        out_green_vol = sum(overlap_vol(:,1));
        out_red_vol = sum(overlap_vol(:,2));
        
        out_isClump = sum(overlap_is_clump) > 0;
        
        % out crop rect
        right_rects = overlap_crop_rect(:,1) + overlap_crop_rect(:,3);
        out_crop_rect_3 = unique(overlap_crop_rect(right_rects==nanmax(right_rects),3));
        bottom_rects = overlap_crop_rect(:,2) + overlap_crop_rect(:,4);
        out_crop_rect_4 = unique(overlap_crop_rect(right_rects==nanmax(right_rects),4));
        
        if isempty(out_crop_rect_3)
            out_crop_rect_3 = NaN;
        end
        
        if isempty(out_crop_rect_4)
            out_crop_rect_4 = NaN;
        end
        
        out_crop_rect = [nanmin(overlap_crop_rect(:,1)), nanmin(overlap_crop_rect(:,2)), out_crop_rect_3, out_crop_rect_4];
        
        % out centroid
        out_red_centroid = sum(overlap_centroid(:,3:4).*repmat(overlap_inten(:,2),1,2),1)./sum(overlap_inten(:,2));
        out_green_centroid = sum(overlap_centroid(:,1:2).*repmat(overlap_inten(:,1),1,2),1)./sum(overlap_inten(:,1));
        
        % out zrange, must now be a clump since we're ignoring spot-spot
        % overlap
        out_zRange = [nanmin(overlap_zRange(:,1)), nanmax(overlap_zRange(:,2))];
        
        counter = counter + 1;
        
        this_out_row = [counter, out_green_centroid, out_red_centroid, out_crop_rect, out_zRange, out_isClump, out_green_inten, out_red_inten, out_green_vol, out_red_vol];
        
        this_out_cluster_arr = [this_out_cluster_arr; this_out_row];
        
        
              
    end
                
    
    cluster_info_out{t} = this_out_cluster_arr;
    
    
end    
    
    





end