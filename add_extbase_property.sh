#!/bin/bash

# TODO: fail if the current directon is not under version control
# TODO: fail if there are uncommitted changes
# TODO: @validate NotEmpty support
# TODO: add relation with optional @lazy support
# TODO: search backwards for ext_emconf.php and cd to that directory and use it as extension name

if [ ! -e "ext_emconf.php" ]; then
	echo "Error: This script needs to be run from an extensions root dir"
	exit 1
fi

if [ $# -lt 3 ]; then
	echo "Usage:"
	echo "  `basename $0` <ModelName> <newField> <type>"
	echo
	echo "  <ModelName> without namespace e.g. 'Event'"
	echo "  <newField>  the field to be added, camel case as written in the model"
	echo "  <type> is one of: "
	echo "    int"
	echo "    float"
	echo "    bool"
	echo "    string"
	echo "    text"
	echo "    rte"
	echo "    password"
	echo "    date"
	echo "    datetime"
	echo "    time"
	echo "    timesec"
	echo "    select"
	echo "    date_timestamp"
	echo "    datetime_timestamp"
	echo "    file"
	echo "    image"
	echo
	echo "Examples:"
	echo "    `basename $0` Event title string"
	echo "    `basename $0` Event start datetime"
	echo "    `basename $0` Event end datetime"
	echo "    `basename $0` Event description rte"
	echo "    `basename $0` Event isTop bool"
	echo "    `basename $0` Product price float"

	exit 1
fi

#uncommitted_changes=$(git status --porcelain 2>/dev/null| egrep "^(M| M)" | wc -l)
#if [ $uncommitted_changes -gt 0 ]; then
#	echo "There a uncommite
#fi

model=$1
property=$2
typ=$3

extension=$(basename `pwd`)
extension_normalize=`echo "$extension" | sed 's/_//g'`
model_normalize=`echo "$model" | tr '[:upper:]' '[:lower:]'`
tablename="tx_${extension_normalize}_domain_model_${model_normalize}"

model_file=Classes/Domain/Model/${model}.php
tca_file=Configuration/TCA/${tablename}.php

[[ -e "$tca_file" ]] || tca_file=Configuration/TCA/${model}.php

field=`echo $property | sed ':a;s/\([a-z]\)\([A-Z][a-z]\)/\1_\l\2/g;ta'`
uproperty=`echo $property | sed 's/^./\u&/'`
propertyLabel=`echo $property | sed -e 's/[A-Z]/ &/' -e 's/^./\u&/'`


declare -A type_map=(
	["int"]="int"
	["string"]="string"
	["text"]="string"
	["rte"]="string"

	["password"]="string"
	["float"]="float"
	["bool"]="bool"
	["date"]="\\\\DateTime"
	["datetime"]="\\\\DateTime"
	["time"]="int"
	["timesec"]="int"
	["select"]="int"
	["date_timestamp"]="\\\\DateTime"
	["datetime_timestamp"]="\\DateTime"

	["file"]="\\\\TYPO3\\\\CMS\\\\Extbase\\\\Domain\\\\Model\\\\FileReference"
	["image"]="\\\\TYPO3\\\\CMS\\\\Extbase\\\\Domain\\\\Model\\\\FileReference"

	["relation"]="$4"
)

declare -A default_values=(
	["int"]="0"
	["string"]="''"
	["text"]="''"
	["rte"]="''"

	["password"]="''"
	["float"]="0.0"
	["bool"]="false"
	["date"]="null"
	["datetime"]="null"
	["time"]="0"
	["timesec"]="0"
	["select"]="0"
	["date_timestamp"]="null"
	["datetime_timestamp"]="null"

	["file"]="null"
	["image"]="null"

	["relation"]="null"
)

declare -A tca_types=(
	["int"]="input"
	["string"]="input"
	["text"]="text"
	["rte"]="text"

	["password"]="input"
	["float"]="input"
	["bool"]="check"
	["date"]="input"
	["datetime"]="input"
	["time"]="input"
	["timesec"]="input"
	["select"]="select"
	["date_timestamp"]="input"
	["datetime_timestamp"]="input"

	["file"]="file_field"
	["image"]="file_field"

	["relation"]="inline"
)

declare -A tca_evals=(
	["int"]="trim,int"
	["string"]="trim"
	["text"]="trim"
	["rte"]="trim"

	["password"]="nospace,password"
	["float"]="double2"
	["bool"]=""
	["date"]="date"
	["datetime"]="datetime"
	["time"]="time"
	["timesec"]="timesec"
	["select"]=""
	["date_timestamp"]="date"
	["datetime_timestamp"]="datetime"

	["file"]=""
	["image"]=""

	["relation"]=""
)

# TODO: defaultExtras need to be placed AFTER the config

declare -A tca_option_map=(
	["int"]="'size' => 30"
	["string"]="'size' => 30"
	["text"]="'cols' => 40, 'rows' => 15"
	["rte"]="'cols' => 40, 'rows' => 15, 'defaultExtras' => 'richtext[]:rte_transform[mode=ts_css]'"

	["password"]="'size' => 30"
	["float"]="'size' => 30"
	["bool"]="'default' => 0"
	["date"]="'dbType' => 'date', 'size' => 7, 'checkbox' => 0, 'default' => '0000-00-00'"
	["datetime"]="'dbType' => 'datetime', 'size' => 12, 'checkbox' => 0, 'default' => '0000-00-00 00:00:00'"
	["time"]="'size' => 4, 'checkbox' => 1, 'default' => time()"
	["timesec"]="'size' => 6, 'checkbox' => 1, 'default' => time()"
	["select"]="'renderType' => 'selectSingle', 'size' => 1, 'maxitems' => 1, 'items' => [['-- Label --', 0]]"
	["date_timestamp"]="'size' => 7, 'checkbox' => 1, 'default' => time()"
	["datetime_timestamp"]="'size' => 12, 'checkbox' => 1, 'default' => time()"

	["file"]=""
	["image"]=""

	["relation"]="'foreign_table' => '$5', 'foreign_field' => 'parent', 'maxitems' => 9999, 'appearance' => ['collapseAll' => 0, 'levelLinksPosition' => 'top', 'showSynchronizationLink' => 1, 'showPossibleLocalizationRecords' => 1, 'showAllLocalizationLink' => 1,]"
)

declare -A sql_types=(
	["int"]="int(11) unsigned DEFAULT '0' NOT NULL"
	["string"]="varchar(255) DEFAULT '' NOT NULL"
	["text"]="text NOT NULL"
	["rte"]="text NOT NULL"

	["password"]="varchar(255) DEFAULT '' NOT NULL"
	["float"]="double(11,2) DEFAULT '0.00' NOT NULL"
	["bool"]="tinyint(1) unsigned DEFAULT '0' NOT NULL"
	["date"]="date DEFAULT '0000-00-00'"
	["datetime"]="datetime DEFAULT '0000-00-00 00:00:00'"
	["time"]="int(11) DEFAULT '0' NOT NULL"
	["time_sec"]="int(11) DEFAULT '0' NOT NULL"
	["select"]="int(11) DEFAULT '0' NOT NULL"
	["date_timestamp"]="int(11) DEFAULT '0' NOT NULL"
	["datetime_timestamp"]="int(11) DEFAULT '0' NOT NULL"

	["file"]="int(11) unsigned NOT NULL DEFAULT '0'"
	["image"]="int(11) unsigned NOT NULL DEFAULT '0'"

	["relation"]="int(11) unsigned DEFAULT '0' NOT NULL"
)

php_type="${type_map["$typ"]}"
default_value="${default_values["$typ"]}"
tca_eval="${tca_evals["$typ"]}"
tca_type="${tca_types["$typ"]}"
tca_options="${tca_option_map["$typ"]}"
sql_type="${sql_types["$typ"]}"

#######################################################################################################################

# TCA

# Add identation to tca_options. \1 is the backreference to the captured indentation of 'columns'
tca_options=$(echo "$tca_options" | sed "s/, '/,\\\\n\\\\1            '/g")
# TODO add ,\n if tca_options is not empty, and remvoe that inline

sed -i -f - $tca_file << EOF
s/\('searchFields' => .*\),',/\1',/
s/\('searchFields.*\)',\$/\1,$field',/
s/\('searchFields' => '\),\(.*\)/\1\2/
s/\('showRecordFieldList.*\)',\$/\1, $field',/
s/'label' => 'uid'/'label' => '${field}'/

/'showitem' =>/ {
	# Place before the first tab, if that is available
	/--div--/s/\('showitem' => '..*\)--div/\1$field, --div/
	/--div--/!s/\('showitem' => '..*\)'),/\1, $field'),/
}

/[ ]*'columns' =>/ {
	:loop
	/^\([ \t]*\)'columns'.*\n\1[])],/! {
		N
		b loop
	}

	s|^\([ \t]*\)\('columns'.*[^\n]\)\(\n\n*\)\1\([])],\)|\1\2\3\
\1    '${field}' => array(\n\
\1        'exclude' => 1,\n\
\1        'label' => 'LLL:EXT:${extension}/Resources/Private/Language/locallang_db.xlf:${tablename}.${field}',\n\
\1        'config' => array(\n\
\1            'type' => '${tca_type}',\n\
\1            $tca_options,\n\
\1            'eval' => '${tca_eval}'\n\
\1        ),\n\
\1    ),\3\
\1\4|
}
EOF


# Locallang fixes
sed -i "s/.*<\/body>/\t\t\t<trans-unit id=\"${tablename}.${field}\">\n\t\t\t\t<source>${propertyLabel}<\/source>\n\t\t\t<\/trans-unit>\n&/" \
	Resources/Private/Language/locallang.xlf \
	Resources/Private/Language/locallang_db.xlf


sed -i "s/.*<\/body>/\t\t\t<trans-unit id=\"${field}.description\">\n\t\t\t\t<source>${field}<\/source>\n\t\t\t<\/trans-unit>\n&/" \
	Resources/Private/Language/locallang_csh_${tablename}.xlf


# Try to place the new field before tstamp (or if that fails directly after the CREATE TABLE statement)
sed -i -f - ext_tables.sql << EOF
/^CREATE TABLE ${tablename} (/ {
	# Fill up the current buffer with the following lines until we find the trailing ');'
	:loop
	/);/! {
		N
		b loop
	}

	# This implies tstamp to be the first non-model field
	# and that model fields and tstamp are seperated by two newlines
	# (that is the case for extension_builder generated files and our generator)
	s/\n\n[ \t]*tstamp /\n\t${field} ${sql_type},&/

	# skip the following CREATE TABLE replace if we've already added
	tend

	s/CREATE TABLE[^\n(]*([^\n]*\n/&\t${field} ${sql_type},\n/
	:end
}
EOF


sed -i -f - ${model_file} << EOF
# Use ^class selector to ensure we're adding the property only once
/^class/ {
	:loop
	/---PROPERTY--/! {
		# Try to define the new property before the first function
		/[^ ]*public function / {
			s/\n\n\([^\n][^\n]*\n\)*[ \t]*public function/\n\n---PROPERTY---&/
		}
	}
	/\n}/ {
		# If we've found no function, add the new property to the end of the file
		/---PROPERTY--/! {
			s/\n}/\n---PROPERTY---&/
		}
		s/\n}/\n\n---GETTER---&/
		s/\n}/\n\n---SETTER---&/

		b replace
	}
	N
	bloop
}

# leave the script here – functionality below is explicitly requesting by a jump
b

:replace
s#\n---PROPERTY---#\n\
    /**\n\
     * ${property}\n\
     *\n\
     * @var ${php_type}\n\
     */\n\
    protected \$${property} = ${default_value};#

s#\n---GETTER---#\n\
    /**\n\
     * Returns the ${property}\n\
     *\n\
     * @return ${php_type} \$${property}\n\
     */\n\
    public function get${uproperty}()\n\
    {\n\
        return \$this->${property};\n\
    }#

s#\n---SETTER---#\n\
    /**\n\
     * Sets the ${property}\n\
     *\n\
     * @param  ${php_type} \$${property}\n\
     * @return void\n\
     */\n\
    public function set${uproperty}(\$${property})\n\
    {\n\
        \$this->${property} = \$${property};\n\
    }#
EOF

echo "Created \$${property} in ${model}"
echo
echo "Edit Resources/Private/Language/locallang_db.xlf to edit the label shown in the TCA."
echo "Edit Resources/Private/Language/locallang.xlf to edit the label shown in the Frontend."
