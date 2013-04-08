function writeMisclassificationCostsToTemp(mc, core = 1, filename='')
  switch(core)
	case(1)
	  fid = fopen('../datasets/temp/temp.mc', 'w');
	case(2)
	  fid = fopen('../datasets/temp1/temp.mc', 'w');
	case(0)
	  fid = fopen(filename,'w');
  end
    fprintf(fid, '%f %f\n',mc(1), mc(2))
    fclose(fid)
end
