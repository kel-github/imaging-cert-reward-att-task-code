function [] = run_masking_instructions(wh, gabor_rect, white, grey, glb_alph, task)    

    Screen('TextStyle', wh, 1);
    Screen('TextSize', wh, 30); 
    instructions = ...
        sprintf(['Well done! From now, the target After the targets \n' ...
                 'are presented, the two possible\n'...
                 'positions will be masked.\n\n'...
                 'Press a key now to see the masks.\n']);
    DrawFormattedText(wh, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', wh);
    start_ts = KbWait;

    WaitSecs(0.5);
    draw_masks(wh, gabor_rect, 10, white, grey, glb_alph);
    Screen('Flip', wh);

    start_ts = KbWait;
    WaitSecs(0.5);
    instructions = ...
        sprintf(['It is very important that you keep your eyes fixed\n'...
                 'on the cross in the middle of the screen at all\n'...
                 'times.\n\n'...
                 'Press a key to continue.']);
    DrawFormattedText(wh, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', wh);
 
    start_ts = KbWait;
    WaitSecs(0.5);
    
    instructions = ...
        sprintf(['Press %s for clockwise and %s for counterclockwise.\n'...
                 'Press any key to start\n'], ...
                KbName(task.responses(1)), KbName(task.responses(2)));
    DrawFormattedText(wh, instructions, 'Center', 'Center', white, 115);
    Screen('Flip', wh);

    WaitSecs(0.5);
    start_ts = KbWait;
end