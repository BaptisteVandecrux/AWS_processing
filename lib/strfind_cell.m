function index = strfind_cell(cell_array,str)
    IndexC = strfind(cell_array, str);
    index = find(not(cellfun('isempty', IndexC)));
end