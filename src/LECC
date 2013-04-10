#!/bin/bash

usage() { 
    echo "Usage: LECC -i <id number> -o <output prefix> -a <algorithm> [-s <selection method> -k <folds>]"
    echo "-i -o and -a are mandatory."
    echo "algorithm may be: lecc, leccm or int."
    echo "selection method is either percent of candidates to consider or 200 for two candidate method, if not specified the percent defaults to 100%"
    echo "folds, number of folds to run as kfold.  If not specified all data will be used for training and a single unprocessed/processed tree will be made" 
}

options="k:a:i:o:s:h" 
iset=false
oset=false
aset=false
selection=100
seltype=0
folds=1

while getopts $options option
do
    case $option in 
	h) usage; exit;;
	i) id=$OPTARG;iset=true;;
	o) pre=$OPTARG;oset=true;;
	a) 
	    case $OPTARG in
		lecc) alg=1;;
		leccm) alg=2;;
		int) alg=3;;
		*) echo "Invalid algorithm option" >&2; exit 1;;
	    esac
	    aset=true;;
	s)  selection=$OPTARG
	    if [ $selection -le 0 ]
	    then
		echo "Invalid selection value.  Must be greater than zero." >&2; usage; exit 1;
	    fi
	    if [ $selection -gt 100 -a $selection -ne 200 ]
	    then
		echo "Invalid selection value.  Must be between zero and one hundred or be two hundred." >&2; usage; exit 1;
	    fi;;
	k) folds=$OPTARG
	    if [ $folds -le 0 ]
	    then
		echo "Invalid fold value.  Number of folds must be greater than 0." >&2; usage; exit 1;
	    fi;;
	\? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        *  ) echo "Unimplimented option: -$OPTARG" >&2; exit 1;;
	esac
done

# Check to make sure at least algorithm, id and output are set
if  ! $iset || ! $aset || ! $oset
    then
    usage;
    exit 1;
fi

if [ $selection -lt 100 ]
then
    seltype=0
fi
if [ $selection -eq 200 ]
then
    seltype=2
fi

# Check to make sure no select for int
if [ $alg -eq 3 -a $selection -ne 100 ]
then
    echo "Int does not support candidate selection methods" >&2; exit 1;
fi

# Run the program
# If folds is 1 then run just a tree



if [ $folds -eq 1 ]
then
    ./treeScript $id $pre $alg $seltype $selection
else
    ./kFoldScript $folds $id $pre $alg $seltype $selection
fi
