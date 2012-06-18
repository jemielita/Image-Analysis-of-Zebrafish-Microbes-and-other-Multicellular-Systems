%Choose from a selection of projection types and output the result. This
%list will be expanded as necessary.

function im = selectProjection(varargin)


if(nargin==4)
    param = varargin{1};
    type = varargin{2};
    autoLoad = varargin{3};
    imVar = varargin{4};
end
if(nargin==6)
    param=varargin{1};
    type = varargin{2};
    autoLoad = varargin{3};
    imVar.scanNum = varargin{4};
    imVar.color = varargin{5};
    imVar.zNum = varargin{6};
end

switch lower(type)
    case 'mip'
        im = mipProjection(param,autoLoad, imVar);
        
end

end