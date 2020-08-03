#
# JBZoo Toolbox - Codestyle
#
# This file is part of the JBZoo Toolbox project.
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.
#
# @package    Codestyle
# @license    MIT
# @copyright  Copyright (C) JBZoo.com, All rights reserved.
# @link       https://github.com/JBZoo/Codestyle
#

PHPUNIT_PRETTY_PRINT_PROGRESS ?= true

#### General Tests #####################################################################################################

test: test-phpunit ##@Tests Runs unit-tests (alias "test-phpunit-manual")
test-phpunit:
	$(call title,"PHPUnit - Running all tests")
	@echo "Config: $(JBZOO_CONFIG_PHPUNIT)"
	@if [ -z "$(TEAMCITY_VERSION)" ]; then                             \
        php `pwd`/vendor/bin/phpunit                                   \
            --configuration="$(JBZOO_CONFIG_PHPUNIT)"                  \
            --printer=Codedungeon\\PHPUnitPrettyResultPrinter\\Printer \
            --order-by=random                                          \
            --colors=always                                            \
            --verbose;                                                 \
    else                                                               \
        echo "##teamcity[progressStart 'PHPUnit Tests']";              \
        php `pwd`/vendor/bin/phpunit                                   \
            --configuration="$(JBZOO_CONFIG_PHPUNIT)"                  \
            --order-by=random                                          \
            --colors=always                                            \
            --teamcity                                                 \
            --verbose;                                                 \
        php `pwd`/vendor/bin/toolbox-ci teamcity:stats                 \
            --input-format="phpunit-clover-xml"                        \
            --input-file="$(PATH_BUILD)/coverage_xml/main.xml";        \
        echo "##teamcity[progressFinish 'PHPUnit Tests']";             \
    fi;


#### All Coding Standards ##############################################################################################

codestyle: ##@Tests Runs all codestyle linters at once
	@if [ -z "$(TEAMCITY_VERSION)" ]; then    \
        make codestyle-local;                 \
    else                                      \
        make codestyle-teamcity;              \
    fi;
	@make test-composer
	@-make test-composer-reqs


codestyle-local: ##@Tests Runs all codestyle linters at once (Internal - Regular Mode)
	@make test-phpcs
	@make test-phpmd
	@make test-phpmnd
	@make test-phpcpd
	@make test-phpstan
	@make test-psalm
	@make test-phan


codestyle-teamcity: ##@Tests Runs all codestyle linters at once (Internal - Teamcity Mode)
	@echo "##teamcity[progressStart 'Checking Coding Standards']"
	@make test-phpcs-teamcity
	@make test-phpmd-teamcity
	@make test-phpmnd-teamcity
	@make test-phpcpd-teamcity
	@make test-phpstan-teamcity
	@make test-psalm-teamcity
	@make test-phan-teamcity
	@make report-phploc-teamcity
	@echo "##teamcity[progressFinish 'Checking Coding Standards']"


#### Composer ##########################################################################################################

test-composer: ##@Tests Validates composer.json and composer.lock
	$(call title,"Composer - Checking common issue")
	@-composer diagnose
	$(call title,"Composer - Validate system requirements")
	@composer validate --verbose
	@composer check-platform-reqs
	$(call title,"Composer - List of outdated packages")
	@composer outdated --verbose
	$(call title,Composer - Checking dependencies with known security vulnerabilities)
	@php `pwd`/vendor/bin/security-checker security:check


test-composer-reqs: ##@Tests Checks composer.json the defined dependencies against your code
	$(call title,Composer - Check the defined dependencies against your code)
	@echo "Config: $(JBZOO_CONFIG_COMPOSER_REQ_CHECKER)"
	@php `pwd`/vendor/bin/composer-require-checker check   \
        --config-file=$(JBZOO_CONFIG_COMPOSER_REQ_CHECKER) \
        -vvv                                               \
        $(PATH_ROOT)/composer.json


#### PHP Code Sniffer ##################################################################################################

test-phpcs: ##@Tests PHPcs - Checking PHP Codestyle (PSR-12 + PHP Compatibility)
	$(call title,"PHPcs - Checks PHP Codestyle \(PSR-12 + PHP Compatibility\)")
	@echo "Config: $(JBZOO_CONFIG_PHPCS)"
	@php `pwd`/vendor/bin/phpcs "$(PATH_SRC)"  \
            --standard="$(JBZOO_CONFIG_PHPCS)" \
            --report=full                      \
            --colors                           \
            -p -s


