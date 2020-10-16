function el=initialise_eyes(wh)

% initialise EYE TRACKER
    el=EyelinkInitDefaults(wh);
    if ~EyelinkInit(0, 1)
        fprintf('Eyelink Init aborted.\n');
        cleanup;  % cleanup function
        return;
    end

end