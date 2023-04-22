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

#### General Tests #####################################################################################################

test: ##@Tests Launch PHPUnit Tests (alias "test-phpunit")
	@make build-download-phars
	@make test-phpunit

test-phpunit: ##@Tests PHPUnit - Launch General Tests
	$(call title,"PHPUnit - Run all tests")
	@if [ -n "$(TEAMCITY_VERSION)" ]; then    \
        make test-phpunit-teamcity;           \
    elif [ -n "$(GITHUB_ACTIONS)" ]; then     \
        make test-phpunit-ga;                 \
    else                                      \
        make test-phpunit-local;              \
    fi;


test-phpunit-teamcity:
	@echo "##teamcity[progressStart 'PHPUnit Tests']"
	@$(VENDOR_BIN)/phpunit --teamcity
	@$(CO_CI_REPORT_BIN) teamcity:stats                             \
        --input-format="phpunit-clover-xml"                         \
        --input-file="$(PATH_BUILD)/coverage_xml/main.xml"
	@$(CO_CI_REPORT_BIN) teamcity:stats                             \
        --input-format="junit-xml"                                  \
        --input-file="$(PATH_BUILD)/coverage_junit/main.xml"
	@echo "##teamcity[progressFinish 'PHPUnit Tests']"


test-phpunit-local:
	@$(VENDOR_BIN)/phpunit


test-phpunit-ga:
	@$(VENDOR_BIN)/phpunit
	@for f in `find ./build/coverage_junit -type f -name "*.xml"`;  \
    do                                                              \
        $(CO_CI_REPORT_BIN) convert                                 \
            --input-format=junit                                    \
            --input-file="$${f}"                                    \
            --output-format=$(CI_REPORT_GA)                         \
            --root-path="$(PATH_ROOT)"                              \
            --suite-name="PHPUnit - $${f}"                          \
            --non-zero-code=yes || exit 1;                          \
    done;


#### All Coding Standards ##############################################################################################

codestyle: ##@Tests Launch all codestyle linters at once
	@make build-download-phars
	@if [ -n "$(TEAMCITY_VERSION)" ]; then    \
        make codestyle-teamcity;              \
    elif [ -n "$(GITHUB_ACTIONS)" ]; then     \
        make codestyle-ga;                    \
    else                                      \
        make codestyle-local;                 \
    fi;


codestyle-local:
	@make test-phpcsfixer
	@make test-phpcs
	@make test-phpmd
	@make test-phpmnd
	@make test-phpcpd
	@make test-phpstan
	@make test-psalm
	@make test-phan
	@make test-composer


codestyle-ga:
	@make test-phpcsfixer-ga
	@make test-phpcs-ga
	@make test-phpmd-ga
	@make test-phpmnd-ga
	@make test-phpcpd-ga
	@make test-phpstan-ga
	@make test-psalm-ga
	@make test-phan-ga
	@make test-composer-ga


codestyle-teamcity:
	@echo "##teamcity[progressStart 'Checking Coding Standards']"
	@make test-phpcsfixer-teamcity
	@make test-phpcs-teamcity
	@make test-phpmd-teamcity
	@make test-phpmnd-teamcity
	@make test-phpcpd-teamcity
	@make test-phpstan-teamcity
	@make test-psalm-teamcity
	@make test-phan-teamcity
	@make report-pdepend
	@make report-phploc
	@echo "##teamcity[progressFinish 'Checking Coding Standards']"


#### Composer ##########################################################################################################

test-composer: ##@Tests Validates composer.json and composer.lock
	$(call title,"Composer - Checking common issue")
	@-$(COMPOSER_BIN) diagnose
	$(call title,"Composer - Validate system requirements")
	@$(COMPOSER_BIN) validate --verbose
	@$(COMPOSER_BIN) check-platform-reqs
	$(call title,"Composer - List of outdated packages")
	@$(COMPOSER_BIN) outdated --direct --verbose


test-composer-ga:
	@echo "::group::Composer Validate"
	@make test-composer
	@echo "::endgroup::"


#### PHP Code Sniffer ##################################################################################################

test-phpcs: ##@Tests PHPcs - Checking PHP Code Sniffer (PSR-12 + PHP Compatibility)
	$(call title,"PHPcs - Checking PHP Code Sniffer")
	@echo "Config: $(JBZOO_CONFIG_PHPCS)"
	@$(VENDOR_BIN)/phpcs "$(PATH_SRC)"                \
        --standard="$(JBZOO_CONFIG_PHPCS)"            \
        --report=full                                 \
        --colors                                      \
        -p -s


