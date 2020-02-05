    
function FastDLMwrite(filename,data,varargin)
    del = ';';
    format = '%f';
    switch length(varargin)
        case 1
        del = varargin{1};
        case 2
        del = varargin{1};
        format = varargin{2};
    end        
    
    ms  = permute( data, [ 2, 1 ] );
    fid = fopen(filename, 'a');
    format = [repmat(sprintf('%s%s',format,del),1,size(data,2)) '\n'];
    fprintf( fid, format, ms );
    fclose( fid );
end