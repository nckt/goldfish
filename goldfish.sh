###
# 指定したサイトの中身を取ってきて、前回と違ってたら更新されてたよ！ってメールする
###
#!/usr/bin/env bash

WORKDIR=`dirname $0`
RECIPIENTFILE=$WORKDIR/conf/recipient.json
SITESDIR=$WORKDIR/conf/sites
HTMLDIR=$WORKDIR/html

##
# 更新通知メールを送信
#
# @param 更新があったページの取得結果
# @param 更新があったページのURL
##
send_mail() {
	local recipient=`cat ${RECIPIENTFILE} | jq '.[]' | perl -pe 's/\n/,/'`
	local title=`cat $1 | awk 'match($0, /<title>.*?<\/title>/){print substr(\$0, RSTART, RLENGTH)}' | sed s/\<title\>\|\<\\\/title\>//g`
	cat << EOT | mail -s '[goldfish]サイト更新通知' ${recipient}
サイトが更新されました!

${title}
${2}
--
I'm goldfish.
EOT
}

# --- 本体処理 --- #
for SITE in $(ls -1 ${SITESDIR}/*.json); do
	# 前回の取得結果をリネームして残しておく
	HTMLFILENAME=`cat ${SITE} | jq '.id' | sed s/\"//g`.html
	HTMLFULLPATH=${HTMLDIR}/${HTMLFILENAME}
	if [ -f ${HTMLFULLPATH} ]; then
		mv ${HTMLFULLPATH} ${HTMLFULLPATH}.old
	else
		touch ${HTMLFULLPATH}.old
	fi
	
	# 現在と前回を比較し、違いがあったらメールする
	URL=`cat ${SITE} | jq '.url' | sed s/\"//g`
	curl ${URL} | perl -pe 's/\n//' | sed s/tdftad.*// > ${HTMLFULLPATH}
	RESULT=`diff ${HTMLFULLPATH} ${HTMLFULLPATH}.old | wc -l`
	if [ ${RESULT} > 0 ]; then
		send_mail ${HTMLFULLPATH} ${URL}
		echo "メールを送信しました。"
	fi
done

