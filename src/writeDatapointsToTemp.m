% Feed instance data in matrix form where each row is the attributes with a 
% class given at the end
function writeDatapointsToTemp(instanceData, core = 1,filename="")

  switch(core)
	case(1)
	  fid = fopen('../datasets/temp/temp.data', 'w');
	case(2)
	  fid = fopen('../datasets/temp1/temp.data', 'w');
	case(0)
	  fid = fopen(filename,'w');
  end

    instanceData;
    size(instanceData);
    for m = 1:size(instanceData)(1)
        for n = 1:size(instanceData)(2)-1
            fprintf(fid, '%f ',instanceData(m, n));
        end
        fprintf(fid, '%d',instanceData(m, size(instanceData)(2)));
	fprintf(fid,'\n');
    end
    fclose(fid)
end

