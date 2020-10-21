function [] = check_dist(x, y, xc, yc, r, fid)

    if ~isempty(x)
            
        dist = sqrt((xc-x)^2 + (yc-y)^2);
        flag = dist > r;
        if isnan(x)
            flag = 1;
        end
        fprintf(fid, '%d\t%d\t%d\t%d\t%f\t%f\n', x, y, xc, yc, dist, flag);
    end
end