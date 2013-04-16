%Choose from a selection of projection types and output the result. This
%list will be expanded as necessary.

function im = selectProjection(varargin)

if(nargin==4)
    param = varargin{1};
    type = varargin{2};
    autoLoad = varargin{3};
    imVar = varargin{4};
end
if(nargin==7)
    param=varargin{1};
    type = varargin{2};
    autoLoad = varargin{3};
    imVar.scanNum = varargin{4};
    imVar.color = varargin{5};
    imVar.zNum = varargin{6};
    recalcProj = varargin{7};
end


im = calculateProjection(type);


    function imTot = calculateProjection(projType)
        colorNum =  find(strcmp(param.color, imVar.color));
        totNumRegions = size(param.regionExtent.XY{colorNum},1);
        
        imTot = zeros(param.regionExtent.regImSize{colorNum});
        
        if(strcmp(autoLoad, 'true'))
            if(isfield(param, 'dataSaveDirectory')&&recalcProj==false)
                
                if(exist([param.dataSaveDirectory filesep...
                        'FluoroScan_', num2str(imVar.scanNum), '_', imVar.color,'.tiff'],'file')==2)
                    
                    imTot = imread([param.dataSaveDirectory filesep...
                        'FluoroScan_', num2str(imVar.scanNum), '_', imVar.color,'.tiff']);
                          return
                end
            end
        end
        
        for nR=1:totNumRegions
            
            %Get the range of pixels that we will read from and read out to.
            xOutI = param.regionExtent.XY{colorNum}(nR,1);
            xOutF = param.regionExtent.XY{colorNum}(nR,3)+xOutI-1;
            
            yOutI = param.regionExtent.XY{colorNum}(nR,2);
            yOutF = param.regionExtent.XY{colorNum}(nR,4)+yOutI -1;
            
            xInI = param.regionExtent.XY{colorNum}(nR,5);
            xInF = xOutF - xOutI +xInI;
            
            yInI = param.regionExtent.XY{colorNum}(nR,6);
            yInF = yOutF - yOutI +yInI;
            
            fprintf(2, '.');

            switch projType
                case 'mip'
                    %See if individual regions exist as MIP. If so load
                    %these.
                    if(exist([param.dataSaveDirectory filesep...
                            'mip', imVar.color, '_R', num2str(nR), '_nS', num2str(imVar.scanNum)],'file')==2)
                        
                        mipR = imread([param.dataSaveDirectory filesep...
                            'mip', imVar.color, '_R', num2str(nR), '_nS', num2str(imVar.scanNum)]);
                    else
                        fprintf(1, 'Calculating MIP projection.');
                        %Use a different data type for maximum inten.
                        %projections and total inten. projections. The latter
                        %will need more memory than the former, since the
                        %greatest intensity any pixel will have is the pixel
                        %range of our camera: 16 bit.
                        im = load3dVolume(param, imVar, 'single', nR);
                        mipR = max(im,[],3); %Get the maximum intensity projection for this region
                    end
                case 'total'
                    im = load3dVolume(param, imVar, 'single', nR, 'dataType', '32bit');
                    mipR = sum(im,3);
            end
            
            mipR = double(mipR);
            
            
            %imTot(xOutI:xOutF, yOutI:yOutF) = mipR + imTot(xOutI:xOutF, yOutI:yOutF);
                        imTot(xOutI:xOutF, yOutI:yOutF) = mipR ;
        end
        
%         for regNum = 2:totNumRegions
%             %Overlapping regions
%             %This is potentially slow (however we need to be as quick as possible with this type of thing).
%             %After we know this code works, we'll come back and write quicker code.
%             imTot(param.regionExtent.overlapIndex{colorNum,regNum-1} )= ...
%                 0.5*imTot(param.regionExtent.overlapIndex{colorNum,regNum-1});
%             %    im(:) =1;
%             %   im(param.regionExtent.overlapIndex{regNum-1} ) = 0;
%             
%         end
        
        
    end

end