test-phpcs-teamcity:
	@rm -f "$(PATH_BUILD)/phpcs-checkstyle.xml"
	@-$(VENDOR_BIN)/phpcs "$(PATH_SRC)"                         \
        --standard="$(JBZOO_CONFIG_PHPCS)"                      \
        --report=checkstyle                                     \
        --report-file="$(PATH_BUILD)/phpcs-checkstyle.xml"      \
        --no-cache                                              \
        --no-colors                                             \
        -s -q > /dev/null
	@$(CO_CI_REPORT_BIN) convert                                \
        --input-file="$(PATH_BUILD)/phpcs-checkstyle.xml"       \
        --input-format="checkstyle"                             \
        --output-format="$(CI_REPORT)"                          \
        --suite-name="PHPcs"                                    \
        --root-path="$(PATH_ROOT)"                              \
        --non-zero-code=$(CI_NON_ZERO_CODE)


test-phpcs-ga:
	@make CI_REPORT=$(CI_REPORT_GA) CI_NON_ZERO_CODE=yes test-phpcs-teamcity


#### PhpCsFixer ########################################################################################################

test-phpcsfixer-fix: ##@Tests PhpCsFixer - Auto fix code to follow stylish standards
	$(call title,"Fix Coding Standards with PhpCsFixer")
	@echo "Config: $(JBZOO_CONFIG_PHPCSFIXER)"
	@PHP_CS_FIXER_IGNORE_ENV=1 $(VENDOR_BIN)/php-cs-fixer fix   \
        --config="$(JBZOO_CONFIG_PHPCSFIXER)"                   \
        -vvv


test-phpcsfixer: ##@Tests PhpCsFixer - Check code to follow stylish standards
	$(call title,"Check Coding Standards with PhpCsFixer")
	@make test-phpcsfixer-int CI_REPORT=plain


test-phpcsfixer-int:
	@echo "Config: $(JBZOO_CONFIG_PHPCSFIXER)"
	@PHP_CS_FIXER_IGNORE_ENV=1 $(VENDOR_BIN)/php-cs-fixer fix               \
        --config="$(JBZOO_CONFIG_PHPCSFIXER)"                               \
        --dry-run                                                           \
        -vvv                                                                \
        --format=checkstyle > "$(PATH_BUILD)/phpcsfixer-checkstyle.xml"     || true
	@$(CO_CI_REPORT_BIN) convert                                            \
        --input-file="$(PATH_BUILD)/phpcsfixer-checkstyle.xml"              \
        --input-format="checkstyle"                                         \
        --output-format="$(CI_REPORT)"                                      \
        --suite-name="PhpCsFixer"                                           \
        --root-path="$(PATH_ROOT)"                                          \
        --non-zero-code=yes


test-phpcsfixer-teamcity:
	@echo "##teamcity[progressStart 'Checking Coding Standards with PhpCsFixer']"
	@make test-phpcsfixer-int CI_REPORT=tc-tests
	@echo "##teamcity[progressFinish 'Checking Coding Standards with PhpCsFixer']"


test-phpcsfixer-ga:
	@make test-phpcsfixer-int CI_REPORT=$(CI_REPORT_GA)

#### PHP Mess Detector #################################################################################################

test-phpmd: ##@Tests PHPmd - Mess Detector Checker
	$(call title,"PHPmd - Mess Detector Checker")
	@echo "Config: $(JBZOO_CONFIG_PHPMD)"
	@$(VENDOR_BIN)/phpmd --version
	@$(VENDOR_BIN)/phpmd "$(PATH_SRC)" ansi "$(JBZOO_CONFIG_PHPMD)" --verbose


test-phpmd-strict: ##@Tests PHPmd - Mess Detector Checker (strict mode)
	$(call title,"PHPmd - Mess Detector Checker")
	@echo "Config: $(JBZOO_CONFIG_PHPMD)"
	@$(VENDOR_BIN)/phpmd --version
	@$(VENDOR_BIN)/phpmd "$(PATH_SRC)" ansi "$(JBZOO_CONFIG_PHPMD)" --verbose --strict


test-phpmd-teamcity:
	@rm -f "$(PATH_BUILD)/phpmd.json"
	@-$(VENDOR_BIN)/phpmd "$(PATH_SRC)" json "$(JBZOO_CONFIG_PHPMD)" > "$(PATH_BUILD)/phpmd.json"
	@$(CO_CI_REPORT_BIN) convert                    \
        --input-file="$(PATH_BUILD)/phpmd.json"     \
        --input-format="phpmd-json"                 \
        --output-format="$(CI_REPORT)"              \
        --suite-name="PHPmd"                        \
        --root-path="$(PATH_ROOT)"                  \
        --non-zero-code=$(CI_NON_ZERO_CODE)


