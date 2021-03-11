function do_fixation(wh, sess)
% inputs:
% wh = window handle
% sess = subject session structure
    white = sess.config.stim_light;
    grey = sess.config.grey;
    stim_dark = sess.config.stim_dark;
    gabor_rect = sess.config.gabor_rect;
    
    draw_pedestals(wh, 1:2, gabor_rect, 0.5 * get_ppd(), white, grey);
    draw_stim(wh, 1, [[white, white, white]',[white, white, white]']);
    draw_stim(wh, 0, stim_dark);
    
end
