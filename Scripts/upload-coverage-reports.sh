#!/bin/bash -l
set -ex

IFS=','; PLATFORMS=$(echo $1); unset IFS

for PLATFORM in $PLATFORMS; do
	# Skip uploading coverage reports for watchOS targets.
	if [[ $PLATFORM == watchOS_* ]]; then
		continue
	fi

	bash <(curl -s https://codecov.io/bash) -J '^Valet$' -D .build/derivedData/$PLATFORM -t 5165deef-da9c-443d-90ea-bb0620bffe44
done
