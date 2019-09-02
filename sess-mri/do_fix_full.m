function do_fix_full(wh, sess, col_map, cue)
    
    % inputs:
    % wh             = window handle
    % sess           = subject session structure
    % col_map        = 3 (r,g,b) x 2 (n locations) mapping of colours to
    % left vs right, can be -1 when reward = 2

    white = sess.config.stim_light;
    grey = sess.config.grey;
    gabor_rect = sess.config.gabor_rect;
    cue_colour = white;
    vc_pwidth = 80; % pen width of value cues
    
    value_cue_colour = col_map;
    draw_pedestals(wh, 1:2, gabor_rect, 0.5 * get_ppd(), white, grey);
    draw_value_cues(wh, 1:2, value_cue_colour, vc_pwidth, gabor_rect);
    draw_stim(wh, cue, [cue_colour(:,1) cue_colour(:,1)]);
end

