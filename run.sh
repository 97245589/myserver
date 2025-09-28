localip=`ifconfig | grep inet | head -1 | awk '{print $2}'`
export IP="0.0.0.0"
export OUTER_IP="0.0.0.0"

# export ROOT=$(cd `dirname $0`; pwd)
# export DAEMON=false
# while getopts "dk" arg
# do
# 	case $arg in
# 		d)
# 			export DAEMON=true
# 			;;
# 		k)
# 			kill `cat run/skynet.pid`
# 			exit 0;
# 			;;
# 	esac
# done

./skynet/skynet ./server_config/config.$1