#!/bin/bash
grep "FOLLOWER_CARD" en_cardData.xml | grep -o ".SKILL_NUMBER_1.*/SKILL_TYPE_3." | sed 's/<\/SKILL_.\{4,6\}_.><SKILL_.\{4,6\}_.>/ /g' | sed 's/<SKILL_NUMBER_1>//' | sed 's/<.*>//' | awk '{print $1, $4, "\n", $2, $5, "\n", $3, $6'} | sed 's/^ *//' | sed 's/ *$//' | sort | uniq | sed 's/ /]=/' | sed 's/^/[/' | sed 's/$/,/'
