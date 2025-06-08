#!/bin/bash

# Generated Configurations
build_context="gensrc"
docker_compose_config="${build_context}/docker-compose.yaml"
dockerfile_config="${build_context}/Dockerfile"

# Location for storing SSL Certificate and Key
key_dir="ssl"
project="jenkins"
image_name="${project}-ssl"
version="lts-jdk17"

# Container Settings
container_name="${project}-ssl"

# Jenkins Url
jenkins_server_ip="127.0.0.1"
jenkins_url="jenkins-ssl.local"

logger(){
	printf "\033[35m[ $(date '+%F %T') ] \033[33mLOG: \033[36m${1}\033[0m\n"
}

error(){
	printf "\033[35mError:\t\033[31m${1}\033[0m\n"
	exit 1
}

cleanup(){
	logger "Running, cleanup process..."
	_dirs=( "${build_context}" "${key_dir}" )
	for _dir in ${_dirs};
	do
		logger "Flushing, ${_dir}"
		[ -d "${_dir}" ] && rm -rfv ${_dir} && logger "Successfully, removed ${_dir}" || \
		logger "No instance of ${_dir} was found"
	done
	# Clean Docker
	logger "Removing, zombie images"
	docker image prune --force
	logger "Truncating, Docker Volume."
	docker volume prune --force

}

create_key_certificate(){
	# Remove older SSL Data
	if [ -n "${key_dir}" -a -d "${key_dir}" ];
	then
		logger "Removing older SSL data."
		rm -rfv "${key_dir}"
	fi		
	
	# Recreate local ssl directory
	mkdir -v "${key_dir}" && logger "Recreating local SSL directory for SSL Key and Certificate." || \
	error "Problem occurred while trying to create local SSL directory!"
	
	# Generate new SSL Key and Certificate
	logger "Generating a new SSL Key and Certificate..."
	openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes -keyout "${key_dir}/${project}.key" \
	-out "${key_dir}/${project}.crt" -subj "/CN=${jenkins_url}" -addext "subjectAltName=DNS:${jenkins_url},IP:${jenkins_server_ip}"
	
	# Determine if the certificate and key where created
	if [ -e "${key_dir}/${project}.crt" -a -e "${key_dir}/${project}.key" ];
	then
		logger "Successfully, created SSL Key and Certificate"
	else
		error "Problem occurred while trying to create SSL Key and Certificate"
	fi
}

generate_configurations(){
	if [ -e "$(command -v python)" ];
	then
		# Remove older configuration data
		logger "Does older configuration data exists?"
		if [ -d "${build_context}" ];
		then
			logger "Removing, older configuration data ${build_context}."
			rm -rfv "${build_context}"
		fi
		# Creates new configuration directory
		logger "Creating new configuration directory ${build_context}."
		mkdir -v "${build_context}" && logger "Successfully, created configuration directory ${build_context}."
		# Executing the docker configuration files generation
		logger "Executing, generate docker configurations."
		python utils/generate_docker_config.py --image "${image_name}"
		if [ -e "${docker_compose_config}" -a -e "${dockerfile_config}" ];
		then
			logger "Successfully, generated docker configuration files."
		else
			error "Unable to generate docker configuration files!"
		fi
	else
		error "Missing or unable to locate Python command!"
	fi
}

	# Moving SSL data to build context
update_build_context(){
	if [ -d "${key_dir}" ];
	then
		if [ -e "${key_dir}/${project}.crt" -a -e "${key_dir}/${project}.key" ];
		then
			logger "Moving '${key_dir}' to '${build_context}' (build context)..."
			mv -v ${key_dir} ${build_context} && logger "Successfully moved." || \
			error "Unable to move ${key_dir}"
		fi
		# Copy NGINX configuration into build context
		if [ -d "config" ];
		then
			logger "Moving 'config' directory to '${build_context}' (build context)..."
			cp -a -v "config" ${build_context} && logger "Successfully moved." || \
			error "Unable to move ${key_dir}"
		fi
	else
		error "No ${key_dir} is available!"
	fi

}

build_image(){
	# Generates the configuration files
	generate_configurations
	# Ensures all required resources are in build context
	update_build_context
	# Build image according to generated Dockerfile
	if [ -n "$(docker images ${project}/${project} | grep -o ${project}/${project})" ];
	then
		docker build --no-cache -t "${image_name}" "${build_context}"
	else
		error "Missing or unable to find ${image_name}!"
	fi
}

build_image_precheck(){
	# Remove older image if exists
	[ -n "${image_name}" -a -n "$(docker images ${image_name} | grep -o ${image_name})" ] && docker rmi -f "${image_name}"
	build_image
}

spinup_container(){
	if [ -e "${docker_compose_config}" ];
	then
		printf "\033[36mSpinning up container: \033[33m${container_name}\033[0m\n"
		if [ -n "$(docker images ${image_name} | grep -o ${image_name})" ];
		then
			if [ -n "$(docker container ls -a | grep ${container_name} | awk '{print $1}')" ];
			then
				printf "\033[36mRemoving, older container.\033[0m\n"
				docker rm -f "${container_name}"
			fi
			docker-compose -f "${docker_compose_config}" up --detach
		fi
	else
		error "Missing or unable to find \"${docker_compose_config}\" file"
	fi
}

extract_value(){
	echo "${1}" | cut -d'=' -f2 | cut -d':' -f2
}

usages(){
	printf "\033[36mUSAGE:\033[0m\n"
	# printf "\033[33m\033[0m\n"
	printf "\033[35m$0 \033[32m--action=spinup\n"
	printf "\033[35m$0 \033[32m--action=spinup\n"
}

commands(){
	printf "\033[35mCOMMANDS:\033[0m\n"
	printf "\033[35mSpin-Up Container\t\033[32m[ build, spinup ]\033[0m\n"
	printf "\033[35mClean-Up Session\t\033[32m[ cleanup, trunc, truncate ]\033[0m\n"
}

help_menu(){
	printf "\033[36m$(basename -s .sh $0 | sed 's/_/ /g' | tr [:lower:] [:upper:])\033[0m\n"
	printf "\033[35mExecute Action\t\033[32m[ --action={COMMAND}, action:{COMMAND} ]\033[0m\n"
	echo;
	commands
	echo;
	usages
	exit 0
}

for argv in $@
do
	case $argv in
		action:*|--action=*) _action="$(extract_value $argv)";;
		-h|--help|help) help_menu;;
	esac
done

case $_action in
	build|spinup)
	logger "Executing, action $_action"
	cleanup; create_key_certificate;	
	build_image_precheck; spinup_container
	;;
	cleanup|trunc|truncate) cleanup;;
	*) error "Missing or invalid parameter was given";;
esac

