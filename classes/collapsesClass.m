classdef collapsesClass
    
    % class for analyzing collapse statistics and comparing to models
    %
    % Structre:  collapses -> species -> fish -> collapse info for that
    % fish.  Info is collected under each species as well.  Since
    % fishAnalysis files can be huge, this class is written with the idea
    % of adding fish info one at a time, rather than passing multiple
    % fishClasses at once.  For batch updating, load fish files and write a script.
    %
    % Basic Usage:
    %           cl = collapseClass(optional names)
    %           cl = cl.appendFish('species',fish,'optional name');
    %
    % Warnings: (1) Be careful not to overwrite fish when using appendFish.
    %           When a name isn't provided, appendFish takes the name
    %           'fish#' out of the param file, so if fish from multiple
    %           experiments are being appended, there might be doubles,
    %           i.e. multiple 'fish2's.
    %
    %           (2) appendFish calls the external function getCollapseTimePointAndMag.m.
    %
    % Info Stored:  collapse times; collapse magnitudes; means and standard
    %               deviations of both; z=p*log10(f); population time
    %               series; total time for each fish;
    %
    % Brandon Schloman
    % September 11, 2015:  First version 
    % September 17, 2015:  -1dDistribution function added 
    %                      -Expanded for option (now default) to 
    %                       calculate everything for both
    %                       vibrio and aero
    % 
    % Work in progress
    
    properties
        savedir = '';
        savename = '';
        aero = struct();
        aeromono = struct();
        vibrio = struct();
        
    end
    
    methods
        
        function obj = collapsesClass(varargin)
            if(nargin == 0)
                obj.savedir = pwd;
                obj.savename = 'cl';
            elseif(nargin==1)
                obj.savedir = pwd;
                obj.savename = varargin{1};

            elseif(nargin == 2)
                obj.savedir = varargin{2};
                obj.savename = varargin{1};
            else
                disp('collapsesClass takes at most 2 arguments')
                return
            end
            
            % maybe make species and fish classes one day?  currently seems
            % unnecessary
            obj.aero.probs = [];
            obj.aero.mags = [];
            obj.aero.fish = struct;
            
            obj.aeromono.probs = [];
            obj.aeromono.mags = [];
            obj.aeromono.fish = struct;
            
            obj.vibrio.probs = [];
            obj.vibrio.mags = [];
            obj.vibrio.fish = struct;
            
        end
        
        
        function obj = appendFish(obj,f,varargin)
            
            % varargin can incluce:
            %   varargin{1} = 'species'
            %   varargin{2} = optional name
            if nargin == 1
                disp('appendFish needs a fish!')
                return
                
            elseif nargin == 2
                species  = 'both';

                fname = f.param{1}.directoryName(end-4:end);
                
            elseif nargin == 3
                species = varargin{1};
                % if user doesn't provide a name, dig into the param file
                fname = f.param{1}.directoryName(end-4:end);
                
            elseif nargin==4
                species = varargin{1};
                fname = varargin{2};
                
            else
                disp('appendFish takes at most 3 arguments')
                return
                
            end
            
            %get the spatial distributions
            obj = obj.update1dDists(f,fname,species);

            
            % get the population time series
            switch species
                
                case 'both'
                    species = {'vibrio','aero'};
                    pop = [f.nL(:,1), f.sH(:,2)+f.sL(:,2)];
                case 'vibrio'
                    pop = f.nL(:,1);
                    species = {species};
                case 'aero'
                    species = {species};
                    pop = f.sH(:,2)+f.sL(:,2);
                case 'aeromono'
                    species = {species};
                    pop = f.sH + f.sL;
            end
            
            nspecies = size(pop,2);
            
            % preallocate arrays
            for o = 1:nspecies
                obj.(species{o}).fish.(fname).mag = [];
                obj.(species{o}).fish.(fname).prob = [];
                obj.(species{o}).fish.(fname).scan = [];
            end
            
            % sometimes pop can contains exact zeros, not trusting those
            % for now
            startzeroindex = zeros(1,nspecies);
            
            % big loop over species to update both aero and vibrio with one
            % call.  Why not?
            for i = 1:nspecies
                
                if ~isempty(find(pop(:,i)==0,1))
                    startzeroindex(i) = find(pop(:,i)==0,1);
                end
                
                if ~isempty(startzeroindex)
                    
                    thispop = pop(1:startzeroindex(i)-1,i);
                    disp(strcat('Truncating ',fname,' time series due to zeros'));
                    
                end
                
               % store pop
                obj.(species{i}).fish.(fname).pop = thispop;
                
                % get collapse time and magnitude by calling external function
                [obj.(species{i}).fish.(fname).scan, obj.(species{i}).fish.(fname).mag] = getCollapseTimePointAndMag(thispop);
            
              
                
                % total time for this fish
                ttot = max(f.t);
                obj.(species{i}).fish.(fname).totaltime = ttot;
                
                % prob per hour of collapse for this fish
                obj.(species{i}).fish.(fname).prob = numel(obj.(species{i}).fish.(fname).mag)/ttot;
                
                % assemble global arrays and calculate params
                obj = obj.remakeGlobalArraysFromLocal(species{i});
                obj = obj.updateModelParams(species{i});
                
               
            end
        end
        
        function obj = remakeGlobalArraysFromLocal(obj,varargin)
            
            if nargin == 1
                species = {'vibrio','aero'};
                nspecies = 2;
            elseif nargin == 2
                species = {varargin{1}};
                if strcmp(species,'both') == 1
                    species = {'vibrio','aero'};
                end
                nspecies = numel(species);
            else
                disp('remakeGlobalArraysFromLocal takes at most a species argument')
            end
            
            for j = 1:nspecies
                obj.(species{j}).probs = [];
                obj.(species{j}).mags = [];
                
                fishnames = fieldnames(obj.(species{j}).fish);
                nfish = numel(fishnames);
                
                for k=1:nfish
                    obj.(species{j}).probs = [obj.(species{j}).probs, obj.(species{j}).fish.(fishnames{k}).prob];
                    obj.(species{j}).mags = [obj.(species{j}).mags, obj.(species{j}).fish.(fishnames{k}).mag'];
                end
                
            end
        end
        
        function obj = updateModelParams(obj,varargin)
            
            if nargin == 1
                species = {'vibrio','aero'};
            elseif nargin == 2
                species = {varargin{1}};
            end
            
            nspecies = numel(species);
            
            for n=1:nspecies
                % update average
                obj.(species{n}).p = mean(obj.(species{n}).probs);
                
                % update sigp
                obj.(species{n}).sigp = std(obj.(species{n}).probs);
                
                % update meanf
                obj.(species{n}).f = mean(obj.(species{n}).mags);
                
                % update sigf
                obj.(species{n}).sigf = std(obj.(species{n}).mags);
                
                % update z
                obj.(species{n}).z = obj.(species{n}).p*log10(obj.(species{n}).f);
                
                % update sigz
                obj.(species{n}).sigz = sqrt(abs(log10(obj.(species{n}).f))^2*(obj.(species{n}).sigp)^2 + abs(obj.(species{n}).p/obj.(species{n}).f/log(10))^2*(obj.(species{n}).sigf)^2);
            end
        end 
            
        function obj = removeFieldAndUpdate(obj,species,structure,field2remove)
            
            if strcmp(species,'both')==1
                species = {'vibrio','aero'};
            elseif strcmp(species,'aero') == 1 || strcmp(species,'vibrio') == 1
                species = {species};
            else
                disp('invalid species in removeFieldAndUpdate')
            end
                    
            nspecies = numel(species);
            for l = 1:nspecies
                obj.(species{l}).(structure) = rmfield(obj.(species{l}).(structure),field2remove);
                
                obj = obj.remakeGlobalArraysFromLocal(species{l});
                obj = obj.updateModelParams(species{l});
            end
        end
        
        function obj = update1dDists(obj,f,fname,varargin)
            % keep track of 1d distributions of bacteria in gut.
            % Potentially interesting to look for signatures of collapse
            % and as a property to track during response to perturbations.
            
            if nargin == 3
                species = {'vibrio','aero'};
                nc = [1,2];
                
            elseif nargin == 4
                species = varargin{1};
                switch species
                    case 'both'
                        nc = [1,2];
                        species = {'vibrio','aero'};
                    case 'vibrio'
                        nc = 1;
                        species = {species};
                    case 'aero'
                        nc = 2;
                        species = {species};
                    case 'aeromono'
                        nc = 1;
                        species = {species};
                end
            else
                disp('wrong number of inputs in update1dDists')
            end
            
            
            nspecies = numel(nc);
            nscans = f.totalNumScans;
            nslicesmax = zeros(1,nspecies);
            
            for m = 1:nspecies
                nslicesmax(m) = 0;
                
                % maybe not the best way to do this, but will loop through
                % scans to find the length of the largest gut partition and use
                % that to preallocate the array of 1d distributions.
                for ns = 1:nscans
                    ny = numel(f.scan(ns,nc(m)).lineDist);
                    if ny > nslicesmax(m)
                        nslicesmax(m) = ny;
                    end
                end
                
                % preallocate
                obj.(species{m}).fish.(fname).lineDist = zeros(nscans,nslicesmax(m));
                
                % loop through and assign each distribution to a row in a
                % matrix
                for ns = 1:nscans
                    thisnslices = numel(f.scan(ns,nc(m)).lineDist);
                    for slicenum = 1:thisnslices
                        obj.(species{m}).fish.(fname).lineDist(ns,1:thisnslices) = f.scan(ns,nc(m)).lineDist';
                    end
                end
            
            end
            
        end
            
            
        
        function save(obj)
            cl = obj;
          
            if(~isdir(obj.savedir))
                mkdir(obj.savedir);
            end
            
            % in case savedir was copied with a '\' at the end, must be
            % consistent
            if obj.savedir(end) == filesep
                obj.savedir = obj.savedir(1:end-1);
            end
            
            save(strcat(obj.savedir,filesep,obj.savename),'cl');
            
         end
            

            
    end
    
end