function [] = draw_targets( wh, gabor_id, gabor_rect, target, shift, hz, ...
                           contrast )
    % inputs
    % ---------------------------------------------------------------
    % wh          = window handle
    % gabor_id    = texture id for the gabor
    % gabor_rect  = where to present the gabors
    % target      = is the target on the left (1) or on the right (2)
    % shift       = shift of gabor, from cardinal axis
    % hz          = 0 = the target is not horizontal, 1 = the target is vertical 
    % contrast    = a vector of contrast values for the target to appear
    % (as many contrast values as there are targets)

    % Patch centre at 5 degree angle both horizontal and vertical.
    ppd = get_ppd();
    phase = 0;
    tilt = [0, 0];
    target_right = mod(target-1, 2);

    if target_right % KG to check that this flips the vertical stimulus on its axis and not the horizontal (i.e. does hz = 1 mean verticle?)
        tilt(1) = hz * 90;
        tilt(2) = shift + 180;
    else
        tilt(1) = shift;
        tilt(2) = hz * 270;
    end
    freq = 2.5 / ppd;
%     contrast = 0.5;
    sc = round(0.3 * get_ppd());
    gw = gabor_rect(3) - gabor_rect(1);
    gh = gabor_rect(4) - gabor_rect(2);
    % Get positions for gabors
    if target > 2
        positions_gabor = 3:4;
    else
        positions_gabor = 1:2;
    end
    xy_pos = get_positions(wh, positions_gabor);
    xy_diff = repmat([gw/2; gh/2], 1, size(xy_pos, 2));
    rects = [xy_pos - xy_diff; xy_pos + xy_diff];
    aux = repmat([phase+180, freq, sc, contrast(1), 1., 0, 0, 0]', [1, 2]);
    for i = 1:length(contrast)
        aux(4, i) = contrast(i);
        
    end
    Screen('DrawTextures', wh, repmat(gabor_id, [1, 2]), [], ...
           rects, tilt, [], [], [], [], kPsychDontDoRotation, aux);

end % function draw_targets
