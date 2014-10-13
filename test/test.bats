#!/usr/bin/env bats

###
# goldfishのテスト
###

setup(){
	NOW=`date +%y%m%d%H%M%S`
	cd `dirname $0`
	cd ../config/sites
	for FILE in *.json; do
		mv ${FILE} ${FILE}.bak
	done

	echo '{id:"test'${NOW}'",url:"http://example.com"' > ${NOW}.json
}

teardown(){
	cd `dirname $0`
	cd ../config/sites
	for FILE in *.json; do
		mv ${FILE}.bak ${FILE}
	done
	rm ${NOW}.json
}

@test "一回目の実行時はメールが送信される"{
	run ../goldfish.sh
	[ $line[0] = "メールを送信しました。" ]
}

@test "二回目の実行時はメールが送信されない"{
	run ../goldfish.sh
	[ $output = "" ]
}

