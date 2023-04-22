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

use JBZoo\Data\Data;
use JBZoo\Utils\Xml;

use function JBZoo\Data\data;
use function JBZoo\PHPUnit\isSame;

/**
 * @phan-file-suppress PhanUndeclaredProperty
 */
trait TraitPHPUnit
{
    //    public function testBootstrap(): void
    //    {
    //        isSame('tests/autoload.php', self::getPhpUnitAsArray()->find('_children.0._attrs.bootstrap'));
    //    }
    //
    //    public function testColor(): void
    //    {
    //        dump(self::getPhpUnitAsArray()->find('_children.0._attrs'));
    //
    //        isSame('true', self::getPhpUnitAsArray()->find('_children.0._attrs.colors1'));
    //    }
    //
    //    public function testVerbose(): void
    //    {
    //        isSame('true', self::getPhpUnitAsArray()->find('_children.0._attrs.verbose'));
    //    }
    //
    //    public function testXmlnsXsi(): void
    //    {
    //        isSame('true', self::getPhpUnitAsArray()->find('_children.0._attrs.xmlns:xsi'));
    //    }
    //
    //    private static function getPhpUnitAsArray(): Data
    //    {
    //        $xml = \file_get_contents(PROJECT_ROOT . '/phpunit.xml.dist');
    //
    //        return data(Xml::dom2Array(Xml::createFromString($xml)));
    //    }
}
