function [X_out,ind_start, ind_end] = longest_nonnan_period(X)
    H = hankel(X);
    C = cumsum(~isnan(H),2);

    threshold = 1;
    T = C<=threshold;
    [~,idx]=sort(T,2);
    lastone=idx(:,end)';

    lengths = length(X):-1:1;
    real_length = min(lastone,lengths);
    [max_length,max_idx] = max(real_length);

    selected_max_idx = max_idx(1);
    X_out = H(selected_max_idx, 1:max_length);
    ind_start = selected_max_idx;
    ind_end = ind_start + max_length-1;
end