test-phpcs-teamcity:
	@rm -f "$(PATH_BUILD)/phpcs-checkstyle.xml"
	@-php `pwd`/vendor/bin/phpcs "$(PATH_SRC)"                  \
            --standard="$(JBZOO_CONFIG_PHPCS)"                  \
            --report=checkstyle                                 \
            --report-file="$(PATH_BUILD)/phpcs-checkstyle.xml"  \
            --no-cache                                          \
            --no-colors                                         \
            -s -q > /dev/null
	@php `pwd`/vendor/bin/toolbox-ci convert                    \
        --input-format="checkstyle"                             \
        --output-format="tc-tests"                              \
        --suite-name="PHPcs"                                    \
        --root-path="`pwd`"                                     \
        --input-file="$(PATH_BUILD)/phpcs-checkstyle.xml"


#### PHP Mess Detector #################################################################################################

test-phpmd: ##@Tests PHPmd - Mess Detector Checker
	$(call title,"PHPmd - Mess Detector Checker")
	@echo "Config: $(JBZOO_CONFIG_PHPMD)"
	@php `pwd`/vendor/bin/phpmd "$(PATH_SRC)" ansi "$(JBZOO_CONFIG_PHPMD)" --verbose


test-phpmd-strict: ##@Tests PHPmd - Mess Detector Checker (strict mode)
	$(call title,"PHPmd - Mess Detector Checker")
	@echo "Config: $(JBZOO_CONFIG_PHPMD)"
	@php `pwd`/vendor/bin/phpmd "$(PATH_SRC)" ansi "$(JBZOO_CONFIG_PHPMD)" --verbose --strict


test-phpmd-teamcity:
	@rm -f "$(PATH_BUILD)/phpmd-json.json"
	@-php `pwd`/vendor/bin/phpmd "$(PATH_SRC)" json "$(JBZOO_CONFIG_PHPMD)" > "$(PATH_BUILD)/phpmd-json.json"
	@php `pwd`/vendor/bin/toolbox-ci convert                    \
        --input-format="phpmd-json"                             \
        --output-format="tc-tests"                              \
        --suite-name="PHPmd"                                    \
        --root-path="`pwd`"                                     \
        --input-file="$(PATH_BUILD)/phpmd-json.json"


#### PHP Magic Number Detector #########################################################################################

test-phpmnd: ##@Tests PHPmnd - Magic Number Detector
	$(call title,"PHPmnd - Magic Number Detector")
	@php `pwd`/vendor/bin/phpmnd "$(PATH_SRC)" --progress


test-phpmnd-teamcity:
	@php `pwd`/vendor/bin/phpmnd "$(PATH_SRC)" --quiet --xml-output="$(PATH_BUILD)/phpmnd.xml"


#### PHP Copy@Paste Detector ###########################################################################################

test-phpcpd: ##@Tests PHPcpd - Find obvious Copy&Paste
	$(call title,"PHPcpd - Find obvious Copy\&Paste")
	@php `pwd`/vendor/bin/phpcpd "$(PATH_SRC)" --verbose --progress


test-phpcpd-teamcity:
	@-php `pwd`/vendor/bin/phpcpd $(PATH_SRC) --log-pmd="$(PATH_BUILD)/phpcpd.xml" --quiet
	@echo ""
	@echo "##teamcity[importData type='pmdCpd' path='$(PATH_BUILD)/phpcpd.xml' verbose='true']"


#### PHPstan - Static Analysis Tool ####################################################################################

test-phpstan: ##@Tests PHPStan - Static Analysis Tool
	$(call title,"PHPStan - Static Analysis Tool")
	@echo "Config: $(JBZOO_CONFIG_PHPSTAN)"
	@php `pwd`/vendor/bin/phpstan analyse         \
        --configuration="$(JBZOO_CONFIG_PHPSTAN)" \
        --error-format=table                      \
        "$(PATH_SRC)"


test-phpstan-teamcity:
	@rm -f "$(PATH_BUILD)/phpstan-checkstyle.xml"
	@-php `pwd`/vendor/bin/phpstan analyse                      \
        --configuration="$(JBZOO_CONFIG_PHPSTAN)"               \
        --error-format=checkstyle                               \
        --no-progress                                           \
        "$(PATH_SRC)" > "$(PATH_BUILD)/phpstan-checkstyle.xml"
	@php `pwd`/vendor/bin/toolbox-ci convert                    \
        --input-format="checkstyle"                             \
        --output-format="tc-tests"                              \
        --suite-name="PHPstan"                                  \
        --root-path="`pwd`"                                     \
        --input-file="$(PATH_BUILD)/phpstan-checkstyle.xml"


