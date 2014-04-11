%updateGraphicsHandle: Update which user definable graphics are being
%displayed.

function userG = updateGraphicsHandle(userG, scanNum, scanNumPrev, colorNum)

b = 0;

for i=1:length(userG)
    %For every specific type of graphics that we're updating and every
    %handle update the saved data
    if(strcmp(userG(i).visible, 'on'))
        userG(i) = updateG( userG(i), scanNumPrev, colorNum);
    end
    
end


end

function ug = updateG(ug, scanNumPrev, colorNum)

for h=1:length(userG.handle)
    v = iptgetapi(ug.handle(h));
    
    ug.val(scanNumPrev, colorNum){h} = v.getPosition();

    switch ug.newVal
        case 1
            set(ug.handle(h), 'Visible', 'off');
        
        case 0
            set(ug.handle(h), 'Visible', 'on');
    end
            

end



end