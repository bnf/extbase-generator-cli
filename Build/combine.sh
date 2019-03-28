#!/bin/bash

echo "#!/bin/bash" > t3x
echo >> t3x

for var in "$@"
do
	func=`basename $var .sh`
	echo "function ${func}() {" >> t3x
	sed '1d' $var >> t3x
	echo "}" >> t3x
	echo >> t3x
done

sed '1d' t3x.sh >> t3x

