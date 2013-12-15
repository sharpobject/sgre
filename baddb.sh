mkdir db
foo="0123456789abcdef"
for (( i=0; i<${#foo}; i++ )); do
  for (( j=0; j<${#foo}; j++ )); do
    mkdir "db/${foo:$i:1}${foo:$j:1}"
  done
done
if [ ! -f db/users ]; then
    echo "{}" > db/users
fi