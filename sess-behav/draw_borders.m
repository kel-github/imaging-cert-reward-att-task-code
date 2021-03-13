function [] = draw_borders(wh, positions, black, wdth, tgt_rect)
    % draw black borders around the edge of the placeholder/value cues
    % this makes sure that the square grey textures on which the targets are
    % presented blend into the display
    
    ppd = get_ppd();
    radius = ((tgt_rect(4)/2/ppd)+(wdth/ppd))*ppd; 
    xy_pos = get_positions(wh, positions);
    xy_diff = repmat([radius; radius], 1, size(positions, 2));
    rects = [xy_pos - xy_diff; xy_pos + xy_diff];
    Screen('FrameOval', wh, black, rects, wdth, wdth);
end