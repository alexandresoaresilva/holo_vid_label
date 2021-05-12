function ax_ret = show_fr(app, I)
    persistent ax_holo_fr;
    persistent fig_holo_fr;
    
    
    if isempty(fig_holo_fr)
        fig_holo_fr = uifigure('Name', 'Hologram Frame');
    end
    if isempty(ax_holo_fr)
        [r,c] = size(I);
        ax_holo_fr = uiaxes(fig_holo_fr, 'Position', [1 1 r c]);
        ax_holo_fr.ButtonDownFcn = @ax_holo_fr_button_down;
    end
    imagesc(ax_holo_fr, I);
    ax_ret = ax_holo_fr;
    
    
end

function ax_holo_fr_button_down(app, event)
%     app.App_uifigure.KeyPressFcn = 
end


function uifigureKeyPress(app, event)
    key = event.Key;
    if strcmpi(key,'rightarrow')
        app.arrow_rightButtonPushed(true)
    elseif strcmpi(key, 'leftarrow')
        app.arrow_leftButtonPushed(true)
    elseif strcmpi(key, 'delete')
        app.del_bbox();
    end
end