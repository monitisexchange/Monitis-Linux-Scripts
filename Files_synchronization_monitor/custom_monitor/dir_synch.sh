#!/bin/bash

#read argument; in this case the monitoring folders paths
while getopts "d:h" opt;
do
        case $opt in
        d) dirs=$OPTARG ;;
        h) echo "Usage: $0 -d <directoy path> "; exit 0 ;;
        *) echo "Wrong parameter received"
           exit 4
         ;;
        esac
done

resp=""

#separate the each folder path
sList=($(echo $dirs | sed -e 's/.\/\/./\n/g' | while read line; do echo $line | sed 's/[\t ]/.\/\/./g'; done))

for (( i = 0; i < ${#sList[@]}; i++ ))
do
  sList[i]=$(echo ${sList[i]} | sed 's/.\/\/./ /g') #a folder path

  dir=${sList[i]} 
  IFS='
  '
  array=(`ls $dir -1`) # get names of all files, includes also filenames containig whitespaces
  len=${#array[*]}
  for ((k=0; k<$len; k++))
  do
    temp=${array[$k]}
      if [[ ! -d "${temp}" ]]
      then #exclude directories
         file=$dir"/"$temp
         chkSum=$(cksum "$file" | awk '{ print $1 }')   
         resp+="$temp/$chkSum" #add a file/checksum pair to response
		 if [[ $k -lt $(( $len - 1 )) ]]
		 then
           resp+="//"
		 fi
      fi
  done
  if [[ $i -lt $(( ${#sList[@]} - 1 )) ]]
  then
    resp+="///"
  fi
  echo $resp > ./temp.txt
done
echo `cat ./temp.txt`


