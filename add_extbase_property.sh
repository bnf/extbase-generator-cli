#!/bin/bash

# TODO: fail if the current directon is not under version control
# TODO: fail if there are uncommitted changes

model=$1
property=$2

# Working for int-only currently
# Need to create a lookup table for type-related definitions in ext_tables.sql/TCA (and Model)
#typ=int
typ=$3

model_file=Classes/Domain/Model/${model}.php
tca_file=Configuration/TCA/${model}.php

# TODO: search backwards for ext_emconf.php and cd to that directory and use it as extension name
# TODO: fail if ext_emconf.php is not found (probably the wrong directory)
extension=$(basename `pwd`)
tablename=$(sed -n "s/^\$GLOBALS\['TCA'\]\['\([^']*\)'].*/\1/p" $tca_file)
field=`echo $property | sed -r 's/([a-z]+)([A-Z][a-z]+)/\1_\l\2/g'`
uproperty=`echo $property | sed -r 's/^./\u&/'`


declare -A type_map=(
	["int"]="int"
	["string"]="string"
	["text"]="string"
	["rte"]="string"
)

declare -A tca_types=(
	["int"]="input"
	["string"]="input"
	["text"]="text"
	["rte"]="text"
)

declare -A tca_option_map=(
	["int"]="'size' => 30"
	["string"]="'size' => 30"
	["text"]="'cols' => 40, 'rows' => 15"
	["rte"]="'cols' => 40, 'rows' => 15"
)

declare -A sql_types=(
	["int"]="int(11) unsigned DEFAULT '0'"
	["string"]="varchar(255) DEFAULT '' NOT NULL"
	["text"]="text NOT NULL"
	["rte"]="text NOT NULL"
)

declare -A default_values=(
	["int"]="0"
	["string"]="''"
	["text"]="''"
	["rte"]="''"
)

php_type="${type_map["$typ"]}"
tca_type="${tca_types["$typ"]}"
tca_options="${tca_option_map["$typ"]}"
sql_type="${sql_types["$typ"]}"
default_value="${default_values["$typ"]}"


#######################################################################################################################

# $tca
sed -i "s/\('showRecordFieldList.*\)',\$/\1, $field',/" $tca_file

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

# TODO: add to searchFields in ext_tables.php ?

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
