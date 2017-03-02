function usage {
  echo "Usage:"
  echo "    script.sh <SAS> --service <rpsp service> --role <chef role name> --name <node name> --environment <env name>"
  exit 1
}

if [[ -z $1 ]];then
  echo "Please input your sastoken"
  usage
else
  SASTOKEN=$1
fi

while [[ $# -gt 1 ]];do
  key="$2"
  case $key in
    -s|--service)
       SERVICE="$3"
       shift # past argument
    ;;
    -r|--role)
       ROLE="$3"
       shift # past argument
    ;;
    -n|--name)
       NODE_NAME="$3"
       shift # past argument
    ;;
    -e|--environment)
       ENVIRONMENT="$3"
       shift
       ;;
    *)
       usage
       exit 1
    ;;
  esac
  shift # past argument or value
done

echo ""
echo "Confirm your inputs"
echo "===================="
echo ""
echo SASTOKEN         = "${SASTOKEN}"
echo SERVICE          = "${SERVICE}"
echo ROLE             = "${ROLE}"
echo NODENAME         = "${NODE_NAME}"
echo ENVIRONMENT      = "${ENVIRONMENT}"

if [[ -z ${SERVICE} ]] || [[ -z ${ROLE} ]] || [[ -z ${NODE_NAME} ]] || [[ -z ${ENVIRONMENT} ]];then
  echo "one of the environment is empty"
  usage
fi