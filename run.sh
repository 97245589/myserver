localip=`ifconfig | grep inet | head -1 | awk '{print $2}'`
export IP="0.0.0.0"

# while getopts "Dk" arg
# do
# 	case $arg in
# 		D)
# 			export DAEMON=true
# 			;;
# 		k)
# 			kill `cat $ROOT/run/skynet.pid`
# 			exit 0;
# 			;;
# 	esac
# done

./skynet/skynet ./server_config/config.$1