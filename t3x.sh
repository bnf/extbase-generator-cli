#!/bin/bash

### INCLUDE_FUNCTIONS ###

base=`dirname $0`

function help() {
	case $1 in
	init)
		init_extension
		;;
	add:model)
		add_extbase_model
		;;
	add:property)
		add_extbase_property
		;;
	add:controller)
		add_extbase_controller
		;;
	*)
		echo "Usage: t3x <init|add:model|add:property|add:controller|help> [Options..]"
		;;
	esac
}

case $1 in
init)
	shift
	init_extension "$@"
	;;

add:model)
	shift
	add_extbase_model "$@"
	;;

add:property)
	shift
	add_extbase_property "$@"
	;;

add:controller)
	shift
	add_extbase_controller "$@"
	;;

help)
	help $2
	;;

*)
	help
	;;
esac
