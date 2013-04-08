% takes a string for the file location of pruned.out/unpruned.out
function decTreeTextFile(dectree, file)
    fid = fopen(file,'w');
    printNode(dectree, 1, 0, fid);
    fprintf(fid,'\n');
    fclose(fid);

end

function printNode(nodes, n, indent, fid)
    if n == -1
        return
    end

    ws = repmat([' '],1,indent*4);
    if nodes(n).class == 0
        totalClass0 = sum(nodes(n).datapoints)-nodes(n).numMisClassified;
        totalClass1 =  nodes(n).numMisClassified;
    elseif nodes(n).class == 1
        totalClass1 = sum(nodes(n).datapoints)-nodes(n).numMisClassified;
        totalClass0 =  nodes(n).numMisClassified;
    else
        totalClass0 = 0;
        totalClass1 = 0;
    end

    fprintf(fid, '%sclass %d    pop %d/%d, %d/%d', ws, nodes(n).class, totalClass0, sum(nodes(n).datapoints), totalClass1, sum(nodes(n).datapoints)); 
    if nodes(n).ldesc ~= -1 || nodes(n).rdesc ~= -1
        fprintf(fid,'     features [');
        fprintf(fid,'%d, ', nodes(n).featuresp);
        fprintf(fid,']', nodes(n).featuresp);
    end
    fprintf(fid,' costn ')
    fprintf(fid,'%f ', nodes(n).costn)
    fprintf(fid,'\n');
    printNode(nodes, nodes(n).ldesc,indent+1,fid)
    printNode(nodes, nodes(n).rdesc,indent+1,fid)
end