test-phpmd-ga:
	@make CI_REPORT=$(CI_REPORT_GA) CI_NON_ZERO_CODE=yes test-phpmd-teamcity


#### PHP Magic Number Detector #########################################################################################

test-phpmnd: ##@Tests PHPmnd - Magic Number Detector
	$(call title,"PHPmnd - Magic Number Detector")
	@$(VENDOR_BIN)/phpmnd "$(PATH_SRC)" --progress


test-phpmnd-teamcity:
	@$(VENDOR_BIN)/phpmnd "$(PATH_SRC)" --quiet --hint --xml-output="$(PATH_BUILD)/phpmnd.xml"
	@$(CO_CI_REPORT_BIN) convert                    \
        --input-file="$(PATH_BUILD)/phpmnd.xml"     \
        --input-format="phpmnd"                     \
        --output-format="$(CI_REPORT_MND)"          \
        --suite-name="PHP Magic Numbers"            \
        --root-path="$(PATH_ROOT)"                  \
        --non-zero-code=$(CI_NON_ZERO_CODE)


test-phpmnd-ga:
	@make CI_REPORT=$(CI_REPORT_GA) CI_NON_ZERO_CODE=yes test-phpmnd-teamcity


#### PHP Copy@Paste Detector ###########################################################################################

test-phpcpd: ##@Tests PHPcpd - Find obvious Copy&Paste
	$(call title,"PHPcpd - Find obvious Copy\&Paste")
	$(call download_phar,$(PHPCPD_PHAR),"phpcpd")
	@$(VENDOR_BIN)/phpcpd.phar "$(PATH_SRC)"


test-phpcpd-teamcity:
	$(call download_phar,$(PHPCPD_PHAR),"phpcpd")
	@$(VENDOR_BIN)/phpcpd.phar $(PATH_SRC) --log-pmd="$(PATH_BUILD)/phpcpd.xml"
	@echo ""
	@echo "##teamcity[importData type='pmdCpd' path='$(PATH_BUILD)/phpcpd.xml' verbose='true']"
	@echo ""


test-phpcpd-ga:
	$(call download_phar,$(PHPCPD_PHAR),"phpcpd")
	@$(VENDOR_BIN)/phpcpd.phar $(PATH_SRC) --log-pmd="$(PATH_BUILD)/phpcpd.xml" > /dev/null
	@$(CO_CI_REPORT_BIN) convert                  \
        --input-file="$(PATH_BUILD)/phpcpd.xml"   \
        --input-format=pmd-cpd                    \
        --output-format="$(CI_REPORT_GA)"         \
        --root-path="$(PATH_ROOT)"                \
        --suite-name="Copy&Paste Detector"        \
        --non-zero-code=yes


#### PHPstan - Static Analysis Tool ####################################################################################

test-phpstan: ##@Tests PHPStan - Static Analysis Tool
	$(call title,"PHPStan - Static Analysis Tool")
	@echo "Config: $(JBZOO_CONFIG_PHPSTAN)"
	@$(VENDOR_BIN)/phpstan analyse                \
        --configuration="$(JBZOO_CONFIG_PHPSTAN)" \
        --error-format=table                      \
        "$(PATH_SRC)"


test-phpstan-teamcity:
	@rm -f "$(PATH_BUILD)/phpstan-checkstyle.xml"
	@-$(VENDOR_BIN)/phpstan analyse                             \
        --configuration="$(JBZOO_CONFIG_PHPSTAN)"               \
        --error-format=checkstyle                               \
        --no-progress                                           \
        "$(PATH_SRC)" > "$(PATH_BUILD)/phpstan-checkstyle.xml"
	@$(CO_CI_REPORT_BIN) convert                                \
        --input-file="$(PATH_BUILD)/phpstan-checkstyle.xml"     \
        --input-format="checkstyle"                             \
        --output-format="$(CI_REPORT)"                          \
        --suite-name="PHPstan"                                  \
        --root-path="$(PATH_ROOT)"                              \
        --non-zero-code=$(CI_NON_ZERO_CODE)


test-phpstan-ga:
	@make CI_REPORT=$(CI_REPORT_GA) CI_NON_ZERO_CODE=yes test-phpstan-teamcity


#### Psalm - Static Analysis Tool ######################################################################################

