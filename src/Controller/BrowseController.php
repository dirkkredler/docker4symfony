<?php

declare(strict_types=1); 

namespace App\Controller;

use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

use function Symfony\Component\String\u;
use str_replace;

#[Route("/browse/{genre}")]
final class BrowseController
{
    public function __invoke(string $genre = "All genres"): Response
    {
        $title = u(str_replace('-', ' ', $genre))->title();

        return new Response("Browse {$title}");
    }
}
