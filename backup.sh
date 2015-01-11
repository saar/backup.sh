#!/bin/bash

FILES=(\
	"/etc/init/redsocks.conf" \
	"/etc/redsocks.conf" \
	"/etc/shadowsocks" \
	"/etc/supervisor/supervisord.conf" \
	"/etc/supervisor/conf.d/shadowsocks.conf" \
	"/etc/supervisor/conf.d/syncthing.conf" \
	"/etc/supervisor/conf.d/dnscrypt.conf"\
	"/usr/local/bin/publicip"\
	)
PROGRAMS=(\
	"supervisor" \
	"redsocks" \
	"python-pip" \
	"curl"
	)

SCRIPTS=(\
	"sudo rm /etc/init.d/redsocks" \
	"sudo ln -s /lib/init/upstart-job /etc/init.d/redsocks" \
	"sudo service supervisor restart"
	)
BACKUPS_DIR="$HOME/config-backups"
BACKUP_DIR="backup"

DATE=`/bin/date +%Y_%m_%d.%H_%M_%S`

function usage {
	echo "$0 [-r restore] [-h help]"
}

function restore {
	sudo apt-get install ${PROGRAMS[@]}

	ALL_BACKUP=`ls -t "$BACKUPS_DIR"`
	if [[ -z "${ALL_BACKUP[@]}" ]]; then
		printf "\e[31m%s\e[0m.\n" "Backup file was not found!"
		return	
	fi
	select LAST_BACKUP in ${ALL_BACKUP[@]}; do
		LAST_BACKUP=`ls -t "$BACKUPS_DIR" | head -n 1`
		if [[ -f "$BACKUPS_DIR/$LAST_BACKUP" ]]; then
			printf "Restoring from \e[32m%s\e[0m.\n" $LAST_BACKUP
		else
			printf "\e[31m%s\e[0m.\n" "Backup file was not found!"
			return
		fi

		tar -C / -xvf "$BACKUPS_DIR/$LAST_BACKUP"

		for S in "${SCRIPTS[@]}"
		do
			printf "Running \e[33m%s\e[0m " "$S" 
			$S
			printf "\e[32mDone\e[0m.\n"
		done
		echo

		break
	done

}

function backup {
	mkdir -p "$BACKUPS_DIR/$BACKUP_DIR"

	for FILE in "${FILES[@]}"
	do
		DIR=`dirname "$FILE"`
		DST="${BACKUPS_DIR}/${BACKUP_DIR}${DIR}"
		printf "Backuping \e[32m%-20s\e[0m from \e[33m%s\e[0m.\n" `basename $FILE` $DIR
		mkdir -p "$DST"
		cp -r "$FILE" "$BACKUPS_DIR/$BACKUP_DIR/$DIR"
	done

	tar -C "${BACKUPS_DIR}/${BACKUP_DIR}" -cf "$BACKUPS_DIR/${BACKUP_DIR}_${DATE}.tar"  --xform 's:\./::' "./"
	rm -r "$BACKUPS_DIR/$BACKUP_DIR"
}


TEMP=`getopt -o rbh --long backup,restore,help \
      -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi
eval set -- "$TEMP"


while true ; do
	case "$1" in
		-r|--restore) restore ; shift ;;
		-h|--help) usage ; shift ;;
		-b|--backup) backup ; shift ;;
		--) shift ; break ;;
		*) echo "Internal error!" ; exit 1 ;;
	esac
done









