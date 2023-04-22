<?php

/**
 * JBZoo Toolbox - Codestyle.
 *
 * This file is part of the JBZoo Toolbox project.
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * @license    MIT
 * @copyright  Copyright (C) JBZoo.com, All rights reserved.
 * @see        https://github.com/JBZoo/Codestyle
 */

declare(strict_types=1);

namespace JBZoo\Codestyle\PHPUnit;

use JBZoo\PHPUnit\PHPUnit;
use JBZoo\Utils\Cli;
use Symfony\Component\Finder\Finder;

use function JBZoo\PHPUnit\isTrue;
use function JBZoo\PHPUnit\openFile;

abstract class AbstractPackageTest extends PHPUnit
{
    use TraitComposer;
    use TraitCopyright;
    use TraitGithubActions;
    use TraitOtherTests;
    use TraitPHPUnit;
    use TraitReadme;

    // ### Other properties. ###########################################################################################
    protected const DEBUG_MODE = false;

    // Important! Overload these properties in your test class.
    protected string $packageName      = '';
    protected string $gaScheduleMinute = '';

    // ### Default values. #############################################################################################
    // General
    protected string $vendorName = 'JBZoo';

    // Composer
    protected string $composerDevVersion = '7.x-dev';
    protected string $composerPhpVersion = '^8.1';
    protected string $composerType       = 'library';
    protected string $composerLicense    = 'MIT';

    protected string $projectRoot         = PROJECT_ROOT;
    protected string $copyrightVendorName = 'JBZoo Toolbox';
    protected string $copyrightLicense    = 'MIT';
    protected string $copyrightRights     = 'Copyright (C) JBZoo.com, All rights reserved.';
    protected string $copyrightSee        = 'https://github.com/_VENDOR_NS_/_PACKAGE_';

    // Internal variables
    protected string $packageNamespace = '';

    /**
     * {@inheritDoc}
     */
    protected function setUp(): void
    {
        parent::setUp();

        if ($this->packageName === '') {
            throw new Exception('$this->packageName is undefined');
        }

        $projectRoot = (string)\realpath($this->projectRoot);

        if ($projectRoot === '') {
            throw new Exception('$this->projectRoot is undefined');
        }

        if (!\is_dir($this->projectRoot)) {
            throw new Exception('$this->projectRoot not exists');
        }

        $this->projectRoot      = $projectRoot;
        $this->packageNamespace = \str_replace('-', '', $this->packageName);
    }

    public static function checkFiles(string $testcaseName, Finder $finder, \Closure $testCaseFunction): int
    {
        if (static::DEBUG_MODE) {
            Cli::out("Count: {$finder->count()}; Method: {$testcaseName}");
        }

        /** @var \SplFileInfo $file */
        foreach ($finder as $file) {
            $pathname = $file->getPathname();
            $content  = (string)openFile($pathname);

            if (static::DEBUG_MODE) {
                Cli::out(" * {$pathname}");
            }

            $testCaseFunction($content, $pathname);
        }

        isTrue(true); // One assert is a minimum for test complete

        return $finder->count();
    }
}
