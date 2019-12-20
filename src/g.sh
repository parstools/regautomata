#!/bin/bash
FILES=out*.dot
for f in $FILES
do
  echo $f
  dot -Tpng $f -o $f.png
done