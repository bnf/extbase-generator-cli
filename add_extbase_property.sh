#!/bin/bash

# TODO: fail if the current directon is not under version control
# TODO: fail if there are uncommitted changes
# TODO: @required support
# TODO: add relation with optional @lazy support

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

# TODO: search backwards for ext_emconf.php and cd to that directory and use it as extension name
# TODO: fail if ext_emconf.php is not found (probably the wrong directory)
field=`echo $property | sed -r 's/([a-z]+)([A-Z][a-z]+)/\1_\l\2/g'`
uproperty=`echo $property | sed -r 's/^./\u&/'`


declare -A type_map=(
	["int"]="int"
	["string"]="string"
	["text"]="string"
	["rte"]="string"

	["password"]="string"
	["float"]="float"
	["bool"]="bool"
	["date"]="\\DateTime"
	["datetime"]="\\DateTime"
	["time"]="int"
	["timesec"]="int"
	["select"]="int"
	["date_timestamp"]="\\DateTime"
	["datetime_timestamp"]="\\DateTime"
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
)

declare -A tca_option_map=(
	["int"]="'size' => 30"
	["string"]="'size' => 30"
	["text"]="'cols' => 40, 'rows' => 15"
	["rte"]="'cols' => 40, 'rows' => 15"

	["password"]="'size' => 30"
	["float"]="'size' => 30"
	["bool"]="'default' => 0"
	["date"]="'dbType' => 'date', 'size' => 7, 'checkbox' => 0, 'default' => '0000-00-00'"
	["datetime"]="'dbType' => 'date', 'size' => 12, 'checkbox' => 0, 'default' => '0000-00-00 00:00:00'"
	["time"]="'size' => 4, 'checkbox' => 1, 'default' => time()"
	["timesec"]="'size' => 6, 'checkbox' => 1, 'default' => time()"
	["select"]="'renderType' => 'selectSingle', 'size' => 1, 'maxitems' => 1, 'items' => [['-- Label --', 0]]"
	["date_timestamp"]="'size' => 7, 'checkbox' => 1, 'default' => time()"
	["datetime_timestamp"]="'size' => 12, 'checkbox' => 1, 'default' => time()"
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
	["select_list"]="int(11) DEFAULT '0' NOT NULL"
	["date_timestamp"]="int(11) DEFAULT '0' NOT NULL"
	["datetime_timestamp"]="int(11) DEFAULT '0' NOT NULL"
)

php_type="${type_map["$typ"]}"
default_value="${default_values["$typ"]}"
tca_type="${tca_types["$typ"]}"
tca_options="${tca_option_map["$typ"]}"
sql_type="${sql_types["$typ"]}"

#######################################################################################################################

# TCA

# The first sed command is a fix for extension_builder's trailing comma in searchFields
sed -i \
	-e "s/\('searchFields' => .*\),',/\1',/" \
	-e "s/\('searchFields.*\)',\$/\1,$field',/" \
	-e "s/\('showRecordFieldList.*\)',\$/\1, $field',/" \
	$tca_file

# Place before the access tab, if that is available
if grep --quiet -- '--div--;LLL:EXT:cms/locallang_ttc.xlf:tabs.access' $tca_file; then
	sed -i "s/\('showitem' => '..*\)--div/\1$field, --div/" $tca_file
else
	sed -i "s/\('showitem' => '..*\)'),/\1, $field'),/" $tca_file
fi

sed -i "s#'columns'.*#&\n\n\
        '${field}' => array(\n\
            'exclude' => 1,\n\
            'label' => 'LLL:EXT:${extension}/Resources/Private/Language/locallang_db.xlf:${tablename}.${field}',\n\
            'config' => array(\n\
                'type' => '${tca_type}',\n\
                $tca_options,\n\
                'eval' => 'trim'\n\
            ),\n\
        ),#" \
	$tca_file

# Locallang fixes
sed -i "s/.*<\/body>/\t\t\t<trans-unit id=\"${tablename}.${field}\">\n\t\t\t\t<source>${uproperty}<\/source>\n\t\t\t<\/trans-unit>\n&/" \
	Resources/Private/Language/locallang.xlf \
	Resources/Private/Language/locallang_db.xlf

sed -i "s/.*<\/body>/\t\t\t<trans-unit id=\"${field}.description\">\n\t\t\t\t<source>${field}<\/source>\n\t\t\t<\/trans-unit>\n&/" \
	Resources/Private/Language/locallang_csh_${tablename}.xlf


#ext_tables.sql
sed -i "s/CREATE TABLE ${tablename} (/&\n\n\t${field} ${sql_type},/" ext_tables.sql

#if grep --quient function 

sed -i "\$s#^#\n\
    /**\n\
     * ${property}\n\
     *\n\
     * @var ${php_type}\n\
     */\n\
    protected \$${property} = ${default_value};\n\
\n\
    /**\n\
     * Returns the ${property}\n\
     *\n\
     * @return ${php_type} \$${property}\n\
     */\n\
    public function get${uproperty}()\n\
    {\n\
        return \$this->${property};\n\
    }\n\
\n\
    /**\n\
     * Sets the ${property}\n\
     *\n\
     * @param  ${php_type} \$${property}\n\
     * @return void\n\
     */\n\
    public function set${uproperty}(\$${property})\n\
    {\n\
        \$this->${property} = \$${property};\n\
    }\n#" \
	$model_file

echo "Created \$${property} in ${model}"
echo
echo "Edit Resources/Private/Language/locallang_db.xlf to edit the label shown in the TCA."
echo "Edit Resources/Private/Language/locallang.xlf to edit the label shown in the Frontend."
echo
echo "You should edit ext_tables.sql, $tca_file and $model_file to move some definitions to the proper place."
