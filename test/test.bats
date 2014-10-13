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
	[ $output = "メールを送信しました。" ]
}

@test "���ڂ̎��s�ł̓��[�������Ȃ�"{
	run ../goldfish.sh
	[ $output = "" ]
}

