%Class containing analysis tools for looking at results from peristalsis
%data

classdef pivanalysis
    properties
       
        %Angle to rotate result from piv to deal with velocity propagation
        angle = 0;
        
        
        %Results from gutMotility.m
        gutMesh = '';
        gutMeshVels ='';
        gutMeshVelsPCoords = '';
        mSlopes = '';
        thetas = '';
        
        freq = '';
        
        fps = 5;
        
        %Frequency range we will calculate our spectra over (basically low
        %frequency stuff).
        freqRange = 0.001:0.001:0.2;
        avgSpectra = []; %Mean and st deviation of spectra down the length of the gut
        avgNormSpectra = [];%Mean and st deviation of spectra down the length of the gut, normalizing each of the time traces for each box down the length of the gut.
        powerAll = [];
        ydist = [];%Distance anterior of the vent that this analysis began.
        
        peakArea = []; %Area under peak and frequency location of all peaks
        filename = '';
    end
    
    
    methods
        function obj = pivanalysis(imPath)
           %Load in our piv analysis 
           cd(imPath)
           aGDName = rdir('**\analyzed*.mat');
           inputVar = load(aGDName(1).name);
           
          var = {'gutMesh','gutMeshVels','gutMeshVelsPCoords',...
              'mSlopes','thetas'};
           for i=1:length(var)
              obj.(var{i}) = inputVar.(var{i}); 
           end
           
           cd ..
        end
        
        
        function obj = dispDisplacements(obj)
          
            nV=size(obj.gutMeshVels,1);
            nU=size(obj.gutMeshVels,2);
            nT=size(obj.gutMeshVels,4);
            totalTimeFraction=1;
            time=1/obj.fps:1/obj.fps:nT/(obj.fps*totalTimeFraction);
            markerNum=1:nU;

            im=squeeze(mean(obj.gutMeshVelsPCoords(:,:,1,1:end),1));
           
            h = fspecial('gaussian', [2 10], 2);
           im =imfilter(im,h); 
            
            figure;
            surf(time,markerNum,im,'LineStyle','none');
            colormap('Jet');
            %caxis([-numSTD*stdFN,numSTD*stdFN]);
            
            title('Longitudinal velocities down the gut','FontSize',12,'FontWeight','bold');
            xlabel('Time (s)','FontSize',20);
            ylabel('Marker number','FontSize',20);
            
        end
        
        
        function obj = calcSpectra(obj)
            im=squeeze(mean(obj.gutMeshVelsPCoords(:,:,1,1:end),1));
            
            x = nansum(im,1);
            fs = 5;
         
            obj.freq = [pxx, f];
        end
        
        function obj = calcAvgNormalizedSpectra(obj)
            %Calculate the spectra for each box down the length of the gut,
            %normalizing each of these traces to unity
            %and then taking the average
          for i = 1:size(obj.gutMeshVelsPCoords,2)
                x = mean(obj.gutMeshVelsPCoords(:,i,1,:));
                x = squeeze(x);
                
                %Normalizing signal
                x = x/sum(x);
                
                [pxx,~] = periodogram(x,hanning(length(x)),obj.freqRange,obj.fps);
                
                %Not saving the result to the class structure.
                if(i==1)
                    %On first round preallocate memory
                    powerAllNorm = zeros(size(obj.gutMeshVelsPCoords,2),length(pxx));
                end
                powerAllNorm(i,:) = pxx;
                fprintf(1,'.');
            end
            fprintf(1,'\n');
            
            obj.avgNormSpectra = [mean(powerAllNorm,1); std(powerAllNorm,1)];
           
        end
        
        function obj = calcAvgSpectra(obj)  
            %Calculate the spectra for each box down the length of the gut
            %and then take the average
         
            for i = 1:size(obj.gutMeshVelsPCoords,2)
                x = mean(obj.gutMeshVelsPCoords(:,i,1,:));
                x = squeeze(x);
                [pxx,f] = periodogram(x,hanning(length(x)),obj.freqRange,obj.fps);
                
                if(i==1)
                    %On first round preallocate memory
                    obj.powerAll = zeros(size(obj.gutMeshVelsPCoords,2),length(pxx));
                end
                obj.powerAll(i,:) = pxx;
                fprintf(1,'.');
            end
            fprintf(1,'\n');
            
            %Overwrite obj.freqRange with the appropriate one for calls to
            %DFFT.
            obj.freqRange = f; %Note: f doesn't change between calls to periodogram.
            
            obj.avgSpectra = [mean(obj.powerAll,1); std(obj.powerAll,1)];
           
        end
        
        function obj = calcPeaks(obj)
           %Find peaks in the power spectrum and calculate their
           %contribution to signal (area at FWHM).
           
           [pks, locs] = findpeaks(obj.avgSpectra(1,:), obj.freqRange);
           
           
           %Find full width at half maximum
           fitwidth = 5;
           for i=1:length(locs)
               ind = find(obj.freqRange==locs(i));
               
               %If we're close to the border
               if(ind-fitwidth<1)
                    obj.peakArea(i,1) = 0;
                    obj.peakArea(i,2) = 0;
                   continue
               end
               if(ind+fitwidth>length(obj.freqRange))
                    obj.peakArea(i,1) = 0;
                    obj.peakArea(i,2) = 0;
                   continue
               end
               
               
               x = obj.freqRange(ind-fitwidth:ind+fitwidth); 
               y = obj.avgSpectra(1,ind-fitwidth:ind+fitwidth);
               
               %Only keeping values that are strictly less than the peak
               rem = zeros(length(y),1);
               
               for j=1:fitwidth
                   if(y(j)>y(j+1))
                       rem(j) = 1;
                   end               
               end
               for j=0:fitwidth-1
                   if(y(end-j)>y(end-j-1))
                       rem(end-j) = 1;
                   end
                   
               end
               rem = logical(rem);
               x(rem) = [];
               y(rem) = [];
               
               
               f = fit(x.',y.','gauss1');
               %Calculate the area under the curve up until the FWHM
               func = @(x,c,a)a*exp(-(x/c).^2);
               a = 2* integral(@(x)func(x,f.c1, f.a1),0, f.c1*sqrt(log(2)));
               
               obj.peakArea(i,1) = locs(i);
               obj.peakArea(i,2) = a;
           end
           
           %Remove zeros and sort
           ind = find(obj.peakArea(:,1)==0);
           obj.peakArea(ind,:) = [];
           
           [~,ind] = sort(obj.peakArea(:,2),1,'ascend');
           obj.peakArea = obj.peakArea(ind,:);
           
        end
        
        
        
        function dispSpectra(obj)
            figure;
            plot(obj.freqRange, obj.avgSpectra(1,:)); hold on;
           % plot(f,pxxc,'r--','linewidth',2);
          
            xlabel('Hz'); 
           
            %set(gca, 'YScale', 'log'); 
        end
        
        function obj = temp(obj)
            
        end
        
        function obj = save(obj)
            piv = obj;
            save(obj.filename, 'piv');
        end
        
    end
    
end