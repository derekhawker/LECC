 
 % Takes a dectree(vector of Node structures)
function decTreeTextVisualizer(dectree)
    printNode(dectree, 1, 0);
    printf('\n');

end

function printNode(nodes, n, indent)
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

    printf('%sclass %d    pop %d/%d, %d/%d', ws, nodes(n).class, totalClass0, 
           sum(nodes(n).datapoints), totalClass1, sum(nodes(n).datapoints)); 
    if nodes(n).ldesc ~= -1 || nodes(n).rdesc ~= -1
        printf('     features [');
        printf('%d, ', nodes(n).featuresp);
        printf(']', nodes(n).featuresp);
    end

    printf(' costn ')
    printf('%f ', nodes(n).costn)

    printf('    mc=%d', nodes(n).numMisClassified);

    printf('\n');
    printNode(nodes, nodes(n).ldesc,indent+1)
    printNode(nodes, nodes(n).rdesc,indent+1)
end

