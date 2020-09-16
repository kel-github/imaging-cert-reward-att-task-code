function [] = draw_placeholders(wh, positions, color)
    % DRAW_PLACEHOLDERS Draw the circular placeholders. Using the window
    % handle("wh") draw the top (positions == 1:2) and/or bottom 
    % (positions == 3:4) circular placeholders.
    ppd = get_ppd();
    radius = 1*ppd;
    xy_pos = get_positions(wh, positions);
    xy_diff = repmat([radius; radius], 1, size(positions, 2));
    rects = [xy_pos - xy_diff; xy_pos + xy_diff];
    Screen('FrameOval', wh, color, rects, 1, 1);
end

