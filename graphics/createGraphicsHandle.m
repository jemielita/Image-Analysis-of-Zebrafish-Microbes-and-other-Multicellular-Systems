%createGraphicsHandle: Create a handle to an appropriate type of graphics
%object. Used for run-time creation of arbitrary graphics handles for gut
%image analysis

function userG = createGraphicsHandle(userG, imageRegion, fieldName, gType, newVal)

len = length(userG);
if(len==1)
    i = len;
else
    i = len+1;
end

userG(i).name = fieldName;
userG(i).type = gType;
userG(i).newVal = newVal;
userG(i).val = []; %Will be updated dynamically.
switch gType
    case 'point'
        h = impoint(imageRegion);
        
end
userG(i).handle = h;
set(userG(i).handle, 'Visible', 'on');

end