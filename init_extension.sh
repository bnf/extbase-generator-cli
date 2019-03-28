#!/bin/bash

num_files=`find . -mindepth 1 -maxdepth 1 -not -path "./.git" | wc -l`

if [ $# -lt 1 ]; then
	echo "Usage:"
	echo "  `basename $0` <VendorName> [<Title>]"

	if [ $num_files -gt 0 ]; then
		echo
		echo "Warning: This script should only be used on an empty (git) directory."
	fi

 	exit 1
fi

if [ $num_files -gt 0 ]; then
	echo "Error: This script should only be used on an empty (git) directory."
	exit 1
fi

extension=$(basename `pwd`)
extension_nc=`echo "$extension" | sed -e 's/^./\u&/' -e 's/_\(.\)/\u\1/g'`

vendor=$1
title=${2:-$extension}

author=`git config user.name`
email=`git config user.email`

cat > ext_emconf.php << EOF
<?php

\$EM_CONF[\$_EXTKEY] = array(
    'title' => '${title}',
    'description' => '',
    'category' => '',
    'author' => '${author}',
    'author_email' => '${email}',
    'state' => 'stable',
    'internal' => '',
    'uploadfolder' => '0',
    'createDirs' => '',
    'clearCacheOnLoad' => 0,
    'version' => '',
    'constraints' => array(
        'depends' => array(
            'typo3' => '6.2.0-7.6.99',
        ),
        'conflicts' => array(
        ),
        'suggests' => array(
        ),
    ),
    'autoload' => array(
        'psr-4' => array(
            '${vendor}\\\\${extension_nc}\\\\' => 'Classes',
        ),
    ),
);
EOF

cat > ext_tables.php << EOF
<?php
if (!defined('TYPO3_MODE')) {
    die('Access denied.');
}
EOF

cat > ext_localconf.php << EOF
<?php
if (!defined('TYPO3_MODE')) {
    die('Access denied.');
}
EOF

cat > .editorconfig << EOF
# This file is for unifying the coding style for different editors and IDEs
# editorconfig.org

root = true

[*]
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true
indent_style = tab
tab_width = 8

[**.php]
indent_style = space
indent_size = 4
EOF

cat > .php_cs << EOF
<?php

return Symfony\\CS\\Config\\Config::create()
    ->level(Symfony\\CS\\FixerInterface::PSR2_LEVEL)
    ->fixers([
        'psr0',

        // psr-1
        'encoding',
        'short_tag',

        // subset of symphony level
        'extra_empty_lines',
        'no_empty_lines_after_phpdocs',
        'no_blank_lines_after_class_opening',
        'operators_spaces',
        'phpdoc_indent',
        'phpdoc_no_package',
        'phpdoc_params',
        'phpdoc_trim',
        'phpdoc_scalar',
        'remove_leading_slash_use',
        'return',
        'self_accessor',
        'single_array_no_trailing_comma',
        'single_quote',
        'spaces_after_semicolon',
        'spaces_before_semicolon',
        'unused_use',
        'whitespacy_lines',

        // contrib checks
        'concat_with_spaces',
        'newline_after_open_tag',
        'ordered_use',
        'single_quote',
    ])
    ->finder(
        Symfony\\CS\\Finder\\DefaultFinder::create()
            ->exclude('Resources')
            ->exclude('.git')
            ->in(__DIR__)
    );
EOF

echo "Initialized as typo3 extension."
