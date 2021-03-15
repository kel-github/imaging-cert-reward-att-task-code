function do_fixation(wh, sess)
% inputs:
% wh = window handle
% sess = subject session structure
    white = sess.config.stim_light;
    grey = sess.config.grey;
    black = sess.config.black;
    stim_dark = sess.config.stim_dark;
    gabor_rect = sess.config.gabor_rect;
    vc_pwidth = 80; % pen width of value cues
    
    draw_pedestals(wh, 1:2, gabor_rect, 0.5 * get_ppd(), white, grey);
    draw_borders(wh, 1:2, black, vc_pwidth, gabor_rect);
    draw_value_cues(wh, 1:2, stim_dark, vc_pwidth, gabor_rect);
    draw_stim(wh, 1, [[white, white, white]',[white, white, white]']);
    draw_stim(wh, 0, stim_dark);
    
end
