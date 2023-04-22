#
# JBZoo Toolbox - Codestyle.
#
# This file is part of the JBZoo Toolbox project.
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.
#
# @license    MIT
# @copyright  Copyright (C) JBZoo.com, All rights reserved.
# @see        https://github.com/JBZoo/Codestyle
#

# Colors
CE      = \033[0m
C_RED   = \033[0;97;41m
C_GREEN = \033[0;97;42m
C_BACK  = \033[0;33m
C_TITLE = \033[0;30;46m

# Paths
PATH_ROOT      ?= `pwd`
PATH_SRC       ?= $(PATH_ROOT)/src
PATH_BIN       ?= $(PATH_ROOT)/bin
PATH_BUILD     ?= $(PATH_ROOT)/build
PATH_TESTS     ?= $(PATH_ROOT)/tests

CI_REPORT        ?= tc-tests
CI_REPORT_MND    ?= tc-inspections
CI_NON_ZERO_CODE ?= no

# Legacy vars. Will be removed ASAP
CI_REPORT        ?= $(TC_REPORT)
CI_REPORT_MND    ?= $(TC_REPORT_MND)
CI_REPORT_GA     ?= github-cli

PHP_BIN           ?= php
VENDOR_BIN        ?= $(PHP_BIN) $(PATH_ROOT)/vendor/bin
COMPOSER_BIN      ?= $(shell if [ $(PHP_BIN) = "php" ]; then echo "composer"; else which composer fi;)
PHP_VERSION_ALIAS ?= $(shell $(PHP_BIN) --version | head -n 1 | cut -d " " -f 2 | cut -c 1,3)
PROJECT_ALIAS     ?= $(shell basename `git rev-parse --show-toplevel` | sed 's/-//g')

JBZOO_COMPOSER_UPDATE_FLAGS ?= --with-all-dependencies

ifeq ($(strip $(PHP_BIN)),php)
	COMPOSER_BIN = composer
else
	COMPOSER_BIN = $(PHP_BIN) $(shell which composer)
endif


#### Phar files
PHPCPD_PHAR        ?= https://phar.phpunit.de/phpcpd.phar
PHPLOC_PHAR        ?= https://phar.phpunit.de/phploc.phar
PHPCOV_PHAR        ?= https://phar.phpunit.de/phpcov.phar
BOX_PHAR           ?= https://github.com/box-project/box/releases/download/3.16.0/box.phar
PHP_COVERALLS_PHAR ?= https://github.com/php-coveralls/php-coveralls/releases/latest/download/php-coveralls.phar
CO_DIFF_PHAR       ?= https://github.com/JBZoo/Composer-Diff/releases/latest/download/composer-diff.phar
CO_GRAPH_PHAR      ?= https://github.com/JBZoo/Composer-Graph/releases/latest/download/composer-graph.phar
CO_CI_REPORT_PHAR  ?= https://github.com/JBZoo/CI-Report-Converter/releases/latest/download/ci-report-converter.phar

BOX_BIN            ?= $(VENDOR_BIN)/box.phar
CO_DIFF_BIN        ?= $(VENDOR_BIN)/composer-diff.phar
CO_GRAPH_BIN       ?= $(VENDOR_BIN)/composer-graph.phar
CO_CI_REPORT_BIN   ?= $(VENDOR_BIN)/ci-report-converter.phar


ifneq (, $(wildcard ./src/phpcs.xml))
    JBZOO_CONFIG_PHPCS ?= $(PATH_ROOT)/src/phpcs.xml
else
    JBZOO_CONFIG_PHPCS ?= $(PATH_ROOT)/vendor/jbzoo/codestyle/src/phpcs.xml
endif


ifneq (, $(wildcard ./.php-cs-fixer.php))
    JBZOO_CONFIG_PHPCSFIXER ?= $(PATH_ROOT)/.php-cs-fixer.php
else
    JBZOO_CONFIG_PHPCSFIXER ?= $(PATH_ROOT)/vendor/jbzoo/codestyle/src/PhpCsFixer/php-cs-fixer.php
endif


ifneq (, $(wildcard ./src/phpmd.xml))
    JBZOO_CONFIG_PHPMD ?= $(PATH_ROOT)/src/phpmd.xml
else
    JBZOO_CONFIG_PHPMD ?= $(PATH_ROOT)/vendor/jbzoo/codestyle/src/phpmd.xml
endif


ifneq (, $(wildcard ./phpstan.neon))
    JBZOO_CONFIG_PHPSTAN ?= $(PATH_ROOT)/phpstan.neon
else
    JBZOO_CONFIG_PHPSTAN ?= $(PATH_ROOT)/vendor/jbzoo/codestyle/src/phpstan.neon
endif


ifneq (, $(wildcard ./psalm.xml))
    JBZOO_CONFIG_PSALM ?= $(PATH_ROOT)/psalm.xml
else
    JBZOO_CONFIG_PSALM ?= $(PATH_ROOT)/vendor/jbzoo/codestyle/psalm.xml
endif


ifneq (, $(wildcard ./psalm-baseline.xml))
    JBZOO_CONFIG_PSALM_BASELINE ?= $(PATH_ROOT)/psalm-baseline.xml
else
    JBZOO_CONFIG_PSALM_BASELINE ?= $(PATH_ROOT)/vendor/jbzoo/codestyle/psalm-baseline.xml
endif


ifneq (, $(wildcard ./.phan.php))
    JBZOO_CONFIG_PHAN ?= $(PATH_ROOT)/.phan.php
else ifneq (, $(wildcard ./.phan/config.php))
    JBZOO_CONFIG_PHAN ?= $(PATH_ROOT)/.phan/config.php
else
    JBZOO_CONFIG_PHAN ?= $(PATH_ROOT)/vendor/jbzoo/codestyle/.phan/config.php
endif




ifneq (, $(wildcard ./phpbench.json))
    JBZOO_CONFIG_PHPBENCH ?= $(PATH_ROOT)/phpbench.json
else
    JBZOO_CONFIG_PHPBENCH ?= $(PATH_ROOT)/vendor/jbzoo/codestyle/src/phpbench.json
endif


# Render colored title before executing a command
define title
    @echo ""
    @echo "$(C_BACK)>>>> >>>> >>>> >>>> >>>> >>>> $(C_TITLE) $(1) $(CE)"
endef


# Download phar file (if needs) and save it in ./vendor/bin
define download_phar
    @test -f "$(PATH_ROOT)/vendor/bin/$(2).phar"                                            \
      ||                                                                                    \
    (                                                                                       \
      echo "File ./vendor/bin/$(2).phar not found. Downloading."                            \
      &&                                                                                    \
      curl $(1) --output "$(PATH_ROOT)/vendor/bin/$(2).phar"                                \
          --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 40   \
          --location --fail --silent --show-error                                           \
      &&                                                                                    \
      chmod +x "$(PATH_ROOT)/vendor/bin/$(2).phar"                                          \
    )
endef