#### Psalm - Static Analysis Tool ######################################################################################

test-psalm: ##@Tests Psalm - static analysis tool for PHP
	$(call title,"Psalm - static analysis tool for PHP")
	@echo "Config:   $(JBZOO_CONFIG_PSALM)"
	@echo "Baseline: $(JBZOO_CONFIG_PSALM_BASELINE)"
	@php `pwd`/vendor/bin/psalm                                 \
        --config="$(JBZOO_CONFIG_PSALM)"                        \
        --use-baseline="$(JBZOO_CONFIG_PSALM_BASELINE)"         \
        --show-snippet=true                                     \
        --report-show-info=true                                 \
        --find-unused-psalm-suppress                            \
        --no-cache                                              \
        --output-format=compact                                 \
        --long-progress                                         \
        --shepherd


test-psalm-teamcity:
	@rm -f "$(PATH_BUILD)/psalm-checkstyle.json"
	@-php `pwd`/vendor/bin/psalm                                \
        --config="$(JBZOO_CONFIG_PSALM)"                        \
        --use-baseline="$(JBZOO_CONFIG_PSALM_BASELINE)"         \
        --show-snippet=true                                     \
        --report-show-info=true                                 \
        --find-unused-psalm-suppress                            \
        --no-cache                                              \
        --output-format=json                                    \
        --no-progress                                           \
        --monochrome > "$(PATH_BUILD)/psalm-checkstyle.json"
	@php `pwd`/vendor/bin/toolbox-ci convert                    \
        --input-format="psalm-json"                             \
        --output-format="tc-tests"                              \
        --suite-name="Psalm"                                    \
        --root-path="`pwd`"                                     \
        --input-file="$(PATH_BUILD)/psalm-checkstyle.json"


#### Phan - Static Analysis Tool #######################################################################################

test-phan: ##@Tests Phan - super strict static analyzer for PHP
	$(call title,"Phan - super strict static analyzer for PHP")
	@echo "Config: $(JBZOO_CONFIG_PHAN)"
	@php `pwd`/vendor/bin/phan                             \
        --config-file="$(JBZOO_CONFIG_PHAN)"               \
        --color-scheme=light                               \
        --progress-bar                                     \
        --backward-compatibility-checks                    \
        --print-memory-usage-summary                       \
        --markdown-issue-messages                          \
        --allow-polyfill-parser                            \
        --strict-type-checking                             \
        --analyze-twice	                                   \
        --color


test-phan-teamcity:
	@rm -f "$(PATH_BUILD)/phan-checkstyle.xml"
	@-php `pwd`/vendor/bin/phan                                 \
        --config-file="$(JBZOO_CONFIG_PHAN)"                    \
        --output-mode="checkstyle"                              \
        --output="$(PATH_BUILD)/phan-checkstyle.xml"            \
        --no-progress-bar                                       \
        --backward-compatibility-checks                         \
        --markdown-issue-messages                               \
        --allow-polyfill-parser                                 \
        --strict-type-checking                                  \
        --analyze-twice	                                        \
        --no-color
	@php `pwd`/vendor/bin/toolbox-ci convert                    \
        --input-format="checkstyle"                             \
        --output-format="tc-tests"                              \
        --suite-name="Phan"                                     \
        --root-path="`pwd`"                                     \
        --input-file="$(PATH_BUILD)/phan-checkstyle.xml"


#### Testing Permformance ##############################################################################################

test-performance: ##@Tests Run benchmarks and performance tests
	$(call title,"Run benchmarks and performance tests")
	@echo "Config: $(JBZOO_CONFIG_PHPBENCH)"
	@rm    -fr "$(PATH_BUILD)/phpbench"
	@mkdir -pv "$(PATH_BUILD)/phpbench"
	@php `pwd`/vendor/bin/phpbench run         \
        --config="$(JBZOO_CONFIG_PHPBENCH)"    \
        --tag=jbzoo                            \
        --warmup=2                             \
        --store                                \
        --stop-on-error
	@make report-performance


test-performance-travis: ##@Tests Travis wrapper for benchmarks
	$(call title,"Run benchmark tests \(Travis Mode\)")
	@if [ $(XDEBUG_OFF) = "yes" ]; then                      \
       make test-performance;                                \
    else                                                     \
       echo "Performance test works only if XDEBUG_OFF=yes"; \
    fi;
