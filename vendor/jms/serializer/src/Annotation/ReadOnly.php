<?php

declare(strict_types=1);

namespace JMS\Serializer\Annotation;

/**
 * @Annotation
 * @Target({"CLASS","PROPERTY"})
 *
 * @deprecated use `@ReadOnlyProperty` instead
 */
final class ReadOnly extends ReadOnlyProperty
{
    /**
     * @var bool
     */
    public $readOnly = true;
}
