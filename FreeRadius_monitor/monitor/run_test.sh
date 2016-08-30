#!/bin/bash

start=$(( `date -u +%s%N`))
resp=$(radtest testuser 123456Aa 127.0.0.1 1812 testing123 >aaa.txt 2> temp.txt)
end=$(( `date -u +%s%N`))
diff=$(($end-$start))
seconds=$(echo "scale=3;$diff/1000000000" | bc )

if grep -q Access-Accept <aaa.txt; then
    echo "accepted"
    rm aaa.txt
elif grep -q Access-Reject <aaa.txt; then
    echo "rejected"
    rm aaa.txt
elif grep -q "radclient: no response" <temp.txt; then
    echo "dead"
    rm temp.txt
fi
