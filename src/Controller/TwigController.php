<?php

declare(strict_types=1); 

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;
use Twig\Environment;


#[Route("/template")]
final class TwigController
{
    public function __construct(private Environment $twig)
    {}

    public function __invoke(): Response
    {
        return new Response($this->twig->render('page.html.twig', [
            'title' => 'PB & JAMS',
            'tracks' => [
                [ 'song' => 'A Track', 'artist' => 'A' ],
                [ 'song' => 'B Track', 'artist' => 'B' ],
                [ 'song' => 'C Track', 'artist' => 'C' ],
                [ 'song' => 'D Track', 'artist' => 'D' ],
            ],
        ]));
    }
}
