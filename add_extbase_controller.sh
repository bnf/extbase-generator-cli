#!/bin/bash

# TODO: add modifiers to enable: enablefield,starttime,endttime,versioning

if [ ! -e "ext_emconf.php" ]; then
	echo "Error: This script needs to be run from an extensions root dir"
	exit 1
fi

if [ $# -lt 1 ]; then
	echo "Usage:"
	echo "  `basename $0` add:controller <ControllerName>"

 	exit 1
fi

controller=$1

cat >> ext_localconf.php << EOF

\\TYPO3\\CMS\\Extbase\\Utility\\ExtensionUtility::configurePlugin(
    'Qbus.' . \$_EXTKEY,
    '${controller}',
    array(
        '${controller}' => '',

    ),
    // non-cacheable actions
    array(
        '${controller}' => '',

    )
);
EOF

cat >> ext_tables.php << EOF


\\TYPO3\\CMS\\Extbase\\Utility\\ExtensionUtility::registerPlugin(
    \$_EXTKEY,
    '${controller}',
    '${controller}'
);
EOF

mkdir -p Classes/Controller Classes/Domain/Repository
touch Classes/Controller/${controller}Controller.php
touch Classes/Domain/Repository/${controller}Repository.php