test-psalm: ##@Tests Psalm - static analysis tool for PHP
	$(call title,"Psalm - static analysis tool for PHP")
	@echo "Config:   $(JBZOO_CONFIG_PSALM)"
	@echo "Baseline: $(JBZOO_CONFIG_PSALM_BASELINE)"
	@$(VENDOR_BIN)/psalm --version
	@$(VENDOR_BIN)/psalm                                        \
        --config="$(JBZOO_CONFIG_PSALM)"                        \
        --use-baseline="$(JBZOO_CONFIG_PSALM_BASELINE)"         \
        --show-snippet=true                                     \
        --report-show-info=true                                 \
        --find-unused-psalm-suppress                            \
        --output-format=compact                                 \
        --long-progress                                         \
        --no-cache


test-psalm-teamcity:
	@rm -f "$(PATH_BUILD)/psalm-checkstyle.json"
	@-$(VENDOR_BIN)/psalm                                       \
        --config="$(JBZOO_CONFIG_PSALM)"                        \
        --use-baseline="$(JBZOO_CONFIG_PSALM_BASELINE)"         \
        --show-snippet=true                                     \
        --report-show-info=true                                 \
        --find-unused-psalm-suppress                            \
        --output-format=json                                    \
        --no-cache                                              \
        --no-progress                                           \
        --shepherd                                              \
        --monochrome > "$(PATH_BUILD)/psalm-checkstyle.json"
	@$(CO_CI_REPORT_BIN) convert                                \
        --input-file="$(PATH_BUILD)/psalm-checkstyle.json"      \
        --input-format="psalm-json"                             \
        --output-format="$(CI_REPORT)"                          \
        --suite-name="Psalm"                                    \
        --root-path="$(PATH_ROOT)"                              \
        --non-zero-code=$(CI_NON_ZERO_CODE)


test-psalm-ga:
	@make CI_REPORT=$(CI_REPORT_GA) CI_NON_ZERO_CODE=yes test-psalm-teamcity


#### Phan - Static Analysis Tool #######################################################################################

test-phan: ##@Tests Phan - super strict static analyzer for PHP
	$(call title,"Phan - super strict static analyzer for PHP")
	@echo "Config: $(JBZOO_CONFIG_PHAN)"
	@$(VENDOR_BIN)/phan --version
	@$(VENDOR_BIN)/phan                                         \
        --config-file="$(JBZOO_CONFIG_PHAN)"                    \
        --project-root-directory="`pwd`"                        \
        --color-scheme=light                                    \
        --no-progress-bar                                       \
        --backward-compatibility-checks                         \
        --print-memory-usage-summary                            \
        --markdown-issue-messages                               \
        --allow-polyfill-parser                                 \
        --strict-type-checking                                  \
        --analyze-twice                                         \
        --disable-cache                                         \
        --color


test-phan-teamcity:
	@rm -f "$(PATH_BUILD)/phan-checkstyle.xml"
	@-$(VENDOR_BIN)/phan                                        \
        --config-file="$(JBZOO_CONFIG_PHAN)"                    \
        --project-root-directory="`pwd`"                        \
        --output-mode="checkstyle"                              \
        --output="$(PATH_BUILD)/phan-checkstyle.xml"            \
        --no-progress-bar                                       \
        --backward-compatibility-checks                         \
        --markdown-issue-messages                               \
        --allow-polyfill-parser                                 \
        --strict-type-checking                                  \
        --analyze-twice	                                        \
        --disable-cache                                         \
        --no-color
	@$(CO_CI_REPORT_BIN) convert                                \
        --input-file="$(PATH_BUILD)/phan-checkstyle.xml"        \
        --input-format="checkstyle"                             \
        --output-format="$(CI_REPORT)"                          \
        --suite-name="Phan"                                     \
        --root-path="$(PATH_ROOT)"                              \
        --non-zero-code=$(CI_NON_ZERO_CODE)


test-phan-ga:
	@make CI_REPORT=$(CI_REPORT_GA) CI_NON_ZERO_CODE=yes test-phan-teamcity


#### Testing Performance ###############################################################################################

test-performance: ##@Tests Run benchmarks and performance tests
	$(call title,"Run benchmarks and performance tests")
	@echo "Config: $(JBZOO_CONFIG_PHPBENCH)"
	@rm    -fr "$(PATH_BUILD)/phpbench"
	@mkdir -pv "$(PATH_BUILD)/phpbench"
	@$(VENDOR_BIN)/phpbench run                                 \
        --config="$(JBZOO_CONFIG_PHPBENCH)"                     \
        --tag=jbzoo                                             \
        --warmup=2                                              \
        --store                                                 \
        --stop-on-error
	@make report-performance
