#!/bin/bash

# TODO: add modifiers to enable: enablefield,starttime,endttime,versioning

if [ ! -e "ext_emconf.php" ]; then
	echo "Error: This script needs to be run from an extensions root dir"
	exit 1
fi

if [ $# -lt 1 ]; then
	echo "Usage:"
	echo "  `basename $0` <ModelName>"

 	exit 1
fi

model=$1

extension=$(basename `pwd`)
extension_normalized=`echo "$extension" | sed 's/_//g'`
model_normalized=`echo "$model" | tr '[:upper:]' '[:lower:]'`
tablename="tx_${extension_normalized}_domain_model_${model_normalized}"
namespace_prefix=$(sed -n -e 's/\\\\/\\/g' -e "s/.*'\([^']*\)'[ ]*=>[ ]*'Classes'.*/\1/p" ext_emconf.php)
namespace=${namespace_prefix}Domain\\Model

model_file=Classes/Domain/Model/${model}.php
tca_file=Configuration/TCA/${tablename}.php
locallang_csh_file=Resources/Private/Language/locallang_csh_${tablename}.xlf

mkdir -p \
	Classes/Domain/Model \
	Configuration/TCA \
	Resources/Private/Language \

cat >${model_file} <<EOL
<?php
namespace ${namespace};

/**
 * ${model}
 */
class ${model} extends \\TYPO3\\CMS\\Extbase\\DomainObject\\AbstractEntity
{
}
EOL

cat >> ext_tables.sql << EOL

#
# Table structure for table '${tablename}'
#
CREATE TABLE ${tablename} (
	uid int(11) NOT NULL auto_increment,
	pid int(11) DEFAULT '0' NOT NULL,


	tstamp int(11) unsigned DEFAULT '0' NOT NULL,
	crdate int(11) unsigned DEFAULT '0' NOT NULL,
	cruser_id int(11) unsigned DEFAULT '0' NOT NULL,
	deleted tinyint(4) unsigned DEFAULT '0' NOT NULL,
	hidden tinyint(4) unsigned DEFAULT '0' NOT NULL,
	starttime int(11) unsigned DEFAULT '0' NOT NULL,
	endtime int(11) unsigned DEFAULT '0' NOT NULL,

	t3ver_oid int(11) DEFAULT '0' NOT NULL,
	t3ver_id int(11) DEFAULT '0' NOT NULL,
	t3ver_wsid int(11) DEFAULT '0' NOT NULL,
	t3ver_label varchar(255) DEFAULT '' NOT NULL,
	t3ver_state tinyint(4) DEFAULT '0' NOT NULL,
	t3ver_stage int(11) DEFAULT '0' NOT NULL,
	t3ver_count int(11) DEFAULT '0' NOT NULL,
	t3ver_tstamp int(11) DEFAULT '0' NOT NULL,
	t3ver_move_id int(11) DEFAULT '0' NOT NULL,

	sys_language_uid int(11) DEFAULT '0' NOT NULL,
	l10n_parent int(11) DEFAULT '0' NOT NULL,
	l10n_diffsource mediumblob,

	PRIMARY KEY (uid),
	KEY parent (pid),
	KEY t3ver_oid (t3ver_oid,t3ver_wsid),
	KEY language (l10n_parent,sys_language_uid)
);
EOL

cat >> ext_tables.php << EOL

\\TYPO3\\CMS\\Core\\Utility\\ExtensionManagementUtility::allowTableOnStandardPages('${tablename}');
\\TYPO3\\CMS\\Core\\Utility\\ExtensionManagementUtility::addLLrefForTCAdescr(
    '${tablename}',
    'EXT:${extension}/Resources/Private/Language/locallang_csh_${tablename}.xlf'
);
EOL


sed -i "s/.*<\/body>/\t\t\t<trans-unit id=\"${tablename}\">\n\t\t\t\t<source>${model}<\/source>\n\t\t\t<\/trans-unit>\n&/" \
	Resources/Private/Language/locallang.xlf \
	Resources/Private/Language/locallang_db.xlf

date=`date "+%Y-%m-%dT%H:%I:%SZ"`
cat > ${locallang_csh_file} << EOL
<?xml version="1.0" encoding="utf-8" standalone="yes" ?>
<xliff version="1.0">
	<file source-language="en" datatype="plaintext" original="messages" date="${date}" product-name="${extension}">
		<header/>
		<body>
		</body>
	</file>
</xliff>
EOL


cat > ${tca_file} << EOL
<?php
return array(
    'ctrl' => array(
        'title'    => 'LLL:EXT:${extension}/Resources/Private/Language/locallang_db.xlf:${tablename}',
        'label' => 'uid',
        'tstamp' => 'tstamp',
        'crdate' => 'crdate',
        'cruser_id' => 'cruser_id',
        'dividers2tabs' => true,
        'versioningWS' => 2,
        'versioning_followPages' => true,
        'languageField' => 'sys_language_uid',
        'transOrigPointerField' => 'l10n_parent',
        'transOrigDiffSourceField' => 'l10n_diffsource',
        'delete' => 'deleted',
        'enablecolumns' => array(
            'disabled' => 'hidden',
            'starttime' => 'starttime',
            'endtime' => 'endtime',
        ),
        'searchFields' => '',
        'iconfile' => \\TYPO3\\CMS\\Core\\Utility\\ExtensionManagementUtility::extRelPath('extension_builder_text') . 'Resources/Public/Icons/${tablename}.gif'
    ),
    'interface' => array(
        'showRecordFieldList' => 'sys_language_uid, l10n_parent, l10n_diffsource, hidden',
    ),
    'types' => array(
        '1' => array('showitem' => 'sys_language_uid;;;;1-1-1, l10n_parent, l10n_diffsource, hidden;;1, --div--;LLL:EXT:cms/locallang_ttc.xlf:tabs.access, starttime, endtime'),
    ),
    'palettes' => array(
        '1' => array('showitem' => ''),
    ),
    'columns' => array(

        'sys_language_uid' => array(
            'exclude' => 1,
            'label' => 'LLL:EXT:lang/locallang_general.xlf:LGL.language',
            'config' => array(
                'type' => 'select',
                'renderType' => 'selectSingle',
                'foreign_table' => 'sys_language',
                'foreign_table_where' => 'ORDER BY sys_language.title',
                'items' => array(
                    array('LLL:EXT:lang/locallang_general.xlf:LGL.allLanguages', -1),
                    array('LLL:EXT:lang/locallang_general.xlf:LGL.default_value', 0)
                ),
            ),
        ),
        'l10n_parent' => array(
            'displayCond' => 'FIELD:sys_language_uid:>:0',
            'exclude' => 1,
            'label' => 'LLL:EXT:lang/locallang_general.xlf:LGL.l18n_parent',
            'config' => array(
                'type' => 'select',
                'renderType' => 'selectSingle',
                'items' => array(
                    array('', 0),
                ),
                'foreign_table' => '${tablename}',
                'foreign_table_where' => 'AND ${tablename}.pid=###CURRENT_PID### AND ${tablename}.sys_language_uid IN (-1,0)',
            ),
        ),
        'l10n_diffsource' => array(
            'config' => array(
                'type' => 'passthrough',
            ),
        ),
        't3ver_label' => array(
            'label' => 'LLL:EXT:lang/locallang_general.xlf:LGL.versionLabel',
            'config' => array(
                'type' => 'input',
                'size' => 30,
                'max' => 255,
            )
        ),
        'hidden' => array(
            'exclude' => 1,
            'label' => 'LLL:EXT:lang/locallang_general.xlf:LGL.hidden',
            'config' => array(
                'type' => 'check',
            ),
        ),
        'starttime' => array(
            'exclude' => 1,
            'l10n_mode' => 'mergeIfNotBlank',
            'label' => 'LLL:EXT:lang/locallang_general.xlf:LGL.starttime',
            'config' => array(
                'type' => 'input',
                'size' => 13,
                'max' => 20,
                'eval' => 'datetime',
                'checkbox' => 0,
                'default' => 0,
                'range' => array(
                    'lower' => mktime(0, 0, 0, date('m'), date('d'), date('Y'))
                ),
            ),
        ),
        'endtime' => array(
            'exclude' => 1,
            'l10n_mode' => 'mergeIfNotBlank',
            'label' => 'LLL:EXT:lang/locallang_general.xlf:LGL.endtime',
            'config' => array(
                'type' => 'input',
                'size' => 13,
                'max' => 20,
                'eval' => 'datetime',
                'checkbox' => 0,
                'default' => 0,
                'range' => array(
                    'lower' => mktime(0, 0, 0, date('m'), date('d'), date('Y'))
                ),
            ),
        ),
    ),
);
EOL
