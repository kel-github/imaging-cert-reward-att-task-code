function [] = run_task_instructions(wh, white, task)


    Screen('TextStyle', wh, 1);
    Screen('TextSize', wh, 80);
    instructions = ...
        sprintf(['Be accurate, speedy and \n', ...
                 'win lots of points! : ) \n\n',...
                 'Press %s for clockwise and\n %s for counterclockwise.\n'], KbName(task.responses(1)), KbName(task.responses(2)));
    DrawFormattedText(wh, instructions, 'Center', 'Center', white, 115);
   
end

