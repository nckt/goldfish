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
# @param 更新があったページのID
# @param 更新があったページのURL
##
send_mail(){
	local recipient=`cat ${RECIPIENTFILE} | jq '.[]' | perl -pe 's/\n/,/'`

	echo "mail -s '[goldfish]サイト更新通知' ${recipient}"
	cat << EOT | mail -s '[goldfish]サイト更新通知' ${recipient}
サイトが更新されました!

Site id: ${1}
${2}
--
goldfish
EOT
	return ${?}
}

# --- 本体処理 --- #
for SITE in $(ls -1 ${SITESDIR}/*.json); do
	ID=`cat ${SITE} | jq -r '.id'`
	URL=`cat ${SITE} | jq -r '.url'`
	REGEXP=`cat ${SITE} | jq -r '.regexp'`
	IS_REGEXP_MULTILINE=`cat ${SITE} | jq '.is_regexp_multiline'`
	COMMAND=`cat ${SITE} | jq -r '.pipeline_command'`

	echo "----- CHECK ${ID} -----"

	# 前回の取得結果をリネームして残しておく
	HTMLFILENAME=${ID}.html
	HTMLFULLPATH=${HTMLDIR}/${HTMLFILENAME}
	touch ${HTMLFULLPATH}.old
	cp ${HTMLFULLPATH} ${HTMLFULLPATH}.old
	
	# 現在と前回を比較し、違いがあったらメールする
	curl -o ${HTMLFULLPATH} ${URL}

	if [ "${IS_REGEXP_MULTILINE}" = 'true' ]; then
		echo '[TRACE] REGEXP MULTI LINE MODE IS ENABLE. DELETE LINE BREAKS.'
		cat ${HTMLFULLPATH} | tr -d '\n' > ${HTMLFULLPATH}.tmp
		mv -f ${HTMLFULLPATH}.tmp ${HTMLFULLPATH}
	fi

	if [ "${REGEXP}" != 'null' ]; then
		echo '[TRACE] REGEXP IS SET. MATCH REGEXP.'
		cat ${HTMLFULLPATH} | grep -o -P "${REGEXP}" > ${HTMLFULLPATH}.tmp
		mv -f ${HTMLFULLPATH}.tmp ${HTMLFULLPATH}
	fi

	if [ "${COMMAND}" != 'null' ]; then
		echo '[TRACE] PIPE LINE COMMAND IS SET. EXECUTE COMMAND.'
		cat ${HTMLFULLPATH} | ${COMMAND} > ${HTMLFULLPATH}.tmp
		mv -f ${HTMLFULLPATH}.tmp ${HTMLFULLPATH}
	fi

	RESULT=`diff ${HTMLFULLPATH} ${HTMLFULLPATH}.old | wc -l`
	if [ ${RESULT} -gt 0 ]; then
		send_mail ${ID} ${URL}

		if [ ${?} -eq 0 ]; then
			echo "[TRACE] MAIL SENT."
		else
			echo '[ERROR!] MAIL SEND FAILURE.'
		fi
	else
		echo '[TRACE] THERE ARE NO CHANGES.'
	fi

	echo "--- CHECK ${ID} END ---"
done

