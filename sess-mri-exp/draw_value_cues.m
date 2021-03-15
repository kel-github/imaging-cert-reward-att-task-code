function[] = draw_value_cues(wh, positions, colors, wdth, tgt_rect)
    % DRAW_VALUE_CUES Draw the circular value cues that sit under the place
    % holders. Using the window
    % handle("wh") draw the top (positions == 1:2) and/or bottom 
    % (positions == 3:4) circular placeholders.
    % tgt_rect is the rect in which the target gabor or distractor is
    % placed (1 x 4)
    ppd = get_ppd();
    radius = (tgt_rect(4)/2/ppd)*ppd; 
    xy_pos = get_positions(wh, positions);
    xy_diff = repmat([radius; radius], 1, size(positions, 2));
    rects = [xy_pos - xy_diff; xy_pos + xy_diff];
    Screen('FrameOval', wh, colors, rects, wdth*.75, wdth*.75);
end