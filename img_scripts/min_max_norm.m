function I_new = min_max_norm(I, lower_bound, upper_bound)
    if nargin < 2
        lower_bound = 0;
    end
    
    if nargin < 3
        upper_bound = 1;
    end
    
    I = double(I);
    min_I = min(I(:));
    max_I = max(I(:));
    I_new = (upper_bound - lower_bound).*(I - min_I)./(max_I - min_I) + lower_bound;
end