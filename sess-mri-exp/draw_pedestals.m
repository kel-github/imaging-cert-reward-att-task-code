function [] = draw_pedestals(wh, positions, rect, sc, max_fg, bg)
    % DRAW_PLACEHOLDERS Draw the circular pedestals. Using the window
    % handle("wh") draw the top (positions == 1:2) and/or bottom 
    % (positions == 3:4) gaussian pedestals in the specified color.
    contrast = 0.1;
    rw = rect(3) - rect(1);
    rh = rect(4) - rect(2);
    [x, y] = meshgrid(1:rw, 1:rh);
    f = exp(-((x-rw/2).^2 + (y-rh/2).^2)/(2*sc^2));
%     noise_matrix = floor(((white-grey)*rand(rw, rh)) .* f) + grey;
    peak = (max_fg - bg) * contrast;
    pedestal_matrix = floor(peak .* f) + bg;
    tex = Screen('MakeTexture', wh, pedestal_matrix);
    xy_pos = get_positions(wh, positions);
    xy_diff = repmat([rw/2; rh/2], 1, size(xy_pos, 2));
    rects = [xy_pos - xy_diff; xy_pos + xy_diff];
    Screen('DrawTextures', wh, tex, [], rects, [], 0);    
end
