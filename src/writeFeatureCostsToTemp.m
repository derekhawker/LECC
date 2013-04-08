function writeFeatureCostsToTemp(fc, core = 1, filename="")
  switch(core)
	case(1)
	  fid = fopen('../datasets/temp/temp.fc', 'w');
	case(2)
	  fid = fopen('../datasets/temp1/temp.fc', 'w');
	case(0)
	  fid = fopen(filename,'w');
  end

    for n = 1:size(fc)(2)-1
        fprintf(fid, '%f ',fc(n))
    end
    fprintf(fid, '%f',fc(size(fc)(2)))
    fprintf(fid, '\n')

    fclose(fid)
end
