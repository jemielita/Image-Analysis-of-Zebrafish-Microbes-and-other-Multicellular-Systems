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
    % September 11, 2015
    %
    % NOT DONE YET!!!
    
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
        
        
        function obj = appendFish(obj,species,f,varargin)
            
            % varargin can be a name for the fish
            if nargin == 3
                % if user doesn't provide a name, dig into the param file
                fname = f.param{1}.directoryName(end-4:end);
            elseif nargin==4
                fname = varargin{1};
            else
                disp('appendFish takes at most 3 arguments')
                return
            end
            
            % get the population time series
            switch species
                
                case 'vibrio'
                    pop = f.sH(:,1)+f.sL(:,1);
                case 'aero'
                    pop = f.sH(:,2)+f.sL(:,2);
                case 'aeromono'
                    pop = f.sH + f.sL;
            end
            
            
            % sometimes pop can contains exact zeros, not trusting those
            % for now
            startzeroindex = find(pop==0,1);
            if ~isempty(startzeroindex)
                pop=pop(1:startzeroindex-1);
                disp(strcat('Truncating ',fname,' time series due to zeros'));
            end

            % get collapse time and magnitude by calling external function
            [obj.(species).fish.(fname).scan, obj.(species).fish.(fname).mag] = getCollapseTimePointAndMag(pop);
            
            % store pop
            obj.(species).fish.(fname).pop = pop;
            
            % total time for this fish
            ttot = max(f.t);
            obj.(species).fish.(fname).totaltime = ttot;
            
            % prob per hour of collapse for this fish
            obj.(species).fish.(fname).prob = numel(obj.(species).fish.(fname).mag)/ttot;
            
            % append array of probs
            obj.(species).probs = [obj.(species).probs, obj.(species).fish.(fname).prob];
            
            % update average
            obj.(species).p = mean(obj.(species).probs);
            
            % update sigp
            obj.(species).sigp = std(obj.(species).probs);
            
            % update mags
            obj.(species).mags = [obj.(species).mags, obj.(species).fish.(fname).mag];
            
            % update meanf
            obj.(species).f = mean(obj.(species).mags);
            
            % update sigf
            obj.(species).sigf = std(obj.(species).mags);
            
            % update z
            obj.(species).z = obj.(species).p*log10(obj.(species).f);
            
            % update sigz
            obj.(species).sigz = sqrt(abs(log10(obj.(species).f))^2*(obj.(species).sigp)^2 + abs(obj.(species).p/obj.(species).f/log(10))^2*(obj.(species).sigf)^2);
        end
        
        function obj = remakeGlobalArraysFromLocal(obj,species)
            obj.(species).probs = [];
            obj.(species).mags = [];
            
            fishnames = fieldnames(obj.(species).fish);
            nfish = numel(fishnames);
            
            for i=1:nfish
                obj.(species).probs = [obj.(species).probs, obj.(species).fish.(fishnames{i}).prob];
                obj.(species).mags = [obj.(species).mags, obj.(species).fish.(fishnames{i}).mag'];
            end
        end
        
        function obj = updateModelParams(obj,species)
            
             % update average
            obj.(species).p = mean(obj.(species).probs);
            
            % update sigp
            obj.(species).sigp = std(obj.(species).probs);
            
            % update meanf
            obj.(species).f = mean(obj.(species).mags);
            
            % update sigf
            obj.(species).sigf = std(obj.(species).mags);
            
            % update z
            obj.(species).z = obj.(species).p*log10(obj.(species).f);
            
            % update sigz
            obj.(species).sigz = sqrt(abs(log10(obj.(species).f))^2*(obj.(species).sigp)^2 + abs(obj.(species).p/obj.(species).f/log(10))^2*(obj.(species).sigf)^2);

        end 
            
        % is this necessary?
        function obj = removeFieldAndUpdate(obj,species,structure,field2remove)
            obj.(species).(structure) = rmfield(obj.(species).(structure),field2remove);
            
            obj = obj.remakeGlobalArraysFromLocal(species);
            obj = obj.updateModelParams(species);
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